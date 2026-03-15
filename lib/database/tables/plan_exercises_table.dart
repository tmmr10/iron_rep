import 'package:drift/drift.dart';

import 'training_plans_table.dart';
import 'exercises_table.dart';

class PlanExercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get planId =>
      integer().references(TrainingPlans, #id)();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id)();
  IntColumn get sortOrder => integer()();
  IntColumn get targetSets =>
      integer().withDefault(const Constant(2))();
}
