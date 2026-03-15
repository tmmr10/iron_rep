class WorkoutSummary {
  final int workoutId;
  final String? name;
  final DateTime startedAt;
  final DateTime? completedAt;
  final int? durationSeconds;
  final int exerciseCount;
  final int totalSets;
  final double totalVolume;
  final int prCount;
  final int skippedCount;

  const WorkoutSummary({
    required this.workoutId,
    this.name,
    required this.startedAt,
    this.completedAt,
    this.durationSeconds,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolume,
    this.prCount = 0,
    this.skippedCount = 0,
  });

  String get durationFormatted {
    if (durationSeconds == null) return '--:--';
    final m = durationSeconds! ~/ 60;
    final s = durationSeconds! % 60;
    return '${m}m ${s}s';
  }

  String get volumeFormatted {
    if (totalVolume >= 1000) {
      return '${(totalVolume / 1000).toStringAsFixed(1)}t';
    }
    return '${totalVolume.toStringAsFixed(0)} kg';
  }
}
