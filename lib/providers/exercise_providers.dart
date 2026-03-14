import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/exercise.dart';
import 'database_provider.dart';

final allExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.exerciseDao.watchAll();
});

final exerciseSearchQueryProvider = StateProvider<String>((ref) => '');

final exerciseMuscleFilterProvider =
    StateProvider<MuscleGroup?>((ref) => null);

final filteredExercisesProvider = StreamProvider<List<Exercise>>((ref) {
  final db = ref.watch(databaseProvider);
  final query = ref.watch(exerciseSearchQueryProvider);
  final muscle = ref.watch(exerciseMuscleFilterProvider);

  if (query.isNotEmpty) {
    return db.exerciseDao.watchSearch(query);
  }
  if (muscle != null) {
    return db.exerciseDao.watchByMuscleGroup(muscle.name);
  }
  return db.exerciseDao.watchAll();
});

final exerciseWithEquipmentProvider =
    FutureProvider.family<ExerciseWithEquipment, int>((ref, exerciseId) async {
  final db = ref.watch(databaseProvider);
  final exercises = await db.exerciseDao.getAll();
  final exercise = exercises.firstWhere((e) => e.id == exerciseId);
  final equipment = await db.exerciseDao.getEquipmentForExercise(exerciseId);

  return ExerciseWithEquipment(
    id: exercise.id,
    name: exercise.name,
    nameKey: exercise.nameKey,
    instructions: exercise.instructions,
    muscleGroup: MuscleGroup.values.firstWhere(
      (m) => m.name == exercise.primaryMuscleGroup,
      orElse: () => MuscleGroup.chest,
    ),
    category: ExerciseCategory.values.firstWhere(
      (c) => c.name == exercise.category,
      orElse: () => ExerciseCategory.compound,
    ),
    isCustom: exercise.isCustom,
    equipment: equipment
        .map((e) => EquipmentType.values.firstWhere(
              (eq) => eq.name == e.equipmentType,
              orElse: () => EquipmentType.machine,
            ))
        .toList(),
  );
});
