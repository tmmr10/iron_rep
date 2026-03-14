import 'package:drift/drift.dart';

import 'exercises_table.dart';
import 'workouts_table.dart';

class PersonalRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id)();
  TextColumn get recordType => text()();
  RealColumn get value => real()();
  DateTimeColumn get achievedAt => dateTime()();
  IntColumn get workoutId =>
      integer().references(Workouts, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {exerciseId, recordType},
      ];
}
