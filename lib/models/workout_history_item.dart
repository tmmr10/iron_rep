class WorkoutHistoryItem {
  final int id;
  final String? name;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationSeconds;
  final List<String> muscleGroups;
  final int setCount;
  final double totalVolume;

  const WorkoutHistoryItem({
    required this.id,
    this.name,
    required this.startedAt,
    this.completedAt,
    this.durationSeconds,
    this.muscleGroups = const [],
    this.setCount = 0,
    this.totalVolume = 0,
  });
}
