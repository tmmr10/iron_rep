import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import 'add_exercise_sheet.dart';
import 'set_logger_card.dart';
import 'rest_timer_overlay.dart';

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeWorkoutProvider);
    final workoutId = state.workoutId;

    if (workoutId == null) {
      return const Scaffold(
        body: Center(child: Text('No active workout')),
      );
    }

    final exercisesAsync = ref.watch(workoutExercisesProvider(workoutId));
    final elapsed = state.elapsed;
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;

    return Scaffold(
      appBar: AppBar(
        title: Text('${m}m ${s.toString().padLeft(2, '0')}s',
            style: const TextStyle(
              color: IronRepColors.accent,
              fontWeight: FontWeight.w700,
            )),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showCancelDialog(context, ref),
        ),
        actions: [
          TextButton(
            onPressed: () => _finishWorkout(context, ref),
            child: const Text('Finish',
                style: TextStyle(
                  color: IronRepColors.success,
                  fontWeight: FontWeight.w700,
                )),
          ),
        ],
      ),
      body: Stack(
        children: [
          exercisesAsync.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline,
                          size: 64, color: IronRepColors.textMuted),
                      const SizedBox(height: 16),
                      Text('Add an exercise to get started',
                          style: TextStyle(color: IronRepColors.textSecondary)),
                    ],
                  ),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.only(
                    left: 16, right: 16, top: 8, bottom: 120),
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final we = exercises[index];
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: IronRepSpacing.md),
                    child: SetLoggerCard(
                      workoutExercise: we,
                      workoutId: workoutId,
                    ),
                  );
                },
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: RestTimerOverlay(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExercise(context, ref, workoutId),
        backgroundColor: IronRepColors.accent,
        icon: const Icon(Icons.add),
        label: const Text('Add Exercise'),
      ),
    );
  }

  void _showAddExercise(
      BuildContext context, WidgetRef ref, int workoutId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: IronRepColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => AddExerciseSheet(
          scrollController: scrollController,
          onSelect: (exerciseId) {
            ref
                .read(activeWorkoutProvider.notifier)
                .addExercise(exerciseId);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _finishWorkout(BuildContext context, WidgetRef ref) async {
    final summary = await ref
        .read(activeWorkoutProvider.notifier)
        .finishWorkout();
    if (context.mounted && summary != null) {
      context.go('/workout-complete', extra: {
        'exerciseCount': summary.exerciseCount,
        'totalSets': summary.totalSets,
        'totalVolume': summary.totalVolume,
        'durationSeconds': summary.durationSeconds ?? 0,
      });
    }
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: IronRepColors.card,
        title: const Text('Cancel Workout?'),
        content: const Text('All progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Going'),
          ),
          TextButton(
            onPressed: () async {
              await ref
                  .read(activeWorkoutProvider.notifier)
                  .cancelWorkout();
              if (context.mounted) {
                Navigator.pop(ctx);
                context.go('/workout');
              }
            },
            child: const Text('Discard',
                style: TextStyle(color: IronRepColors.error)),
          ),
        ],
      ),
    );
  }
}
