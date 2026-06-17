import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward.dart';
import '../models/reward_redemption.dart';
import '../providers/data_providers.dart';
import 'package:intl/intl.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final availablePoints = ref.watch(availablePointsProvider);
    final rewards = ref.watch(rewardsProvider);
    final redemptions = ref.watch(redemptionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 32),
                const SizedBox(width: 12),
                Text(
                  '$availablePoints Available Points',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Rewards Gallery'),
                      Tab(text: 'History'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _RewardsList(rewards: rewards, availablePoints: availablePoints),
                        _RedemptionHistory(redemptions: redemptions, rewards: rewards),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRewardDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('New Reward'),
      ),
    );
  }

  void _showAddRewardDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final costController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create Reward', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Reward Title (e.g., Watch a movie)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cost in Points', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    
                    final reward = Reward(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: titleController.text.trim(),
                      costPoints: int.tryParse(costController.text) ?? 100,
                      createdAt: DateTime.now(),
                    );

                    ref.read(rewardsProvider.notifier).addReward(reward);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Reward'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}

class _RewardsList extends ConsumerWidget {
  final List<Reward> rewards;
  final int availablePoints;

  const _RewardsList({required this.rewards, required this.availablePoints});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (rewards.isEmpty) {
      return const Center(child: Text('No rewards created yet.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        final canAfford = availablePoints >= reward.costPoints;

        return Dismissible(
          key: ValueKey(reward.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            margin: const EdgeInsets.only(bottom: 4),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete Reward?'),
                content: Text('Are you sure you want to delete "${reward.title}"?'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ?? false;
          },
          onDismissed: (_) {
            ref.read(rewardsProvider.notifier).deleteReward(reward.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${reward.title}" deleted')),
            );
          },
          child: Card(
            child: ListTile(
              title: Text(reward.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${reward.costPoints} pts'),
              onLongPress: () => _showEditRewardDialog(context, ref, reward),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditRewardDialog(context, ref, reward);
                      } else if (value == 'delete') {
                        _confirmDeleteReward(context, ref, reward);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit), title: Text('Edit'), contentPadding: EdgeInsets.zero)),
                      const PopupMenuItem(value: 'delete', child: ListTile(leading: Icon(Icons.delete, color: Colors.red), title: Text('Delete', style: TextStyle(color: Colors.red)), contentPadding: EdgeInsets.zero)),
                    ],
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: canAfford ? () => _redeemReward(context, ref, reward) : null,
                    child: const Text('Redeem'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteReward(BuildContext context, WidgetRef ref, Reward reward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Reward?'),
        content: Text('Are you sure you want to delete "${reward.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(rewardsProvider.notifier).deleteReward(reward.id);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${reward.title}" deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditRewardDialog(BuildContext context, WidgetRef ref, Reward reward) {
    final titleController = TextEditingController(text: reward.title);
    final costController = TextEditingController(text: reward.costPoints.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Edit Reward', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Reward Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: costController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Cost in Points', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) return;
                    
                    final updated = reward.copyWith(
                      title: titleController.text.trim(),
                      costPoints: int.tryParse(costController.text) ?? reward.costPoints,
                    );

                    ref.read(rewardsProvider.notifier).updateReward(updated);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  void _redeemReward(BuildContext context, WidgetRef ref, Reward reward) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Redeem Reward?'),
        content: Text('Are you sure you want to spend ${reward.costPoints} points on "${reward.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final redemption = RewardRedemption(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                rewardId: reward.id,
                rewardName: reward.title,
                redeemedAt: DateTime.now(),
                costPoints: reward.costPoints,
              );
              ref.read(redemptionsProvider.notifier).addRedemption(redemption);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reward redeemed! Enjoy!')));
            },
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
  }
}

class _RedemptionHistory extends StatelessWidget {
  final List<RewardRedemption> redemptions;
  final List<Reward> rewards;

  const _RedemptionHistory({required this.redemptions, required this.rewards});

  @override
  Widget build(BuildContext context) {
    if (redemptions.isEmpty) {
      return const Center(child: Text('No redemption history.', style: TextStyle(color: Colors.grey)));
    }

    // Sort descending
    final sorted = List.of(redemptions)..sort((a, b) => b.redeemedAt.compareTo(a.redeemedAt));

    return ListView.builder(
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final r = sorted[index];
        final dateFormat = DateFormat('MMM d, y, h:mm a');

        return ListTile(
          leading: const Icon(Icons.history),
          title: Text(r.rewardName),
          subtitle: Text(dateFormat.format(r.redeemedAt)),
          trailing: Text('-${r.costPoints} pts', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        );
      },
    );
  }
}
