import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

final totalWorkoutsProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.getTotalWorkoutCount();
});

final totalSetsProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.getTotalSetsCount();
});

final totalVolumeProvider = FutureProvider<double>((ref) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.getTotalVolume();
});

final volumePerWorkoutProvider = FutureProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.getVolumePerWorkout();
});

final strengthProgressProvider =
    FutureProvider.family((ref, int exerciseId) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.getStrengthProgress(exerciseId);
});

final workoutDaysProvider = FutureProvider((ref) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.getWorkoutDays();
});

final allPersonalRecordsProvider =
    StreamProvider<List<PersonalRecord>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.watchAllRecords();
});

final workoutsThisWeekProvider = FutureProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.getWorkoutsThisWeek();
});

final currentStreakProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();

  // Find Monday of current week
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final currentWeekStart =
      DateTime(monday.year, monday.month, monday.day);

  int streak = 0;
  var weekStart = currentWeekStart;

  while (true) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final result = await db.customSelect(
      'SELECT COUNT(*) AS cnt FROM workouts '
      'WHERE completed_at IS NOT NULL '
      'AND completed_at >= ? AND completed_at < ?',
      variables: [
        Variable.withDateTime(weekStart),
        Variable.withDateTime(weekEnd),
      ],
    ).getSingle();

    final count = result.read<int>('cnt');
    if (count > 0) {
      streak++;
      weekStart = weekStart.subtract(const Duration(days: 7));
    } else {
      break;
    }
  }

  return streak;
});

final avgWorkoutDurationProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final result = await db.customSelect(
    'SELECT AVG(duration_seconds) AS avg_dur FROM workouts '
    'WHERE completed_at IS NOT NULL AND duration_seconds IS NOT NULL AND duration_seconds > 0',
  ).getSingle();
  return ((result.data['avg_dur'] as num?)?.toDouble() ?? 0).round();
});

final totalPRsProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
  final result = await db.customSelect(
    'SELECT COUNT(*) AS cnt FROM personal_records WHERE achieved_at >= ?',
    variables: [Variable.withDateTime(thirtyDaysAgo)],
  ).getSingle();
  return result.read<int>('cnt');
});

final weeklyFrequencyProvider =
    FutureProvider<List<({DateTime weekStart, int count})>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final currentWeekStart =
      DateTime(monday.year, monday.month, monday.day);

  final List<({DateTime weekStart, int count})> weeks = [];

  for (int i = 7; i >= 0; i--) {
    final weekStart =
        currentWeekStart.subtract(Duration(days: 7 * i));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final result = await db.customSelect(
      'SELECT COUNT(*) AS cnt FROM workouts '
      'WHERE completed_at IS NOT NULL '
      'AND completed_at >= ? AND completed_at < ?',
      variables: [
        Variable.withDateTime(weekStart),
        Variable.withDateTime(weekEnd),
      ],
    ).getSingle();

    weeks.add((
      weekStart: weekStart,
      count: result.read<int>('cnt'),
    ));
  }

  return weeks;
});

// ({planId, weeks}): planId 0 = alle, weeks = Vergleichszeitraum pro Hälfte
final overallProgressProvider = FutureProvider.family<
    ({double volumeChange, double frequencyChange, double avgWeightChange, bool hasPriorData}),
    ({int planId, int weeks})>((ref, params) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final weeks = params.weeks;
  final planId = params.planId;

  // weeks == 0 → "Gesamt": split all history in half
  late final DateTime recentEnd;
  late final DateTime recentStart;
  late final DateTime priorStart;
  late final int effectiveWeeks;

  if (weeks == 0) {
    final planFilter = planId > 0 ? 'AND w.plan_id = ?' : '';
    final firstRow = await db.customSelect(
      'SELECT MIN(w.completed_at) AS first_date FROM workouts w '
      'WHERE w.completed_at IS NOT NULL $planFilter',
      variables: [if (planId > 0) Variable.withInt(planId)],
    ).getSingle();
    final firstDateEpoch = firstRow.readNullable<int>('first_date');
    if (firstDateEpoch == null) {
      return (volumeChange: 0.0, frequencyChange: 0.0, avgWeightChange: 0.0, hasPriorData: false);
    }
    final firstDate = DateTime.fromMillisecondsSinceEpoch(firstDateEpoch * 1000);
    final totalDays = now.difference(firstDate).inDays;
    if (totalDays <= 0) {
      // All workouts on the same day — treat as current data with no prior comparison
      return (volumeChange: 0.0, frequencyChange: 0.0, avgWeightChange: 0.0, hasPriorData: true);
    }
    final halfDays = (totalDays / 2).ceil().clamp(1, totalDays);
    recentEnd = now;
    recentStart = now.subtract(Duration(days: halfDays));
    priorStart = recentStart.subtract(Duration(days: halfDays));
    effectiveWeeks = (halfDays / 7).ceil().clamp(1, halfDays);
  } else {
    recentEnd = now;
    recentStart = now.subtract(Duration(days: 7 * weeks));
    priorStart = recentStart.subtract(Duration(days: 7 * weeks));
    effectiveWeeks = weeks;
  }

  final planFilter = planId > 0 ? 'AND w.plan_id = ?' : '';
  List<Variable> vars(DateTime from, DateTime to) => [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        if (planId > 0) Variable.withInt(planId),
      ];

  Future<double> avgVolume(DateTime from, DateTime to) async {
    final r = await db.customSelect(
      '''
      SELECT AVG(wv.vol) AS avg_vol FROM (
        SELECT w.id, COALESCE(SUM(s.weight * s.reps), 0) AS vol
        FROM workouts w
        JOIN workout_exercises we ON we.workout_id = w.id
        JOIN workout_sets s ON s.workout_exercise_id = we.id
        WHERE w.completed_at IS NOT NULL
          AND w.completed_at >= ? AND w.completed_at < ?
          AND s.is_completed = 1 AND s.weight IS NOT NULL
          $planFilter
        GROUP BY w.id
      ) wv
      ''',
      variables: vars(from, to),
    ).getSingle();
    return (r.data['avg_vol'] as num?)?.toDouble() ?? 0;
  }

  Future<double> avgFrequency(DateTime from, DateTime to) async {
    final r = await db.customSelect(
      'SELECT COUNT(*) AS cnt FROM workouts w '
      'WHERE w.completed_at IS NOT NULL AND w.completed_at >= ? AND w.completed_at < ? '
      '$planFilter',
      variables: vars(from, to),
    ).getSingle();
    return r.read<int>('cnt') / effectiveWeeks.toDouble();
  }

  Future<double> avgMaxWeight(DateTime from, DateTime to) async {
    final r = await db.customSelect(
      '''
      SELECT AVG(max_w) AS avg_w FROM (
        SELECT we.exercise_id, MAX(s.weight) AS max_w
        FROM workout_sets s
        JOIN workout_exercises we ON s.workout_exercise_id = we.id
        JOIN workouts w ON we.workout_id = w.id
        WHERE w.completed_at IS NOT NULL
          AND w.completed_at >= ? AND w.completed_at < ?
          AND s.is_completed = 1 AND s.weight IS NOT NULL
          $planFilter
        GROUP BY we.exercise_id
      )
      ''',
      variables: vars(from, to),
    ).getSingle();
    return (r.data['avg_w'] as num?)?.toDouble() ?? 0;
  }

  // Find exercise IDs that appear in both periods (intersection)
  Future<Set<int>> exerciseIdsInPeriod(DateTime from, DateTime to) async {
    final rows = await db.customSelect(
      '''
      SELECT DISTINCT we.exercise_id
      FROM workout_exercises we
      JOIN workouts w ON we.workout_id = w.id
      JOIN workout_sets s ON s.workout_exercise_id = we.id
      WHERE w.completed_at IS NOT NULL
        AND w.completed_at >= ? AND w.completed_at < ?
        AND s.is_completed = 1 AND s.weight IS NOT NULL
        $planFilter
      ''',
      variables: vars(from, to),
    ).get();
    return rows.map((r) => r.read<int>('exercise_id')).toSet();
  }

  final recentIds = await exerciseIdsInPeriod(recentStart, recentEnd);
  final priorIds = await exerciseIdsInPeriod(priorStart, recentStart);
  final matchedIds = recentIds.intersection(priorIds);

  // Build a SQL filter for matched exercises (only when both periods have data)
  final matchedFilter = matchedIds.isNotEmpty
      ? 'AND we.exercise_id IN (${matchedIds.join(",")})'
      : '';

  Future<double> avgVolumeMatched(DateTime from, DateTime to) async {
    final r = await db.customSelect(
      '''
      SELECT AVG(wv.vol) AS avg_vol FROM (
        SELECT w.id, COALESCE(SUM(s.weight * s.reps), 0) AS vol
        FROM workouts w
        JOIN workout_exercises we ON we.workout_id = w.id
        JOIN workout_sets s ON s.workout_exercise_id = we.id
        WHERE w.completed_at IS NOT NULL
          AND w.completed_at >= ? AND w.completed_at < ?
          AND s.is_completed = 1 AND s.weight IS NOT NULL
          $planFilter
          $matchedFilter
        GROUP BY w.id
      ) wv
      ''',
      variables: vars(from, to),
    ).getSingle();
    return (r.data['avg_vol'] as num?)?.toDouble() ?? 0;
  }

  Future<double> avgMaxWeightMatched(DateTime from, DateTime to) async {
    final r = await db.customSelect(
      '''
      SELECT AVG(max_w) AS avg_w FROM (
        SELECT we.exercise_id, MAX(s.weight) AS max_w
        FROM workout_sets s
        JOIN workout_exercises we ON s.workout_exercise_id = we.id
        JOIN workouts w ON we.workout_id = w.id
        WHERE w.completed_at IS NOT NULL
          AND w.completed_at >= ? AND w.completed_at < ?
          AND s.is_completed = 1 AND s.weight IS NOT NULL
          $planFilter
          $matchedFilter
        GROUP BY we.exercise_id
      )
      ''',
      variables: vars(from, to),
    ).getSingle();
    return (r.data['avg_w'] as num?)?.toDouble() ?? 0;
  }

  double pctChange(double recent, double prior) =>
      prior > 0 ? (recent - prior) / prior * 100 : 0;

  final recentVol = matchedIds.isNotEmpty
      ? await avgVolumeMatched(recentStart, recentEnd)
      : await avgVolume(recentStart, recentEnd);
  final priorVol = matchedIds.isNotEmpty
      ? await avgVolumeMatched(priorStart, recentStart)
      : await avgVolume(priorStart, recentStart);
  final recentFreq = await avgFrequency(recentStart, recentEnd);
  final priorFreq = await avgFrequency(priorStart, recentStart);
  final recentWeight = matchedIds.isNotEmpty
      ? await avgMaxWeightMatched(recentStart, recentEnd)
      : await avgMaxWeight(recentStart, recentEnd);
  final priorWeight = matchedIds.isNotEmpty
      ? await avgMaxWeightMatched(priorStart, recentStart)
      : await avgMaxWeight(priorStart, recentStart);

  final hasPriorData = priorVol > 0 || priorFreq > 0 || priorWeight > 0;
  final hasAnyData = hasPriorData || recentVol > 0 || recentFreq > 0 || recentWeight > 0;

  return (
    volumeChange: pctChange(recentVol, priorVol),
    frequencyChange: pctChange(recentFreq, priorFreq),
    avgWeightChange: pctChange(recentWeight, priorWeight),
    hasPriorData: hasAnyData,
  );
});

// Per-exercise progress: shows how each exercise changed between periods
final exerciseProgressProvider = FutureProvider.family<
    List<({int exerciseId, String name, String muscleGroup, double recentMax, double priorMax, double change})>,
    ({int planId, int weeks})>((ref, params) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final weeks = params.weeks;
  final planId = params.planId;

  late final DateTime recentStart;
  late final DateTime priorStart;

  if (weeks == 0) {
    final planFilter0 = planId > 0 ? 'AND w.plan_id = ?' : '';
    final firstRow = await db.customSelect(
      'SELECT MIN(w.completed_at) AS first_date FROM workouts w '
      'WHERE w.completed_at IS NOT NULL $planFilter0',
      variables: [if (planId > 0) Variable.withInt(planId)],
    ).getSingle();
    final firstDateEpoch = firstRow.readNullable<int>('first_date');
    if (firstDateEpoch == null) return [];
    final firstDate = DateTime.fromMillisecondsSinceEpoch(firstDateEpoch * 1000);
    final totalDays = now.difference(firstDate).inDays;
    if (totalDays <= 0) return [];
    final halfDays = (totalDays / 2).ceil().clamp(1, totalDays);
    recentStart = now.subtract(Duration(days: halfDays));
    priorStart = recentStart.subtract(Duration(days: halfDays));
  } else {
    recentStart = now.subtract(Duration(days: 7 * weeks));
    priorStart = recentStart.subtract(Duration(days: 7 * weeks));
  }

  final planFilter = planId > 0 ? 'AND w.plan_id = ?' : '';
  List<Variable> vars(DateTime from, DateTime to) => [
        Variable.withDateTime(from),
        Variable.withDateTime(to),
        if (planId > 0) Variable.withInt(planId),
      ];

  // Get max weight per exercise in recent period
  Future<Map<int, double>> maxWeightsInPeriod(DateTime from, DateTime to) async {
    final rows = await db.customSelect(
      '''
      SELECT we.exercise_id, MAX(s.weight) AS max_w
      FROM workout_sets s
      JOIN workout_exercises we ON s.workout_exercise_id = we.id
      JOIN workouts w ON we.workout_id = w.id
      WHERE w.completed_at IS NOT NULL
        AND w.completed_at >= ? AND w.completed_at < ?
        AND s.is_completed = 1 AND s.weight IS NOT NULL
        $planFilter
      GROUP BY we.exercise_id
      ''',
      variables: vars(from, to),
    ).get();
    return {for (final r in rows) r.read<int>('exercise_id'): (r.data['max_w'] as num).toDouble()};
  }

  final recentWeights = await maxWeightsInPeriod(recentStart, now);
  final priorWeights = await maxWeightsInPeriod(priorStart, recentStart);

  // Only include exercises that appear in both periods
  final commonIds = recentWeights.keys.toSet().intersection(priorWeights.keys.toSet());
  if (commonIds.isEmpty) return [];

  // Get exercise names
  final nameRows = await db.customSelect(
    'SELECT id, name, primary_muscle_group FROM exercises WHERE id IN (${commonIds.join(",")})',
  ).get();
  final names = {for (final r in nameRows) r.read<int>('id'): (name: r.read<String>('name'), muscle: r.read<String>('primary_muscle_group'))};

  final results = commonIds.map((id) {
    final recent = recentWeights[id]!;
    final prior = priorWeights[id]!;
    final change = prior > 0 ? (recent - prior) / prior * 100 : 0.0;
    return (
      exerciseId: id,
      name: names[id]?.name ?? 'Unknown',
      muscleGroup: names[id]?.muscle ?? '',
      recentMax: recent,
      priorMax: prior,
      change: change,
    );
  }).toList();

  // Sort by absolute change descending (biggest improvements first)
  results.sort((a, b) => b.change.abs().compareTo(a.change.abs()));
  return results;
});

final weeklyVolumeProvider =
    FutureProvider<List<({DateTime weekStart, double volume})>>((ref) async {
  final db = ref.watch(databaseProvider);
  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final currentWeekStart = DateTime(monday.year, monday.month, monday.day);

  final List<({DateTime weekStart, double volume})> weeks = [];

  for (int i = 7; i >= 0; i--) {
    final weekStart = currentWeekStart.subtract(Duration(days: 7 * i));
    final weekEnd = weekStart.add(const Duration(days: 7));

    final result = await db.customSelect(
      '''
      SELECT COALESCE(SUM(s.weight * s.reps), 0) AS volume
      FROM workout_sets s
      JOIN workout_exercises we ON s.workout_exercise_id = we.id
      JOIN workouts w ON we.workout_id = w.id
      WHERE w.completed_at IS NOT NULL
        AND w.completed_at >= ? AND w.completed_at < ?
        AND s.is_completed = 1
        AND s.weight IS NOT NULL
      ''',
      variables: [
        Variable.withDateTime(weekStart),
        Variable.withDateTime(weekEnd),
      ],
    ).getSingle();

    final volume = (result.data['volume'] as num).toDouble();
    weeks.add((weekStart: weekStart, volume: volume));
  }

  return weeks;
});

final muscleDistributionProvider =
    FutureProvider<List<({String muscleGroup, int count})>>((ref) async {
  final db = ref.watch(databaseProvider);
  final results = await db.customSelect(
    '''
    SELECT e.primary_muscle_group AS muscle_group, COUNT(*) AS cnt
    FROM workout_exercises we
    JOIN workouts w ON we.workout_id = w.id
    JOIN exercises e ON we.exercise_id = e.id
    WHERE w.completed_at IS NOT NULL
    GROUP BY e.primary_muscle_group
    ORDER BY cnt DESC
    ''',
  ).get();

  return results
      .map((row) => (
            muscleGroup: row.read<String>('muscle_group'),
            count: row.read<int>('cnt'),
          ))
      .toList();
});
