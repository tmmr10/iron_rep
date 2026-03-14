import 'package:drift/drift.dart';

import 'workout_exercises_table.dart';

@DataClassName('WorkoutSet')
class WorkoutSets extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutExerciseId =>
      integer().references(WorkoutExercises, #id)();
  IntColumn get setNumber => integer()();
  RealColumn get weight => real().nullable()();
  IntColumn get reps => integer().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get setType =>
      text().withDefault(const Constant('working'))();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}
