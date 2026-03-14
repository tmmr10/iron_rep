import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/exercises_table.dart';
import '../tables/exercise_equipment_table.dart';

part 'exercise_dao.g.dart';

@DriftAccessor(tables: [Exercises, ExerciseEquipment])
class ExerciseDao extends DatabaseAccessor<AppDatabase>
    with _$ExerciseDaoMixin {
  ExerciseDao(super.db);

  Stream<List<Exercise>> watchAll() {
    return (select(exercises)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<List<Exercise>> getAll() {
    return (select(exercises)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Stream<List<Exercise>> watchByMuscleGroup(String muscleGroup) {
    return (select(exercises)
          ..where((t) =>
              t.isActive.equals(true) &
              t.primaryMuscleGroup.equals(muscleGroup))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Stream<List<Exercise>> watchSearch(String query) {
    return (select(exercises)
          ..where((t) =>
              t.isActive.equals(true) &
              t.name.like('%$query%'))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Exercise?> getByNameKey(String nameKey) {
    return (select(exercises)..where((t) => t.nameKey.equals(nameKey)))
        .getSingleOrNull();
  }

  Future<List<ExerciseEquipmentData>> getEquipmentForExercise(int exerciseId) {
    return (select(exerciseEquipment)
          ..where((t) => t.exerciseId.equals(exerciseId)))
        .get();
  }

  Future<int> insertExercise(ExercisesCompanion entry) {
    return into(exercises).insert(entry);
  }

  Future<void> insertEquipment(ExerciseEquipmentCompanion entry) {
    return into(exerciseEquipment).insert(entry);
  }

  Future<bool> hasExercises() async {
    final count = await (selectOnly(exercises)
          ..addColumns([exercises.id.count()]))
        .getSingle();
    return (count.read(exercises.id.count()) ?? 0) > 0;
  }
}
