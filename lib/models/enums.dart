import 'package:flutter/material.dart';

enum MuscleGroup {
  chest('Brust', Color(0xFFFF6B6B), Icons.fitness_center),
  back('Rücken', Color(0xFF4ECDC4), Icons.fitness_center),
  shoulders('Schultern', Color(0xFF45B7D1), Icons.fitness_center),
  biceps('Bizeps', Color(0xFFF7DC6F), Icons.fitness_center),
  triceps('Trizeps', Color(0xFFBB8FCE), Icons.fitness_center),
  forearms('Unterarme', Color(0xFFE59866), Icons.fitness_center),
  quadriceps('Quadrizeps', Color(0xFF58D68D), Icons.fitness_center),
  hamstrings('Beinbeuger', Color(0xFF5DADE2), Icons.fitness_center),
  glutes('Gesäß', Color(0xFFF1948A), Icons.fitness_center),
  calves('Waden', Color(0xFF82E0AA), Icons.fitness_center),
  core('Core', Color(0xFFAED6F1), Icons.fitness_center),
  fullBody('Ganzkörper', Color(0xFFFF6B35), Icons.fitness_center),
  cardio('Ausdauer', Color(0xFFFF4757), Icons.directions_run);

  const MuscleGroup(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

enum EquipmentType {
  barbell('Langhantel', 'equipment_squat_rack'),
  dumbbell('Kurzhantel', 'equipment_dumbbell_rack'),
  cable('Kabelzug', 'equipment_cable_crossover'),
  machine('Maschine', 'equipment_chest_press'),
  bodyweight('Körpergewicht', null),
  benchPress('Bankdrücken', 'equipment_bench_press'),
  latPulldown('Latzug', 'equipment_lat_pulldown'),
  legExtension('Beinstrecker', 'equipment_leg_extension'),
  legCurl('Beinbeuger', 'equipment_leg_curl'),
  seatedRow('Rudermaschine', 'equipment_seated_row'),
  shoulderPress('Schulterpresse', 'equipment_shoulder_press'),
  smithMachine('Multipresse', 'equipment_smith_machine'),
  chestFly('Butterfly', 'equipment_chest_fly'),
  rowingMachine('Rudergerät', 'equipment_rowing_machine'),
  treadmill('Laufband', 'equipment_treadmill'),
  stationaryBike('Ergometer', 'equipment_stationary_bike'),
  elliptical('Crosstrainer', 'equipment_elliptical');

  const EquipmentType(this.label, this.assetName);
  final String label;
  final String? assetName;

  String? get assetPath =>
      assetName != null ? 'assets/equipment/$assetName.jpg' : null;
}

enum SetType {
  warmup('Aufwärmen'),
  working('Arbeitssatz'),
  dropset('Drop Set'),
  failure('Bis Versagen');

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
  cardio('Ausdauer'),
  stretch('Dehnung');

  const ExerciseCategory(this.label);
  final String label;
}
