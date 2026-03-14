import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/iron_card.dart';

class WorkoutTab extends ConsumerWidget {
  const WorkoutTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final recentWorkouts = ref.watch(recentWorkoutsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout')),
      body: SafeArea(
        child: Padding(
          padding: IronRepSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Start / Resume button
              if (activeWorkout.isActive)
                _ResumeWorkoutCard(
                  elapsed: activeWorkout.elapsed,
                  onTap: () => context.push('/active-workout'),
                )
              else
                ElevatedButton.icon(
                  onPressed: () async {
                    await ref
                        .read(activeWorkoutProvider.notifier)
                        .startWorkout();
                    if (context.mounted) context.push('/active-workout');
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Workout'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),

              const SizedBox(height: IronRepSpacing.xl),

              // Recent workouts as templates
              Text('Recent Workouts',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: IronRepSpacing.md),

              Expanded(
                child: recentWorkouts.when(
                  data: (workouts) {
                    if (workouts.isEmpty) {
                      return const EmptyState(
                        icon: Icons.fitness_center,
                        title: 'No workouts yet',
                        subtitle: 'Start your first workout to see it here',
                      );
                    }
                    return ListView.separated(
                      itemCount: workouts.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: IronRepSpacing.sm),
                      itemBuilder: (context, index) {
                        final w = workouts[index];
                        return IronCard(
                          onTap: () =>
                              context.push('/workout-detail/${w.id}'),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      w.name ?? 'Workout',
                                      style: const TextStyle(
                                        color: IronRepColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(w.completedAt ??
                                          w.startedAt),
                                      style: const TextStyle(
                                        color: IronRepColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (w.durationSeconds != null)
                                Text(
                                  '${w.durationSeconds! ~/ 60}m',
                                  style: const TextStyle(
                                    color: IronRepColors.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
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
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}.${date.month}.${date.year}';
  }
}

class _ResumeWorkoutCard extends StatelessWidget {
  final Duration elapsed;
  final VoidCallback onTap;

  const _ResumeWorkoutCard({required this.elapsed, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;

    return IronCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: IronRepColors.accentDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.play_arrow,
                color: IronRepColors.accent),
          ),
          const SizedBox(width: IronRepSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Workout in Progress',
                  style: TextStyle(
                    color: IronRepColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${m}m ${s}s elapsed',
                  style: const TextStyle(
                    color: IronRepColors.accent,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: IronRepColors.textMuted),
        ],
      ),
    );
  }
}
