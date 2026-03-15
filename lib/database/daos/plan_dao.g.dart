// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_dao.dart';

// ignore_for_file: type=lint
mixin _$PlanDaoMixin on DatabaseAccessor<AppDatabase> {
  $TrainingPlansTable get trainingPlans => attachedDatabase.trainingPlans;
  $ExercisesTable get exercises => attachedDatabase.exercises;
  $PlanExercisesTable get planExercises => attachedDatabase.planExercises;
  $WorkoutsTable get workouts => attachedDatabase.workouts;
  PlanDaoManager get managers => PlanDaoManager(this);
}

class PlanDaoManager {
  final _$PlanDaoMixin _db;
  PlanDaoManager(this._db);
  $$TrainingPlansTableTableManager get trainingPlans =>
      $$TrainingPlansTableTableManager(_db.attachedDatabase, _db.trainingPlans);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db.attachedDatabase, _db.exercises);
  $$PlanExercisesTableTableManager get planExercises =>
      $$PlanExercisesTableTableManager(_db.attachedDatabase, _db.planExercises);
  $$WorkoutsTableTableManager get workouts =>
      $$WorkoutsTableTableManager(_db.attachedDatabase, _db.workouts);
}
