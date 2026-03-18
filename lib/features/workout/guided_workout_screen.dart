import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/plan_providers.dart';
import '../../providers/timer_providers.dart';
import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../shared/widgets/weight_slider.dart';
import '../../shared/widgets/reps_stepper.dart';
import '../../l10n/l10n_helper.dart';
import 'active_workout_screen.dart';
import 'guided_rest_timer.dart';
import 'set_logger_card.dart';
import 'widgets/exercise_progress_dots.dart';

class GuidedWorkoutScreen extends ConsumerStatefulWidget {
  final int workoutId;
  final ActiveWorkoutState state;
  final StreamProvider<({int completed, int total})> Function(int)
      progressProvider;

  const GuidedWorkoutScreen({
    super.key,
    required this.workoutId,
    required this.state,
    required this.progressProvider,
  });

  @override
  ConsumerState<GuidedWorkoutScreen> createState() =>
      _GuidedWorkoutScreenState();
}

class _GuidedWorkoutScreenState extends ConsumerState<GuidedWorkoutScreen> {
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  double _currentWeight = 0;
  int _currentReps = 10;
  bool _initialized = false;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final exercisesAsync =
        ref.watch(workoutExercisesProvider(widget.workoutId));
    final timer = ref.watch(restTimerProvider);
    final elapsed = widget.state.elapsed;
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;

    // Auto-advance when rest timer expires naturally
    ref.listen(restTimerProvider, (prev, next) {
      if (prev != null && prev.isRunning && !next.isRunning) {
        _advanceAfterRest(null, null);
      }
    });

    return Scaffold(
      body: SafeArea(
        child: exercisesAsync.when(
          data: (exercises) {
            if (exercises.isEmpty) {
              return const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }

            if (_currentExerciseIndex >= exercises.length) {
              _currentExerciseIndex = exercises.length - 1;
            }

            final currentExercise = exercises[_currentExerciseIndex];
            final setsAsync = ref.watch(
                setsForWorkoutExerciseProvider(currentExercise.id));
            final allExercises = ref.watch(allExercisesProvider);
            final previousSetsAsync = ref.watch(previousSetsProvider((
              exerciseId: currentExercise.exerciseId,
              workoutId: widget.workoutId,
            )));

            final exerciseData = allExercises.whenOrNull(
              data: (list) {
                final e = list.where(
                    (e) => e.id == currentExercise.exerciseId);
                return e.isNotEmpty ? e.first : null;
              },
            );
            final exerciseName = exerciseData?.name ?? 'Exercise';
            final muscleGroup = exerciseData != null
                ? MuscleGroup.values.firstWhere(
                    (mm) => mm.name == exerciseData.primaryMuscleGroup,
                    orElse: () => MuscleGroup.chest,
                  )
                : null;

            String? nextExerciseName;
            if (_currentExerciseIndex + 1 < exercises.length) {
              final nextEx = exercises[_currentExerciseIndex + 1];
              nextExerciseName = allExercises.whenOrNull(
                data: (list) {
                  final e =
                      list.where((e) => e.id == nextEx.exerciseId);
                  return e.isNotEmpty ? e.first.name : null;
                },
              );
            }

            final sets = setsAsync.valueOrNull ?? [];
            final prevSets = previousSetsAsync.valueOrNull ?? [];
            final muscleColor = muscleGroup?.color ?? c.accent;

            // Sync notification info for background notification
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                ref.read(workoutNotificationInfoProvider.notifier).state =
                    WorkoutNotificationInfo(
                  exerciseName: exerciseName,
                  currentSetIndex: _currentSetIndex,
                  totalSets: sets.length,
                );
              }
            });

            if (!_initialized && sets.isNotEmpty) {
              final currentSet = _currentSetIndex < sets.length
                  ? sets[_currentSetIndex]
                  : sets.last;
              final prevSet = _currentSetIndex < prevSets.length
                  ? prevSets[_currentSetIndex]
                  : null;
              _currentWeight = currentSet.weight ??
                  prevSet?.weight ??
                  0;
              _currentReps = currentSet.reps ??
                  prevSet?.reps ??
                  10;
              _initialized = true;
            }

            if (_currentSetIndex >= sets.length && sets.isNotEmpty) {
              _currentSetIndex = sets.length - 1;
            }

            // If current set is completed and no rest timer running,
            // jump to first uncompleted set (e.g. after adding a set in list mode)
            if (!timer.isRunning &&
                sets.isNotEmpty &&
                _currentSetIndex < sets.length &&
                sets[_currentSetIndex].isCompleted) {
              final nextUncompleted =
                  sets.indexWhere((s) => !s.isCompleted);
              if (nextUncompleted != -1) {
                _currentSetIndex = nextUncompleted;
                _initialized = false;
              }
            }

            final currentSet = sets.isNotEmpty &&
                    _currentSetIndex < sets.length
                ? sets[_currentSetIndex]
                : null;
            final prevWeight = _currentSetIndex < prevSets.length
                ? prevSets[_currentSetIndex].weight
                : null;
            final prevReps = _currentSetIndex < prevSets.length
                ? prevSets[_currentSetIndex].reps
                : null;

            // Show rest timer if running
            if (timer.isRunning && sets.isNotEmpty) {
              // Check if there's another set in this exercise
              final nextSetIdx = sets.indexWhere(
                  (s) => !s.isCompleted, _currentSetIndex + 1);
              final String? nextSetInfo = nextSetIdx != -1
                  ? context.l10n.setOfTotal(nextSetIdx + 1, sets.length)
                  : null;

              return Column(
                children: [
                  _buildHeader(context, c, m, s, exerciseName, muscleColor),
                  Expanded(
                    child: GuidedRestTimer(
                      nextExerciseName:
                          nextSetIdx == -1 ? nextExerciseName : null,
                      nextSetInfo: nextSetInfo,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: [
                _buildHeader(context, c, m, s, exerciseName, muscleColor),
                const SizedBox(height: 20),
                // Exercise progress dots
                ExerciseProgressDots(
                  total: exercises.length,
                  currentIndex: _currentExerciseIndex,
                  onTap: (index) {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.exerciseOf(_currentExerciseIndex + 1, exercises.length),
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (nextExerciseName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      context.l10n.nextExerciseLabel(nextExerciseName!),
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                // Carousel for unified card
                Expanded(
                  child: PageView.builder(
                    key: const ValueKey('exercise-carousel'),
                    controller: _pageController,
                    itemCount: exercises.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentExerciseIndex = index;
                        _currentSetIndex = 0;
                        _initialized = false;
                      });
                    },
                    itemBuilder: (context, index) {
                      // Diff badge calculation
                      final weightDiff = prevWeight != null
                          ? _currentWeight - prevWeight
                          : null;
                      final diffColor = weightDiff == null
                          ? c.textMuted
                          : weightDiff > 0
                              ? c.success
                              : weightDiff < 0
                                  ? c.error
                                  : c.textMuted;
                      final diffPrefix = weightDiff != null && weightDiff > 0
                          ? '+'
                          : '';

                      return SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        child: Column(
                          children: [
                            // Weight card with header
                            Container(
                              decoration: BoxDecoration(
                                color: c.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: c.border.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Header Row: Satz-Info + Diff-Badge
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          sets.isNotEmpty
                                              ? context.l10n.setOfTotal(_currentSetIndex + 1, sets.length)
                                              : context.l10n.setOfTotalLoading,
                                          style: TextStyle(
                                            color: c.textMuted,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (weightDiff != null)
                                          Text(
                                            '$diffPrefix${weightDiff.toStringAsFixed(1)} kg',
                                            style: TextStyle(
                                              color: diffColor,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Divider(
                                    color: c.border.withValues(alpha: 0.2),
                                    height: 1,
                                  ),
                                  // Weight Section
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: WeightSlider(
                                      value: _currentWeight,
                                      previousValue: prevWeight,
                                      onChanged: (v) =>
                                          setState(() => _currentWeight = v),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Reps card (separate)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 24),
                              decoration: BoxDecoration(
                                color: c.card,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: c.border.withValues(alpha: 0.3),
                                ),
                              ),
                              child: RepsStepper(
                                value: _currentReps,
                                previousValue: prevReps,
                                onChanged: (v) =>
                                    setState(() => _currentReps = v),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                // Complete set button — always in tree
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Column(
                    children: [
                      TapScale(
                        onTap: currentSet == null ||
                                currentSet.isCompleted
                            ? null
                            : () => _completeSet(
                                currentSet, sets, exercises),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 18),
                          decoration: BoxDecoration(
                            gradient: currentSet?.isCompleted ?? false
                                ? null
                                : IronRepGradients.accent(c),
                            color: currentSet?.isCompleted ?? false
                                ? c.accent.withValues(alpha: 0.15)
                                : null,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: currentSet?.isCompleted ?? false
                                ? Border.all(color: c.accent.withValues(alpha: 0.3))
                                : null,
                            boxShadow:
                                currentSet?.isCompleted ?? false
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: c.accent
                                              .withValues(alpha: 0.25),
                                          blurRadius: 16,
                                          spreadRadius: -2,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                          ),
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  currentSet?.isCompleted ?? false
                                      ? Icons.check_rounded
                                      : Icons.done_rounded,
                                  color: currentSet?.isCompleted ?? false
                                      ? c.accent
                                      : Colors.black,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currentSet?.isCompleted ?? false
                                      ? context.l10n.setCompleted
                                      : context.l10n.completeSet,
                                  style: TextStyle(
                                    color: currentSet?.isCompleted ?? false
                                        ? c.accent
                                        : Colors.black,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref
                            .read(isGuidedModeProvider.notifier)
                            .state = false,
                        child: Text(
                          context.l10n.showAllExercises,
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(context.l10n.error(e.toString()))),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors c, int m, int s,
      String exerciseName, Color muscleColor) {
    final isPaused = widget.state.isPaused;

    return Container(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.border.withValues(alpha: 0.3)),
        ),
      ),
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
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: muscleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          letterSpacing: -0.3,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isPaused
                      ? context.l10n.pausedTime('${m}m ${s.toString().padLeft(2, '0')}s')
                      : '${m}m ${s.toString().padLeft(2, '0')}s',
                  style: TextStyle(
                    color: isPaused ? c.warning : c.textMuted,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TapScale(
            onTap: () =>
                ref.read(activeWorkoutProvider.notifier).togglePause(),
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
          const SizedBox(width: 8),
          TapScale(
            onTap: () => _showMoreOptions(context, c),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.more_horiz,
                  color: c.textSecondary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  void _showMoreOptions(BuildContext context, AppColors c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: c.textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TapScale(
                  onTap: () {
                    Navigator.pop(context);
                    _finishWorkout();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      context.l10n.endWorkout,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TapScale(
                  onTap: () {
                    Navigator.pop(context);
                    _showCancelDialog(context, c);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      context.l10n.discardWorkout,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, AppColors c) {
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

  Future<void> _completeSet(WorkoutSet currentSet,
      List<WorkoutSet> sets, List<WorkoutExercise> exercises) async {
    final notifier = ref.read(activeWorkoutProvider.notifier);

    await notifier.updateSet(
      currentSet.id,
      weight: _currentWeight,
      reps: _currentReps,
    );
    await notifier.completeSet(currentSet.id);
    HapticFeedback.mediumImpact();

    // Check if this was the last set of the last exercise
    final hasMoreSets = sets.any((s) => !s.isCompleted && s.id != currentSet.id);
    final isLastExercise = _currentExerciseIndex + 1 >= exercises.length;

    if (!hasMoreSets && isLastExercise) {
      // Skip timer, show finish dialog directly
      _showAllCompletedDialog();
      return;
    }

    final restSeconds =
        await ref.read(defaultRestSecondsProvider.future);
    ref.read(restTimerProvider.notifier).start(restSeconds);
  }

  void _advanceAfterRest(
      List<WorkoutSet>? setsOverride, List<WorkoutExercise>? exercisesOverride) {
    // Always read fresh data from providers
    final exercises = exercisesOverride ??
        ref.read(workoutExercisesProvider(widget.workoutId)).valueOrNull ??
        [];
    if (exercises.isEmpty || _currentExerciseIndex >= exercises.length) {
      return;
    }
    final currentEx = exercises[_currentExerciseIndex];
    final sets = setsOverride ??
        ref.read(setsForWorkoutExerciseProvider(currentEx.id)).valueOrNull ??
        [];
    if (sets.isEmpty) return;

    _initialized = false;

    final nextSetIdx = sets.indexWhere(
        (s) => !s.isCompleted, _currentSetIndex + 1);

    if (nextSetIdx != -1) {
      setState(() {
        _currentSetIndex = nextSetIdx;
      });
    } else {
      if (_currentExerciseIndex + 1 < exercises.length) {
        final nextIdx = _currentExerciseIndex + 1;
        setState(() {
          _currentExerciseIndex = nextIdx;
          _currentSetIndex = 0;
          _initialized = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(nextIdx);
          }
        });
      } else {
        _showAllCompletedDialog();
      }
    }
  }

  void _showAllCompletedDialog() {
    final c = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(context.l10n.allExercisesCompleted,
            style: TextStyle(color: c.textPrimary)),
        content: Text(context.l10n.confirmEndWorkout,
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.l10n.keepTraining,
              style: TextStyle(color: c.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _finishWorkout();
            },
            child: Text(
              context.l10n.endWorkout,
              style: TextStyle(
                color: c.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout() async {
    final state = ref.read(activeWorkoutProvider);
    final planId = state.planId;
    final summary =
        await ref.read(activeWorkoutProvider.notifier).finishWorkout();
    if (planId != null) {
      ref.invalidate(planHistoryProvider(planId));
      ref.invalidate(planCompletionProvider(planId));
    }
    if (mounted && summary != null) {
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
}
