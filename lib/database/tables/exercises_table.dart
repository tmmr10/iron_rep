import 'package:drift/drift.dart';

class Exercises extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(max: 100)();
  TextColumn get nameKey => text().unique()();
  TextColumn get instructions => text().nullable()();
  TextColumn get primaryMuscleGroup => text()();
  TextColumn get category => text()();
  BoolColumn get trackWeight => boolean().withDefault(const Constant(true))();
  BoolColumn get isCustom => boolean().withDefault(const Constant(false))();
  TextColumn get imagePath => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}
