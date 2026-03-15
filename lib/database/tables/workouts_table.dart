import 'package:drift/drift.dart';

import 'training_plans_table.dart';

class Workouts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().nullable()();
  IntColumn get planId =>
      integer().nullable().references(TrainingPlans, #id)();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get durationSeconds => integer().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(false))();
}
