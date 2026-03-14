import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workouts_table.dart';
import '../tables/workout_exercises_table.dart';
import '../tables/sets_table.dart';
import '../tables/personal_records_table.dart';

part 'stats_dao.g.dart';

@DriftAccessor(tables: [Workouts, WorkoutExercises, WorkoutSets, PersonalRecords])
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
              volume: row.read<double>('total_volume'),
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
              maxWeight: row.read<double>('max_weight'),
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
              volume: row.read<double>('volume'),
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
    return result.read<double>('vol');
  }
}
