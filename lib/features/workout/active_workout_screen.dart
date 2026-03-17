import 'package:drift/drift.dart' show Variable;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/database_provider.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/plan_providers.dart';
import '../../providers/workout_providers.dart';
import '../../l10n/l10n_helper.dart';
import '../../shared/design_system.dart';
import '../plans/exercise_picker_sheet.dart';
import 'set_logger_card.dart';
import 'rest_timer_overlay.dart';
import 'guided_workout_screen.dart';
import '../../shared/widgets/tap_scale.dart';

final _workoutProgressProvider =
    StreamProvider.family<({int completed, int total}), int>((ref, workoutId) {
  final db = ref.watch(databaseProvider);
  return db.customSelect(
    '''
    SELECT
      COUNT(*) AS total,
      SUM(CASE WHEN s.is_completed = 1 THEN 1 ELSE 0 END) AS done
    FROM workout_sets s
    JOIN workout_exercises we ON s.workout_exercise_id = we.id
    WHERE we.workout_id = ?
    ''',
    variables: [Variable(workoutId)],
    readsFrom: {db.workoutSets, db.workoutExercises},
  ).watch().map((rows) {
    if (rows.isEmpty) return (completed: 0, total: 0);
    final row = rows.first;
    return (
      completed: row.read<int>('done'),
      total: row.read<int>('total'),
    );
  });
});

final isGuidedModeProvider = StateProvider<bool>((ref) => true);

class ActiveWorkoutScreen extends ConsumerWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final state = ref.watch(activeWorkoutProvider);
    final workoutId = state.workoutId;

    // Pre-start view: plan selected but workout not yet started
    if (workoutId == null && state.planId != null) {
      return _PreStartView(state: state);
    }

    // No plan and no workout
    if (workoutId == null) {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new,
                          size: 18, color: c.textSecondary),
                      onPressed: () => context.pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(child: Text(context.l10n.noActiveWorkout)),
              ),
            ],
          ),
        ),
      );
    }

    final isGuided = ref.watch(isGuidedModeProvider);

    if (isGuided) {
      return GuidedWorkoutScreen(
        workoutId: workoutId,
        state: state,
        progressProvider: _workoutProgressProvider,
      );
    }

    return _ListModeScreen(
      workoutId: workoutId,
      state: state,
      progressProvider: _workoutProgressProvider,
    );
  }
}

class _ListModeScreen extends ConsumerWidget {
  final int workoutId;
  final ActiveWorkoutState state;
  final StreamProvider<({int completed, int total})> Function(int)
      progressProvider;

  const _ListModeScreen({
    required this.workoutId,
    required this.state,
    required this.progressProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final exercisesAsync = ref.watch(workoutExercisesProvider(workoutId));
    final elapsed = state.elapsed;
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    final isPaused = state.isPaused;

    final progressAsync = ref.watch(progressProvider(workoutId));
    final progressData = progressAsync.valueOrNull;
    final completedSets = progressData?.completed ?? 0;
    final totalSets = progressData?.total ?? 1;
    final progressValue = totalSets > 0 ? completedSets / totalSets : 0.0;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 18, color: c.textSecondary),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          state.planName ?? context.l10n.training,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${m}m ${s.toString().padLeft(2, '0')}s',
                              style: TextStyle(
                                color: isPaused ? c.warning : c.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            if (isPaused)
                              Text(
                                ' · ${context.l10n.paused}',
                                style: TextStyle(
                                  color: c.warning,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Text(
                              ' · ${context.l10n.completedOfTotalSets(completedSets, totalSets)}',
                              style: TextStyle(
                                color: c.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Guided mode toggle
                  TapScale(
                    onTap: () =>
                        ref.read(isGuidedModeProvider.notifier).state = true,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.view_carousel_outlined,
                          color: c.textSecondary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Pause button
                  TapScale(
                    onTap: () => ref
                        .read(activeWorkoutProvider.notifier)
                        .togglePause(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPaused
                            ? c.warning.withValues(alpha: 0.15)
                            : c.surface,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isPaused
                            ? Icons.play_arrow_rounded
                            : Icons.pause_rounded,
                        color: isPaused ? c.warning : c.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress bar with gradient
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 4,
                  child: Stack(
                    children: [
                      Container(color: c.surface),
                      FractionallySizedBox(
                        widthFactor: progressValue.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: progressValue >= 1.0
                                ? null
                                : IronRepGradients.accent(c),
                            color: progressValue >= 1.0 ? c.success : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Exercises
            Expanded(
              child: Stack(
                children: [
                  exercisesAsync.when(
                    data: (exercises) {
                      if (exercises.isEmpty) {
                        return const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      return ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                        itemCount: exercises.length + 1,
                        separatorBuilder: (_, __) => Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: Divider(color: c.border, height: 1),
                        ),
                        itemBuilder: (context, index) {
                          if (index == exercises.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: TapScale(
                                onTap: () => _showAddExercise(context, ref),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: c.border),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add, color: c.textMuted, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        context.l10n.addExercise,
                                        style: TextStyle(
                                          color: c.textMuted,
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          final we = exercises[index];
                          return SetLoggerCard(
                            key: ValueKey(we.id),
                            workoutExercise: we,
                            workoutId: workoutId,
                            initiallyExpanded: index == 0,
                          );
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text(context.l10n.error(e.toString()))),
                  ),
                  const Positioned(
                    left: 0,
                    right: 0,
                    bottom: 60,
                    child: RestTimerOverlay(),
                  ),
                ],
              ),
            ),
            // Bottom bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Column(
                children: [
                  TapScale(
                    onTap: () => _finishWorkout(context, ref),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: IronRepGradients.accent(c),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: c.accent.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          context.l10n.endWorkout,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  TapScale(
                    onTap: () => _showCancelDialog(context, ref),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        context.l10n.discard,
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finishWorkout(BuildContext context, WidgetRef ref) async {
    final state = ref.read(activeWorkoutProvider);
    final planId = state.planId;
    final summary =
        await ref.read(activeWorkoutProvider.notifier).finishWorkout();
    if (planId != null) {
      ref.invalidate(planHistoryProvider(planId));
      ref.invalidate(planCompletionProvider(planId));
    }
    if (context.mounted && summary != null) {
      context.go('/workout-complete', extra: {
        'planName': state.planName,
        'exerciseCount': summary.exerciseCount,
        'totalSets': summary.totalSets,
        'totalVolume': summary.totalVolume,
        'durationSeconds': summary.durationSeconds ?? 0,
        'skippedCount': summary.skippedCount,
      });
    }
  }

  void _showAddExercise(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    ref.read(exerciseSearchQueryProvider.notifier).state = '';
    ref.read(exerciseMuscleFilterProvider.notifier).state = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ExercisePickerSheet(
          scrollController: scrollController,
          excludeIds: const {},
          onSelect: (exerciseId, name) async {
            await ref
                .read(activeWorkoutProvider.notifier)
                .addExercise(exerciseId);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(context.l10n.discardWorkoutConfirm,
            style: TextStyle(color: c.textPrimary)),
        content: Text(context.l10n.allProgressWillBeLost,
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.l10n.continueTraining),
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
            child: Text(context.l10n.discard, style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
  }
}

class _PreStartView extends ConsumerWidget {
  final ActiveWorkoutState state;

  const _PreStartView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final planExercisesAsync =
        ref.watch(planExerciseNamesProvider(state.planId!));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new,
                        size: 18, color: c.textSecondary),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      state.planName ?? context.l10n.training,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: planExercisesAsync.when(
                data: (exercises) {
                  if (exercises.isEmpty) {
                    return Center(
                      child: Text(
                        context.l10n.noExercisesInPlan,
                        style: TextStyle(color: c.textMuted),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: exercises.length,
                    separatorBuilder: (_, __) =>
                        Divider(color: c.border, height: 1),
                    itemBuilder: (context, index) {
                      final ex = exercises[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                ex.name,
                                style: TextStyle(
                                  color: c.textPrimary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Text(
                              context.l10n.setsCompact(ex.targetSets),
                              style: TextStyle(
                                color: c.textMuted,
                                fontSize: 14,
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
                error: (e, _) => Center(child: Text(context.l10n.error(e.toString()))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: TapScale(
                onTap: () async {
                  await ref
                      .read(activeWorkoutProvider.notifier)
                      .startWorkout(planId: state.planId);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: c.accent.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      context.l10n.startWorkout,
                      style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
