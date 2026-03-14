import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workouts_table.dart';
import '../tables/workout_exercises_table.dart';
import '../tables/sets_table.dart';
import '../tables/exercises_table.dart';
import '../tables/personal_records_table.dart';

part 'workout_dao.g.dart';

@DriftAccessor(
    tables: [Workouts, WorkoutExercises, WorkoutSets, Exercises, PersonalRecords])
class WorkoutDao extends DatabaseAccessor<AppDatabase>
    with _$WorkoutDaoMixin {
  WorkoutDao(super.db);

  // --- Workout CRUD ---

  Future<int> startWorkout({String? name}) async {
    return into(workouts).insert(WorkoutsCompanion.insert(
      startedAt: DateTime.now(),
      name: Value(name),
      isActive: const Value(true),
    ));
  }

  Future<Workout?> getActiveWorkout() {
    return (select(workouts)..where((t) => t.isActive.equals(true)))
        .getSingleOrNull();
  }

  Stream<Workout?> watchActiveWorkout() {
    return (select(workouts)..where((t) => t.isActive.equals(true)))
        .watchSingleOrNull();
  }

  Future<void> finishWorkout(int workoutId) async {
    final now = DateTime.now();
    final workout = await (select(workouts)
          ..where((t) => t.id.equals(workoutId)))
        .getSingle();
    final duration = now.difference(workout.startedAt).inSeconds;
    await (update(workouts)..where((t) => t.id.equals(workoutId))).write(
      WorkoutsCompanion(
        isActive: const Value(false),
        completedAt: Value(now),
        durationSeconds: Value(duration),
      ),
    );
  }

  Future<void> cancelWorkout(int workoutId) async {
    await (delete(workoutSets)
          ..where((t) => t.workoutExerciseId.isInQuery(
              selectOnly(workoutExercises)
                ..addColumns([workoutExercises.id])
                ..where(workoutExercises.workoutId.equals(workoutId)))))
        .go();
    await (delete(workoutExercises)
          ..where((t) => t.workoutId.equals(workoutId)))
        .go();
    await (delete(workouts)..where((t) => t.id.equals(workoutId))).go();
  }

  // --- Workout Exercises ---

  Future<int> addExerciseToWorkout(int workoutId, int exerciseId) async {
    final maxOrder = await (selectOnly(workoutExercises)
          ..addColumns([workoutExercises.sortOrder.max()])
          ..where(workoutExercises.workoutId.equals(workoutId)))
        .getSingle();
    final nextOrder =
        (maxOrder.read(workoutExercises.sortOrder.max()) ?? -1) + 1;

    return into(workoutExercises).insert(
      WorkoutExercisesCompanion.insert(
        workoutId: workoutId,
        exerciseId: exerciseId,
        sortOrder: nextOrder,
      ),
    );
  }

  Future<void> removeExerciseFromWorkout(int workoutExerciseId) async {
    await (delete(workoutSets)
          ..where((t) => t.workoutExerciseId.equals(workoutExerciseId)))
        .go();
    await (delete(workoutExercises)
          ..where((t) => t.id.equals(workoutExerciseId)))
        .go();
  }

  Stream<List<WorkoutExercise>> watchWorkoutExercises(int workoutId) {
    return (select(workoutExercises)
          ..where((t) => t.workoutId.equals(workoutId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  // --- Sets ---

  Future<int> addSet(int workoutExerciseId) async {
    final maxSet = await (selectOnly(workoutSets)
          ..addColumns([workoutSets.setNumber.max()])
          ..where(workoutSets.workoutExerciseId.equals(workoutExerciseId)))
        .getSingle();
    final nextNum = (maxSet.read(workoutSets.setNumber.max()) ?? 0) + 1;

    return into(workoutSets).insert(WorkoutSetsCompanion.insert(
      workoutExerciseId: workoutExerciseId,
      setNumber: nextNum,
    ));
  }

  Future<void> updateSet(int setId,
      {double? weight, int? reps, String? setType}) async {
    await (update(workoutSets)..where((t) => t.id.equals(setId))).write(
      WorkoutSetsCompanion(
        weight: Value(weight),
        reps: Value(reps),
        setType: setType != null ? Value(setType) : const Value.absent(),
      ),
    );
  }

  Future<void> completeSet(int setId) async {
    await (update(workoutSets)..where((t) => t.id.equals(setId))).write(
      WorkoutSetsCompanion(
        isCompleted: const Value(true),
        completedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteSet(int setId) async {
    await (delete(workoutSets)..where((t) => t.id.equals(setId))).go();
  }

  Stream<List<WorkoutSet>> watchSetsForWorkoutExercise(int workoutExerciseId) {
    return (select(workoutSets)
          ..where((t) => t.workoutExerciseId.equals(workoutExerciseId))
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
        .watch();
  }

  // --- History ---

  Stream<List<Workout>> watchCompletedWorkouts() {
    return (select(workouts)
          ..where((t) => t.completedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .watch();
  }

  Future<List<Workout>> getRecentWorkouts({int limit = 3}) {
    return (select(workouts)
          ..where((t) => t.completedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
          ..limit(limit))
        .get();
  }

  Future<List<WorkoutExercise>> getWorkoutExercises(int workoutId) {
    return (select(workoutExercises)
          ..where((t) => t.workoutId.equals(workoutId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<WorkoutSet>> getSetsForWorkoutExercise(int workoutExerciseId) {
    return (select(workoutSets)
          ..where((t) => t.workoutExerciseId.equals(workoutExerciseId))
          ..orderBy([(t) => OrderingTerm.asc(t.setNumber)]))
        .get();
  }

  // --- Previous Workout Values ---

  Future<List<WorkoutSet>> getPreviousSetsForExercise(
      int exerciseId, int excludeWorkoutId) async {
    final previousWe = await (select(workoutExercises)
          ..where((t) =>
              t.exerciseId.equals(exerciseId) &
              t.workoutId.isNotValue(excludeWorkoutId))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    if (previousWe == null) return [];
    return getSetsForWorkoutExercise(previousWe.id);
  }

  // --- Personal Records ---

  Future<void> updatePersonalRecords(
      int exerciseId, int workoutId, List<WorkoutSet> completedSets) async {
    for (final s in completedSets) {
      if (s.weight != null && s.weight! > 0) {
        await _updateRecord(
            exerciseId, 'max_weight', s.weight!, workoutId);
      }
      if (s.reps != null && s.reps! > 0) {
        await _updateRecord(
            exerciseId, 'max_reps', s.reps!.toDouble(), workoutId);
      }
      if (s.weight != null && s.reps != null) {
        final volume = s.weight! * s.reps!;
        await _updateRecord(
            exerciseId, 'max_volume', volume, workoutId);
      }
    }
  }

  Future<void> _updateRecord(
      int exerciseId, String type, double value, int workoutId) async {
    final existing = await (select(personalRecords)
          ..where((t) =>
              t.exerciseId.equals(exerciseId) &
              t.recordType.equals(type)))
        .getSingleOrNull();

    if (existing == null || value > existing.value) {
      await into(personalRecords).insertOnConflictUpdate(
        PersonalRecordsCompanion.insert(
          exerciseId: exerciseId,
          recordType: type,
          value: value,
          achievedAt: DateTime.now(),
          workoutId: workoutId,
        ),
      );
    }
  }

  Future<List<PersonalRecord>> getRecordsForExercise(int exerciseId) {
    return (select(personalRecords)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();
  }

  Stream<List<PersonalRecord>> watchAllRecords() {
    return (select(personalRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.achievedAt)]))
        .watch();
  }
}
