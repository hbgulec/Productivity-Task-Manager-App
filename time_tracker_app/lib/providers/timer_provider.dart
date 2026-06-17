import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/session.dart';
import 'data_providers.dart';

final appStateBoxProvider = Provider<Box>((ref) => Hive.box('app_state'));

class TimerState {
  final String? activeTaskId;
  final DateTime? sessionStartAt;
  final int elapsedSeconds;
  final String? pausedTaskId;
  final int pausedElapsedSeconds;
  
  TimerState({
    this.activeTaskId,
    this.sessionStartAt,
    this.elapsedSeconds = 0,
    this.pausedTaskId,
    this.pausedElapsedSeconds = 0,
  });

  TimerState copyWith({
    String? activeTaskId,
    DateTime? sessionStartAt,
    int? elapsedSeconds,
    String? pausedTaskId,
    int? pausedElapsedSeconds,
  }) {
    return TimerState(
      activeTaskId: activeTaskId ?? this.activeTaskId,
      sessionStartAt: sessionStartAt ?? this.sessionStartAt,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      pausedTaskId: pausedTaskId ?? this.pausedTaskId,
      pausedElapsedSeconds: pausedElapsedSeconds ?? this.pausedElapsedSeconds,
    );
  }
}

class TimerNotifier extends StateNotifier<TimerState> {
  final Box _appState;
  final Ref _ref;
  Timer? _ticker;

  TimerNotifier(this._appState, this._ref) : super(TimerState()) {
    _initFromState();
  }

  void _initFromState() {
    final activeId = _appState.get('activeTaskId') as String?;
    final startAtMs = _appState.get('sessionStartAt') as int?;
    
    if (activeId != null && startAtMs != null) {
      final startAt = DateTime.fromMillisecondsSinceEpoch(startAtMs);
      state = TimerState(activeTaskId: activeId, sessionStartAt: startAt);
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.sessionStartAt != null) {
        final elapsed = DateTime.now().difference(state.sessionStartAt!).inSeconds;
        state = state.copyWith(elapsedSeconds: elapsed);
      }
    });
  }

  void startTask(String taskId) {
    if (state.activeTaskId != null && state.activeTaskId != taskId) {
      stopTask(); // Force stop existing
    }
    
    final now = DateTime.now();
    _appState.put('activeTaskId', taskId);
    _appState.put('sessionStartAt', now.millisecondsSinceEpoch);
    
    // Update task status
    final taskBox = _ref.read(taskBoxProvider);
    final task = taskBox.get(taskId);
    if (task != null) {
      _ref.read(tasksProvider.notifier).updateTask(task.copyWith(status: TaskStatus.inProgress));
    }

    state = TimerState(activeTaskId: taskId, sessionStartAt: now, elapsedSeconds: 0);
    _startTicker();
  }

  void pauseTask() {
    if (state.activeTaskId != null) {
      final taskId = state.activeTaskId!;
      final elapsed = state.elapsedSeconds;
      _saveSessionAndUpdateTask(taskId, TaskStatus.paused);
      // Keep elapsed time visible on screen for the paused task
      state = TimerState(pausedTaskId: taskId, pausedElapsedSeconds: elapsed);
    }
  }

  void stopTask() {
    if (state.activeTaskId != null) {
      final taskId = state.activeTaskId!;
      _saveSessionAndUpdateTask(taskId, TaskStatus.completed);
      // Fully reset — display goes back to 00:00:00
      state = TimerState();
    }
  }

  void _saveSessionAndUpdateTask(String taskId, TaskStatus nextStatus) {
    _ticker?.cancel();
    
    final startAt = state.sessionStartAt ?? DateTime.now();
    final endAt = DateTime.now();
    final durationSeconds = endAt.difference(startAt).inSeconds;
    
    if (durationSeconds > 0) {
      final taskBox = _ref.read(taskBoxProvider);
      final task = taskBox.get(taskId);
      
      if (task != null) {
        // --- Bug 2 fix: Proportional + cumulative daily points ---
        final today = DateTime.now();
        final dayKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

        // Get all sessions for this task today
        final allSessions = _ref.read(sessionsProvider);
        final todayTaskSessions = allSessions.where(
          (s) => s.taskId == taskId && s.dayKey == dayKey
        ).toList();

        final previousDailySeconds = todayTaskSessions.fold(0, (sum, s) => sum + s.durationSeconds);
        final previousDailyPoints = todayTaskSessions.fold(0, (sum, s) => sum + s.earnedPoints);

        final totalDailySeconds = previousDailySeconds + durationSeconds;

        // Proportional calculation: floor(totalSeconds * rewardPoints / (rewardMinutes * 60))
        // e.g. 10 pts per 60 min → 1 pt per 6 min (360 seconds)
        int totalDailyPoints = 0;
        if (task.rewardMinutes > 0) {
          totalDailyPoints = (totalDailySeconds * task.rewardPoints) ~/ (task.rewardMinutes * 60);
        }

        // Only award the increment (what hasn't been awarded yet today)
        final earnedPoints = (totalDailyPoints - previousDailyPoints).clamp(0, totalDailyPoints);

        final session = Session(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          taskId: taskId,
          taskName: task.title,
          startAt: startAt,
          endAt: endAt,
          durationSeconds: durationSeconds,
          earnedPoints: earnedPoints,
          dayKey: dayKey,
        );
        _ref.read(sessionsProvider.notifier).addSession(session);
        _ref.read(tasksProvider.notifier).updateTask(task.copyWith(status: nextStatus));
      }
    } else {
      // Even if duration is 0, update the task status
      final taskBox = _ref.read(taskBoxProvider);
      final task = taskBox.get(taskId);
      if (task != null) {
        _ref.read(tasksProvider.notifier).updateTask(task.copyWith(status: nextStatus));
      }
    }

    _appState.delete('activeTaskId');
    _appState.delete('sessionStartAt');
  }
}

final timerProvider = StateNotifierProvider<TimerNotifier, TimerState>((ref) {
  return TimerNotifier(ref.watch(appStateBoxProvider), ref);
});
