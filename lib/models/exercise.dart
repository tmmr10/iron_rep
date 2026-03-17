import 'enums.dart';

class ExerciseWithEquipment {
  final int id;
  final String name;
  final String nameKey;
  final String? instructions;
  final MuscleGroup muscleGroup;
  final bool isCustom;
  final bool trackWeight;
  final String? imagePath;
  final List<EquipmentType> equipment;

  const ExerciseWithEquipment({
    required this.id,
    required this.name,
    required this.nameKey,
    this.instructions,
    required this.muscleGroup,
    required this.isCustom,
    this.trackWeight = true,
    this.imagePath,
    required this.equipment,
  });

  EquipmentType? get primaryEquipment =>
      equipment.isNotEmpty ? equipment.first : null;
}
