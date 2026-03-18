import 'package:drift/drift.dart';

import '../../models/workout_history_item.dart';
import '../app_database.dart';
import '../tables/exercises_table.dart';
import '../tables/workouts_table.dart';
import '../tables/workout_exercises_table.dart';
import '../tables/sets_table.dart';
import '../tables/personal_records_table.dart';

part 'stats_dao.g.dart';

@DriftAccessor(tables: [Workouts, WorkoutExercises, Exercises, WorkoutSets, PersonalRecords])
class StatsDao extends DatabaseAccessor<AppDatabase> with _$StatsDaoMixin {
  StatsDao(super.db);

  /// Total volume (weight * reps) per workout, last N workouts
  Future<List<({int workoutId, DateTime date, double volume})>>
      getVolumePerWorkout({int limit = 20}) async {
    final results = await customSelect(
      '''
      SELECT w.id AS workout_id, w.started_at,
             COALESCE(SUM(s.weight * s.reps), 0) AS total_volume
      FROM workouts w
      JOIN workout_exercises we ON we.workout_id = w.id
      JOIN workout_sets s ON s.workout_exercise_id = we.id
      WHERE w.completed_at IS NOT NULL AND s.is_completed = 1
      GROUP BY w.id
      ORDER BY w.started_at DESC
      LIMIT ?
      ''',
      variables: [Variable.withInt(limit)],
    ).get();

    return results
        .map((row) => (
              workoutId: row.read<int>('workout_id'),
              date: DateTime.fromMillisecondsSinceEpoch(
                  row.read<int>('started_at') * 1000),
              volume: (row.data['total_volume'] as num).toDouble(),
            ))
        .toList()
        .reversed
        .toList();
  }

  /// Max weight per session for a specific exercise
  Future<List<({DateTime date, double maxWeight})>>
      getStrengthProgress(int exerciseId, {int limit = 30}) async {
    final results = await customSelect(
      '''
      SELECT w.started_at, MAX(s.weight) AS max_weight
      FROM workouts w
      JOIN workout_exercises we ON we.workout_id = w.id
      JOIN workout_sets s ON s.workout_exercise_id = we.id
      WHERE we.exercise_id = ? AND w.completed_at IS NOT NULL
        AND s.is_completed = 1 AND s.weight IS NOT NULL
      GROUP BY w.id
      ORDER BY w.started_at DESC
      LIMIT ?
      ''',
      variables: [Variable.withInt(exerciseId), Variable.withInt(limit)],
    ).get();

    return results
        .map((row) => (
              date: DateTime.fromMillisecondsSinceEpoch(
                  row.read<int>('started_at') * 1000),
              maxWeight: (row.data['max_weight'] as num).toDouble(),
            ))
        .toList()
        .reversed
        .toList();
  }

  /// Workout days with total volume for heatmap
  Future<List<({DateTime date, double volume})>> getWorkoutDays(
      {int days = 365}) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final results = await customSelect(
      '''
      SELECT DATE(w.started_at, 'unixepoch') AS day,
             COALESCE(SUM(s.weight * s.reps), 0) AS volume
      FROM workouts w
      JOIN workout_exercises we ON we.workout_id = w.id
      JOIN workout_sets s ON s.workout_exercise_id = we.id
      WHERE w.completed_at IS NOT NULL AND s.is_completed = 1
        AND w.started_at > ?
      GROUP BY day
      ''',
      variables: [Variable.withInt(since.millisecondsSinceEpoch ~/ 1000)],
    ).get();

    return results
        .map((row) => (
              date: DateTime.parse(row.read<String>('day')),
              volume: (row.data['volume'] as num).toDouble(),
            ))
        .toList();
  }

  /// Total workouts count
  Future<int> getTotalWorkoutCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM workouts WHERE completed_at IS NOT NULL',
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Total sets completed
  Future<int> getTotalSetsCount() async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM workout_sets WHERE is_completed = 1',
    ).getSingle();
    return result.read<int>('cnt');
  }

  /// Total volume lifted
  Future<double> getTotalVolume() async {
    final result = await customSelect(
      'SELECT COALESCE(SUM(weight * reps), 0) AS vol FROM workout_sets WHERE is_completed = 1',
    ).getSingle();
    return (result.data['vol'] as num).toDouble();
  }

  /// Enriched history: workout + muscle groups, set count, total volume
  Stream<List<WorkoutHistoryItem>> watchEnrichedHistory() {
    return customSelect(
      '''
      SELECT w.id, w.name, w.started_at, w.completed_at, w.duration_seconds,
             GROUP_CONCAT(DISTINCT e.primary_muscle_group) AS muscle_groups,
             COUNT(DISTINCT CASE WHEN s.is_completed = 1 THEN s.id END) AS set_count,
             COALESCE(SUM(CASE WHEN s.is_completed = 1 THEN s.weight * s.reps ELSE 0 END), 0) AS total_volume
      FROM workouts w
      LEFT JOIN workout_exercises we ON we.workout_id = w.id
      LEFT JOIN exercises e ON we.exercise_id = e.id
      LEFT JOIN workout_sets s ON s.workout_exercise_id = we.id
      WHERE w.completed_at IS NOT NULL
      GROUP BY w.id
      ORDER BY w.completed_at DESC
      ''',
      readsFrom: {workouts, workoutExercises, exercises, workoutSets},
    ).watch().map((rows) => rows.map((row) {
          final muscleStr = row.readNullable<String>('muscle_groups');
          return WorkoutHistoryItem(
            id: row.read<int>('id'),
            name: row.readNullable<String>('name'),
            startedAt: DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('started_at') * 1000),
            completedAt: row.readNullable<int>('completed_at') != null
                ? DateTime.fromMillisecondsSinceEpoch(
                    row.read<int>('completed_at') * 1000)
                : null,
            durationSeconds: row.readNullable<int>('duration_seconds'),
            muscleGroups: muscleStr != null
                ? muscleStr.split(',').where((s) => s.isNotEmpty).toList()
                : [],
            setCount: row.read<int>('set_count'),
            totalVolume: (row.data['total_volume'] as num).toDouble(),
          );
        }).toList());
  }

  /// Count completed workouts this week (since Monday 00:00)
  Future<int> getWorkoutsThisWeek() async {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final sinceEpoch = monday.millisecondsSinceEpoch ~/ 1000;
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM workouts WHERE completed_at IS NOT NULL AND started_at >= ?',
      variables: [Variable.withInt(sinceEpoch)],
    ).getSingle();
    return result.read<int>('cnt');
  }
}
