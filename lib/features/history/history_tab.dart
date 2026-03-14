import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/iron_card.dart';

class HistoryTab extends ConsumerWidget {
  const HistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(workoutHistoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: Column(
        children: [
          Expanded(
            child: history.when(
              data: (workouts) {
                if (workouts.isEmpty) {
                  return const EmptyState(
                    icon: Icons.history,
                    title: 'No workouts yet',
                    subtitle: 'Complete your first workout to see it here',
                  );
                }
                return ListView.separated(
                  padding: IronRepSpacing.screenPadding,
                  itemCount: workouts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: IronRepSpacing.sm),
                  itemBuilder: (context, index) {
                    final w = workouts[index];
                    final date = w.completedAt ?? w.startedAt;
                    final duration = w.durationSeconds != null
                        ? '${w.durationSeconds! ~/ 60}m'
                        : '--';

                    return IronCard(
                      onTap: () => context.push('/workout-detail/${w.id}'),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: IronRepColors.accentDim,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.fitness_center,
                                color: IronRepColors.accent, size: 24),
                          ),
                          const SizedBox(width: IronRepSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.name ?? 'Workout',
                                  style: const TextStyle(
                                    color: IronRepColors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${date.day}.${date.month}.${date.year}',
                                  style: const TextStyle(
                                    color: IronRepColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            duration,
                            style: const TextStyle(
                              color: IronRepColors.accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.chevron_right,
                              color: IronRepColors.textMuted),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
