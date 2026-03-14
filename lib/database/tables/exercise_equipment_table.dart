import 'package:drift/drift.dart';

import 'exercises_table.dart';

class ExerciseEquipment extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get exerciseId =>
      integer().references(Exercises, #id)();
  TextColumn get equipmentType => text()();
  BoolColumn get isPrimary =>
      boolean().withDefault(const Constant(true))();
}
