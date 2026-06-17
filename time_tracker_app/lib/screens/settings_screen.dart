import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/task.dart';
import '../models/session.dart';
import '../models/reward.dart';
import '../models/reward_redemption.dart';
import '../providers/data_providers.dart';
import '../providers/timer_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('Data Management', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Reset All Data', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text('Permanently delete all tasks, sessions, rewards, and history.'),
            onTap: () => _confirmReset(context, ref),
          ),
          const Divider(),
          const ListTile(
            title: Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Time Tracker App v1.0'),
            subtitle: Text('Offline-only Todo, Points & Rewards Flutter application.'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset All Data?', style: TextStyle(color: Colors.red)),
        content: const Text('This action cannot be undone. All your tasks, tracked time, points, and rewards will be deleted permanently. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton.tonal(
            style: FilledButton.styleFrom(backgroundColor: Colors.red[100], foregroundColor: Colors.red[900]),
            onPressed: () async {
              Navigator.pop(ctx);
              await _resetData(ref);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data has been wiped.')));
              }
            },
            child: const Text('Yes, Delete Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _resetData(WidgetRef ref) async {
    // Stop any active timer
    ref.read(timerProvider.notifier).stopTask();
    
    // Clear boxes
    await Hive.box<Task>('tasks').clear();
    await Hive.box<Session>('sessions').clear();
    await Hive.box<Reward>('rewards').clear();
    await Hive.box<RewardRedemption>('redemptions').clear();
    await Hive.box('app_state').clear();

    // Reset notifiers
    // Riverpod StateNotifiers need to have their state updated or we can invalidate them.
    ref.invalidate(tasksProvider);
    ref.invalidate(sessionsProvider);
    ref.invalidate(rewardsProvider);
    ref.invalidate(redemptionsProvider);
    ref.invalidate(timerProvider);
  }
}
