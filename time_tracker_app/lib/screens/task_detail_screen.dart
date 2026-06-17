import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../providers/data_providers.dart';
import '../providers/timer_provider.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends ConsumerWidget {
  final String taskId;
  
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);
    final task = tasks.firstWhere((t) => t.id == taskId, orElse: () => Task(
      id: '', title: 'Unknown', createdAt: DateTime.now(), status: TaskStatus.notStarted, rewardMinutes: 0, rewardPoints: 0
    ));

    final timerState = ref.watch(timerProvider);
    final isTimerActiveForThis = timerState.activeTaskId == taskId;
    final isPausedForThis = timerState.pausedTaskId == taskId;

    final sessions = ref.watch(sessionsProvider).where((s) => s.taskId == taskId).toList();
    // sort sessions desc
    sessions.sort((a, b) => b.endAt.compareTo(a.endAt));

    final today = DateTime.now();
    final dayKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final todaySessions = sessions.where((s) => s.dayKey == dayKey).toList();
    final todaySeconds = todaySessions.fold(0, (sum, s) => sum + s.durationSeconds) + (isTimerActiveForThis ? timerState.elapsedSeconds : 0);
    final todayPoints = todaySessions.fold(0, (sum, s) => sum + s.earnedPoints);

    final String timerDisplay = isTimerActiveForThis 
        ? _formatSeconds(timerState.elapsedSeconds)
        : isPausedForThis
            ? _formatSeconds(timerState.pausedElapsedSeconds)
            : "00:00:00";

    return Scaffold(
      appBar: AppBar(title: Text(task.title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      task.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(task.status),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      timerDisplay,
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!isTimerActiveForThis)
                          FloatingActionButton.extended(
                            heroTag: 'start_btn',
                            onPressed: () {
                              ref.read(timerProvider.notifier).startTask(taskId);
                            },
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Start'),
                          ),
                        if (isTimerActiveForThis)
                          FloatingActionButton.extended(
                            heroTag: 'pause_btn',
                            onPressed: () {
                              ref.read(timerProvider.notifier).pauseTask();
                            },
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause'),
                            backgroundColor: Colors.orange,
                          ),
                        const SizedBox(width: 16),
                        if (isTimerActiveForThis || task.status == TaskStatus.paused)
                          FloatingActionButton.extended(
                            heroTag: 'stop_btn',
                            onPressed: () {
                              if (isTimerActiveForThis) {
                                ref.read(timerProvider.notifier).stopTask();
                              } else {
                                ref.read(tasksProvider.notifier).updateTask(task.copyWith(status: TaskStatus.completed));
                              }
                            },
                            icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                            backgroundColor: Colors.red,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Stats Row
            Row(
              children: [
                Expanded(child: _StatCard(title: "Today's Time", value: _formatSeconds(todaySeconds))),
                const SizedBox(width: 16),
                Expanded(child: _StatCard(title: "Today's Points", value: '+$todayPoints', valueColor: Colors.amber[700])),
              ],
            ),
            const SizedBox(height: 24),
            // Info Card
            if (task.description != null && task.description!.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text(task.description!),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.rule),
                    const SizedBox(width: 16),
                    Text('Rule: ${task.rewardPoints} pts per ${task.rewardMinutes} min'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Session History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (sessions.isEmpty)
              const Text('No sessions yet.', style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final s = sessions[index];
                  final dateFormat = DateFormat('MMM d, h:mm a');
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${dateFormat.format(s.startAt)} - ${dateFormat.format(s.endAt)}'),
                    subtitle: Text('Duration: ${_formatSeconds(s.durationSeconds)}'),
                    trailing: Text('+${s.earnedPoints} pts', style: TextStyle(color: Colors.amber[700], fontWeight: FontWeight.bold)),
                  );
                },
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  String _formatSeconds(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.notStarted: return Colors.grey;
      case TaskStatus.inProgress: return Colors.blue;
      case TaskStatus.paused: return Colors.orange;
      case TaskStatus.completed: return Colors.green;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _StatCard({required this.title, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ),
    );
  }
}
