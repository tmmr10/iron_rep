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
