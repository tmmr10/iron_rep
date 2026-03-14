import 'enums.dart';

class SetEntry {
  final int id;
  final int setNumber;
  final double? weight;
  final int? reps;
  final int? durationSeconds;
  final SetType setType;
  final bool isCompleted;
  final DateTime? completedAt;

  const SetEntry({
    required this.id,
    required this.setNumber,
    this.weight,
    this.reps,
    this.durationSeconds,
    this.setType = SetType.working,
    this.isCompleted = false,
    this.completedAt,
  });

  double get volume => (weight ?? 0) * (reps ?? 0);
}
