import 'package:flutter/material.dart';

enum MuscleGroup {
  chest('Chest', Color(0xFFFF6B6B), Icons.fitness_center),
  back('Back', Color(0xFF4ECDC4), Icons.fitness_center),
  shoulders('Shoulders', Color(0xFF45B7D1), Icons.fitness_center),
  biceps('Biceps', Color(0xFFF7DC6F), Icons.fitness_center),
  triceps('Triceps', Color(0xFFBB8FCE), Icons.fitness_center),
  forearms('Forearms', Color(0xFFE59866), Icons.fitness_center),
  quadriceps('Quadriceps', Color(0xFF58D68D), Icons.fitness_center),
  hamstrings('Hamstrings', Color(0xFF5DADE2), Icons.fitness_center),
  glutes('Glutes', Color(0xFFF1948A), Icons.fitness_center),
  calves('Calves', Color(0xFF82E0AA), Icons.fitness_center),
  core('Core', Color(0xFFAED6F1), Icons.fitness_center),
  fullBody('Full Body', Color(0xFFFF6B35), Icons.fitness_center),
  cardio('Cardio', Color(0xFFFF4757), Icons.directions_run);

  const MuscleGroup(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

enum EquipmentType {
  barbell('Barbell', 'equipment_squat_rack'),
  dumbbell('Dumbbell', 'equipment_dumbbell_rack'),
  cable('Cable', 'equipment_cable_crossover'),
  machine('Machine', 'equipment_chest_press'),
  bodyweight('Bodyweight', null),
  benchPress('Bench Press', 'equipment_bench_press'),
  latPulldown('Lat Pulldown', 'equipment_lat_pulldown'),
  legExtension('Leg Extension', 'equipment_leg_extension'),
  legCurl('Leg Curl', 'equipment_leg_curl'),
  seatedRow('Seated Row', 'equipment_seated_row'),
  shoulderPress('Shoulder Press', 'equipment_shoulder_press'),
  smithMachine('Smith Machine', 'equipment_smith_machine'),
  chestFly('Chest Fly', 'equipment_chest_fly'),
  rowingMachine('Rowing Machine', 'equipment_rowing_machine'),
  treadmill('Treadmill', 'equipment_treadmill'),
  stationaryBike('Stationary Bike', 'equipment_stationary_bike'),
  elliptical('Elliptical', 'equipment_elliptical');

  const EquipmentType(this.label, this.assetName);
  final String label;
  final String? assetName;

  String? get assetPath =>
      assetName != null ? 'assets/equipment/$assetName.jpg' : null;
}

enum SetType {
  warmup('Warm-up'),
  working('Working'),
  dropset('Drop Set'),
  failure('To Failure');

  const SetType(this.label);
  final String label;
}

enum WeightUnit {
  kg('kg', 1.0),
  lbs('lbs', 2.20462);

  const WeightUnit(this.label, this.factor);
  final String label;
  final double factor;

  double fromKg(double kg) => kg * factor;
  double toKg(double value) => value / factor;
}

enum ExerciseCategory {
  compound('Compound'),
  isolation('Isolation'),
  cardio('Cardio'),
  stretch('Stretch');

  const ExerciseCategory(this.label);
  final String label;
}
