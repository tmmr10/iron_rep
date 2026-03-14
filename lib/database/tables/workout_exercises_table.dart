import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workouts_table.dart';

class WorkoutExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();
  TextColumn get notes => text().nullable()();
}
