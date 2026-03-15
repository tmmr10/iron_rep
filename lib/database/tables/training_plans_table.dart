import 'package:drift/drift.dart';

class TrainingPlans extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get colorHex => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true))();
}
