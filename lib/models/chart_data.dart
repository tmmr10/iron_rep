class VolumeDataPoint {
  final DateTime date;
  final double volume;
  const VolumeDataPoint(this.date, this.volume);
}

class StrengthDataPoint {
  final DateTime date;
  final double maxWeight;
  const StrengthDataPoint(this.date, this.maxWeight);
}

class HeatmapDay {
  final DateTime date;
  final double intensity; // 0.0 - 1.0
  const HeatmapDay(this.date, this.intensity);
}
