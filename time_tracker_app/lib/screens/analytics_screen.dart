import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/session.dart';
import '../providers/data_providers.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analytics'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DailyAnalytics(),
            _WeeklyAnalytics(),
            _MonthlyAnalytics(),
          ],
        ),
      ),
    );
  }
}

class _DailyAnalytics extends ConsumerWidget {
  const _DailyAnalytics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    
    final today = DateTime.now();
    final dayKey = "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";
    final todaySessions = sessions.where((s) => s.dayKey == dayKey).toList();

    // Build maps keyed by taskId, but also track taskName
    Map<String, int> timePerTaskId = {};
    Map<String, String> taskIdToName = {};
    for (var s in todaySessions) {
      timePerTaskId[s.taskId] = (timePerTaskId[s.taskId] ?? 0) + s.durationSeconds;
      taskIdToName[s.taskId] = s.taskName;
    }

    final totalSeconds = todaySessions.fold(0, (sum, s) => sum + s.durationSeconds);
    final totalPoints = todaySessions.fold(0, (sum, s) => sum + s.earnedPoints);
    
    final workedTaskNames = taskIdToName.values.join(', ');

    if (todaySessions.isEmpty) {
      return const Center(child: Text('No activity today.', style: TextStyle(color: Colors.grey)));
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Today you worked on: ${workedTaskNames.isEmpty ? 'Nothing' : workedTaskNames}.\nTotal time: ${_formatHoursMins(totalSeconds)}.\nPoints earned today: $totalPoints.',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),
          const Text('Time breakdown By Task (Seconds)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: BarChart(
              BarChartData(
                barGroups: timePerTaskId.entries.toList().asMap().entries.map((e) {
                  final index = e.key;
                  final duration = e.value.value.toDouble();
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(toY: duration, color: Colors.blue, width: 20, borderRadius: BorderRadius.circular(4)),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        final entriesList = timePerTaskId.entries.toList();
                        if (value.toInt() < entriesList.length) {
                          final taskId = entriesList[value.toInt()].key;
                          final title = taskIdToName[taskId] ?? 'Unknown';
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(title.length > 5 ? title.substring(0, 5) : title, style: const TextStyle(fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHoursMins(int s) {
    return '${s ~/ 3600}h ${(s % 3600) ~/ 60}m';
  }
}

class _WeeklyAnalytics extends ConsumerWidget {
  const _WeeklyAnalytics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    
    final now = DateTime.now();
    // get sessions from last 7 days
    final weekSessions = sessions.where((s) => s.startAt.isAfter(now.subtract(const Duration(days: 7)))).toList();

    return _buildPieChart(weekSessions, 'Last 7 Days');
  }
}

class _MonthlyAnalytics extends ConsumerWidget {
  const _MonthlyAnalytics();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);
    
    final now = DateTime.now();
    // last 30 days
    final monthSessions = sessions.where((s) => s.startAt.isAfter(now.subtract(const Duration(days: 30)))).toList();

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: _PointsLedgerSummary(),
        ),
        Expanded(child: _buildPieChart(monthSessions, 'Last 30 Days')),
      ],
    );
  }
}

class _PointsLedgerSummary extends ConsumerWidget {
  const _PointsLedgerSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earned = ref.watch(totalEarnedPointsProvider);
    final spent = ref.watch(totalSpentPointsProvider);
    final available = ref.watch(availablePointsProvider);

    return Card(
      color: Colors.amber[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statColumn('Earned', '$earned', Colors.green),
            _statColumn('Spent', '$spent', Colors.red),
            _statColumn('Available', '$available', Colors.amber[900]!),
          ],
        ),
      ),
    );
  }
}

Widget _statColumn(String label, String value, Color color) {
  return Column(
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
    ],
  );
}

Widget _buildPieChart(List<Session> periodSessions, String periodLabel) {
  if (periodSessions.isEmpty) {
    return Center(child: Text('No activity for $periodLabel.', style: const TextStyle(color: Colors.grey)));
  }

  Map<String, int> timePerTaskId = {};
  Map<String, String> taskIdToName = {};
  for (var s in periodSessions) {
    timePerTaskId[s.taskId] = (timePerTaskId[s.taskId] ?? 0) + s.durationSeconds;
    taskIdToName[s.taskId] = s.taskName;
  }

  final totalSeconds = periodSessions.fold(0, (sum, s) => sum + s.durationSeconds);
  final totalPoints = periodSessions.fold(0, (sum, s) => sum + s.earnedPoints);

  final List<Color> colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.cyan];

  final sections = timePerTaskId.entries.toList().asMap().entries.map((e) {
    final index = e.key;
    final duration = e.value.value;
    final percentage = (duration / totalSeconds) * 100;

    return PieChartSectionData(
      color: colors[index % colors.length],
      value: percentage,
      title: '${percentage.toStringAsFixed(1)}%',
      radius: 80,
      titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }).toList();

  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Totals for $periodLabel:\nTime: ${totalSeconds ~/ 3600}h ${(totalSeconds % 3600) ~/ 60}m\nPoints: $totalPoints', style: const TextStyle(fontSize: 16)),
        const SizedBox(height: 32),
        Expanded(
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40,
              sectionsSpace: 2,
            ),
          ),
        ),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: timePerTaskId.keys.toList().asMap().entries.map((e) {
            final taskId = e.value;
            final taskTitle = taskIdToName[taskId] ?? 'Unknown';
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: colors[e.key % colors.length]),
                const SizedBox(width: 4),
                Text(taskTitle),
              ],
            );
          }).toList(),
        )
      ],
    ),
  );
}
