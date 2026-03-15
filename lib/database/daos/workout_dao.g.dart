// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_dao.dart';

// ignore_for_file: type=lint
mixin _$WorkoutDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrainingPlansTable get trainingPlans => attachedDatabase.trainingPlans;
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $WorkoutExercisesTable get workoutExercises =>
      attachedDatabase.workoutExercises;
  $WorkoutSetsTable get workoutSets => attachedDatabase.workoutSets;
  $PersonalRecordsTable get personalRecords => attachedDatabase.personalRecords;
  WorkoutDaoManager get managers => WorkoutDaoManager(this);
}

class WorkoutDaoManager {
  final _$WorkoutDaoMixin _db;
  WorkoutDaoManager(this._db);
  $$TrainingPlansTableTableManager get trainingPlans =>
      $$TrainingPlansTableTableManager(_db.attachedDatabase, _db.trainingPlans);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$WorkoutExercisesTableTableManager get workoutExercises =>
      $$WorkoutExercisesTableTableManager(
        _db.attachedDatabase,
        _db.workoutExercises,
      );
  $$WorkoutSetsTableTableManager get workoutSets =>
      $$WorkoutSetsTableTableManager(_db.attachedDatabase, _db.workoutSets);
  $$PersonalRecordsTableTableManager get personalRecords =>
      $$PersonalRecordsTableTableManager(
        _db.attachedDatabase,
        _db.personalRecords,
      );
}
