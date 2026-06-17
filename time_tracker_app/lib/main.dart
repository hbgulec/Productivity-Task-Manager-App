import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/task.dart';
import 'models/session.dart';
import 'models/reward.dart';
import 'models/reward_redemption.dart';
import 'screens/main_skeleton.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Hive.initFlutter();
  
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(SessionAdapter());
  Hive.registerAdapter(RewardAdapter());
  Hive.registerAdapter(RewardRedemptionAdapter());
  
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<Session>('sessions');
  await Hive.openBox<Reward>('rewards');
  await Hive.openBox<RewardRedemption>('redemptions');
  await Hive.openBox('app_state');

  runApp(const ProviderScope(child: TimeTrackerApp()));
}

class TimeTrackerApp extends StatelessWidget {
  const TimeTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const MainSkeleton(),
    );
  }
}
