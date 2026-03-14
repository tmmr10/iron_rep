import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/workout_summary.dart';
import 'database_provider.dart';

// Active workout state
class ActiveWorkoutState {
  final int? workoutId;
  final bool isActive;
  final Duration elapsed;
  final List<int> workoutExerciseIds;

  const ActiveWorkoutState({
    this.workoutId,
    this.isActive = false,
    this.elapsed = Duration.zero,
    this.workoutExerciseIds = const [],
  });

  ActiveWorkoutState copyWith({
    int? workoutId,
    bool? isActive,
    Duration? elapsed,
    List<int>? workoutExerciseIds,
  }) {
    return ActiveWorkoutState(
      workoutId: workoutId ?? this.workoutId,
      isActive: isActive ?? this.isActive,
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
      state = ActiveWorkoutState(
        workoutId: active.id,
        isActive: true,
        elapsed: elapsed,
      );
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive) {
        state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
      }
    });
  }

  Future<void> startWorkout({String? name}) async {
    final id = await _db.workoutDao.startWorkout(name: name);
    state = ActiveWorkoutState(
      workoutId: id,
      isActive: true,
      elapsed: Duration.zero,
    );
    _startTimer();
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

// Recent workouts for templates
final recentWorkoutsProvider = FutureProvider<List<Workout>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.getRecentWorkouts();
});
