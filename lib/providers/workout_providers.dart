import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/workout_history_item.dart';
import '../models/workout_summary.dart';
import 'database_provider.dart';

// Active workout state
class ActiveWorkoutState {
  final int? workoutId;
  final int? planId;
  final String? planName;
  final bool isActive;
  final bool isPaused;
  final Duration elapsed;
  final List<int> workoutExerciseIds;

  const ActiveWorkoutState({
    this.workoutId,
    this.planId,
    this.planName,
    this.isActive = false,
    this.isPaused = false,
    this.elapsed = Duration.zero,
    this.workoutExerciseIds = const [],
  });

  ActiveWorkoutState copyWith({
    int? workoutId,
    int? planId,
    String? planName,
    bool? isActive,
    bool? isPaused,
    Duration? elapsed,
    List<int>? workoutExerciseIds,
  }) {
    return ActiveWorkoutState(
      workoutId: workoutId ?? this.workoutId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      elapsed: elapsed ?? this.elapsed,
      workoutExerciseIds: workoutExerciseIds ?? this.workoutExerciseIds,
    );
  }
}

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final AppDatabase _db;
  Timer? _timer;

  ActiveWorkoutNotifier(this._db) : super(const ActiveWorkoutState()) {
    _checkForActiveWorkout();
  }

  Future<void> _checkForActiveWorkout() async {
    final active = await _db.workoutDao.getActiveWorkout();
    if (active != null) {
      final elapsed = DateTime.now().difference(active.startedAt);
      String? planName;
      if (active.planId != null) {
        try {
          final plan = await _db.planDao.getPlan(active.planId!);
          planName = plan.name;
        } catch (_) {}
      }
      state = ActiveWorkoutState(
        workoutId: active.id,
        planId: active.planId,
        planName: planName ?? active.name,
        isActive: true,
        elapsed: elapsed,
      );
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive && !state.isPaused) {
        state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
      }
    });
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  Future<void> preparePlan(int planId) async {
    final plan = await _db.planDao.getPlan(planId);
    state = ActiveWorkoutState(
      planId: planId,
      planName: plan.name,
      isActive: false,
      isPaused: false,
      elapsed: Duration.zero,
    );
  }

  Future<void> startWorkout({String? name, int? planId}) async {
    String? planName = name;
    if (planId != null) {
      final plan = await _db.planDao.getPlan(planId);
      planName = plan.name;
    }
    final id = await _db.workoutDao.startWorkout(
        name: planName, planId: planId);
    state = ActiveWorkoutState(
      workoutId: id,
      planId: planId,
      planName: planName,
      isActive: true,
      elapsed: Duration.zero,
    );
    _startTimer();

    // If starting from a plan, pre-load exercises with target sets
    if (planId != null) {
      final planExercises = await _db.planDao.getPlanExercises(planId);
      for (final pe in planExercises) {
        final weId =
            await _db.workoutDao.addExerciseToWorkout(id, pe.exerciseId);
        // Pre-create target sets
        for (var i = 0; i < pe.targetSets; i++) {
          await _db.workoutDao.addSet(weId);
        }
      }
    }
  }

  Future<void> addExercise(int exerciseId) async {
    if (state.workoutId == null) return;
    final weId = await _db.workoutDao
        .addExerciseToWorkout(state.workoutId!, exerciseId);
    // Auto-add first set
    await _db.workoutDao.addSet(weId);
  }

  Future<void> removeExercise(int workoutExerciseId) async {
    await _db.workoutDao.removeExerciseFromWorkout(workoutExerciseId);
  }

  Future<int> addSet(int workoutExerciseId) async {
    return _db.workoutDao.addSet(workoutExerciseId);
  }

  Future<void> updateSet(int setId,
      {double? weight, int? reps, String? setType}) async {
    await _db.workoutDao.updateSet(setId,
        weight: weight, reps: reps, setType: setType);
  }

  Future<void> completeSet(int setId) async {
    await _db.workoutDao.completeSet(setId);
  }

  Future<void> uncompleteSet(int setId) async {
    await _db.workoutDao.uncompleteSet(setId);
  }

  Future<void> deleteSet(int setId) async {
    await _db.workoutDao.deleteSet(setId);
  }

  Future<WorkoutSummary?> finishWorkout() async {
    if (state.workoutId == null) return null;
    final workoutId = state.workoutId!;

    // Calculate PRs
    final workoutExercises =
        await _db.workoutDao.getWorkoutExercises(workoutId);
    int prCount = 0;
    int totalSets = 0;
    double totalVolume = 0;

    for (final we in workoutExercises) {
      final sets = await _db.workoutDao.getSetsForWorkoutExercise(we.id);
      final completedSets = sets.where((s) => s.isCompleted == true).toList();
      totalSets += completedSets.length;
      for (final s in completedSets) {
        totalVolume += (s.weight ?? 0) * (s.reps ?? 0);
      }
      await _db.workoutDao
          .updatePersonalRecords(we.exerciseId, workoutId, completedSets);
    }

    // Calculate skipped exercises if workout is plan-based
    int skippedCount = 0;
    if (state.planId != null) {
      final planExercises =
          await _db.planDao.getPlanExercises(state.planId!);
      final workoutExerciseIds =
          workoutExercises.map((we) => we.exerciseId).toSet();
      skippedCount = planExercises
          .where((pe) => !workoutExerciseIds.contains(pe.exerciseId))
          .length;
    }

    await _db.workoutDao.finishWorkout(workoutId);
    _timer?.cancel();

    final workout = await (_db.select(_db.workouts)
          ..where((t) => t.id.equals(workoutId)))
        .getSingle();

    final summary = WorkoutSummary(
      workoutId: workoutId,
      name: workout.name,
      startedAt: workout.startedAt,
      completedAt: workout.completedAt,
      durationSeconds: workout.durationSeconds,
      exerciseCount: workoutExercises.length,
      totalSets: totalSets,
      totalVolume: totalVolume,
      prCount: prCount,
      skippedCount: skippedCount,
    );

    state = const ActiveWorkoutState();
    return summary;
  }

  Future<void> cancelWorkout() async {
    if (state.workoutId == null) return;
    await _db.workoutDao.cancelWorkout(state.workoutId!);
    _timer?.cancel();
    state = const ActiveWorkoutState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>((ref) {
  final db = ref.watch(databaseProvider);
  return ActiveWorkoutNotifier(db);
});

// Plan exercises with names (for pre-start view)
final planExerciseNamesProvider =
    FutureProvider.family<List<({String name, int targetSets})>, int>(
        (ref, planId) async {
  final db = ref.watch(databaseProvider);
  final planExercises = await db.planDao.getPlanExercises(planId);
  final allExercises = await db.exerciseDao.getAll();
  return planExercises.map((pe) {
    final ex = allExercises.firstWhere((e) => e.id == pe.exerciseId);
    return (name: ex.name, targetSets: pe.targetSets);
  }).toList();
});

// Workout exercises stream
final workoutExercisesProvider =
    StreamProvider.family<List<WorkoutExercise>, int>((ref, workoutId) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.watchWorkoutExercises(workoutId);
});

// Sets stream for a workout exercise
final setsForWorkoutExerciseProvider =
    StreamProvider.family<List<WorkoutSet>, int>((ref, workoutExerciseId) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.watchSetsForWorkoutExercise(workoutExerciseId);
});

// Completed workouts history
final workoutHistoryProvider = StreamProvider<List<Workout>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.watchCompletedWorkouts();
});

// Enriched workout history with muscle groups, set count, volume
final enrichedWorkoutHistoryProvider =
    StreamProvider<List<WorkoutHistoryItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.watchEnrichedHistory();
});

// Recent workouts for templates
final recentWorkoutsProvider = FutureProvider<List<Workout>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.getRecentWorkouts();
});
