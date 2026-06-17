import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/session.dart';
import '../models/reward.dart';
import '../models/reward_redemption.dart';

// Hive Box Providers
final taskBoxProvider = Provider<Box<Task>>((ref) => Hive.box<Task>('tasks'));
final sessionBoxProvider = Provider<Box<Session>>((ref) => Hive.box<Session>('sessions'));
final rewardBoxProvider = Provider<Box<Reward>>((ref) => Hive.box<Reward>('rewards'));
final redemptionBoxProvider = Provider<Box<RewardRedemption>>((ref) => Hive.box<RewardRedemption>('redemptions'));

// Task Provider
class TasksNotifier extends StateNotifier<List<Task>> {
  final Box<Task> _box;
  TasksNotifier(this._box) : super(_box.values.toList());

  void addTask(Task task) {
    _box.put(task.id, task);
    state = _box.values.toList();
  }

  void updateTask(Task task) {
    _box.put(task.id, task);
    state = _box.values.toList();
  }

  void deleteTask(String id) {
    _box.delete(id);
    state = _box.values.toList();
  }
}

final tasksProvider = StateNotifierProvider<TasksNotifier, List<Task>>((ref) {
  return TasksNotifier(ref.watch(taskBoxProvider));
});

// Session Provider
class SessionsNotifier extends StateNotifier<List<Session>> {
  final Box<Session> _box;
  SessionsNotifier(this._box) : super(_box.values.toList());

  void addSession(Session session) {
    _box.put(session.id, session);
    state = _box.values.toList();
  }
  
  void deleteSession(String id) {
    _box.delete(id);
    state = _box.values.toList();
  }
}

final sessionsProvider = StateNotifierProvider<SessionsNotifier, List<Session>>((ref) {
  return SessionsNotifier(ref.watch(sessionBoxProvider));
});

// Reward Provider
class RewardsNotifier extends StateNotifier<List<Reward>> {
  final Box<Reward> _box;
  RewardsNotifier(this._box) : super(_box.values.toList());

  void addReward(Reward reward) {
    _box.put(reward.id, reward);
    state = _box.values.toList();
  }

  void updateReward(Reward reward) {
    _box.put(reward.id, reward);
    state = _box.values.toList();
  }

  void deleteReward(String id) {
    _box.delete(id);
    state = _box.values.toList();
  }
}

final rewardsProvider = StateNotifierProvider<RewardsNotifier, List<Reward>>((ref) {
  return RewardsNotifier(ref.watch(rewardBoxProvider));
});

// Redemption Provider
class RedemptionsNotifier extends StateNotifier<List<RewardRedemption>> {
  final Box<RewardRedemption> _box;
  RedemptionsNotifier(this._box) : super(_box.values.toList());

  void addRedemption(RewardRedemption redemption) {
    _box.put(redemption.id, redemption);
    state = _box.values.toList();
  }
}

final redemptionsProvider = StateNotifierProvider<RedemptionsNotifier, List<RewardRedemption>>((ref) {
  return RedemptionsNotifier(ref.watch(redemptionBoxProvider));
});

// Derived Providers
final totalEarnedPointsProvider = Provider<int>((ref) {
  final sessions = ref.watch(sessionsProvider);
  return sessions.fold(0, (sum, s) => sum + s.earnedPoints);
});

final totalSpentPointsProvider = Provider<int>((ref) {
  final redemptions = ref.watch(redemptionsProvider);
  return redemptions.fold(0, (sum, r) => sum + r.costPoints);
});

final availablePointsProvider = Provider<int>((ref) {
  final earned = ref.watch(totalEarnedPointsProvider);
  final spent = ref.watch(totalSpentPointsProvider);
  return earned - spent;
});
