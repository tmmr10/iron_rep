import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import 'database_provider.dart';

// All active plans
final allPlansProvider = StreamProvider<List<TrainingPlan>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.planDao.watchAllPlans();
});

// Exercises for a specific plan
final planExercisesProvider =
    StreamProvider.family<List<PlanExercise>, int>((ref, planId) {
  final db = ref.watch(databaseProvider);
  return db.planDao.watchPlanExercises(planId);
});

// Last used plan ID
final lastUsedPlanIdProvider = FutureProvider<int?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.planDao.getLastUsedPlanId();
});

// Plan workout count
final planWorkoutCountProvider =
    FutureProvider.family<int, int>((ref, planId) {
  final db = ref.watch(databaseProvider);
  return db.planDao.getPlanWorkoutCount(planId);
});

// Plan history
final planHistoryProvider =
    FutureProvider.family<List<Workout>, int>((ref, planId) {
  final db = ref.watch(databaseProvider);
  return db.planDao.getPlanHistory(planId);
});

// Plan completion: how many exercises were done vs planned in the last workout
final planCompletionProvider = FutureProvider.family<
    ({int done, int planned})?, int>((ref, planId) async {
  final db = ref.watch(databaseProvider);

  // Get plan exercises count
  final planExercises = await db.planDao.getPlanExercises(planId);
  if (planExercises.isEmpty) return null;

  // Get last completed workout for this plan
  final history = await db.planDao.getPlanHistory(planId);
  if (history.isEmpty) return null;
  final lastWorkout = history.first;

  // Get workout exercises for the last workout
  final workoutExercises =
      await db.workoutDao.getWorkoutExercises(lastWorkout.id);

  return (done: workoutExercises.length, planned: planExercises.length);
});
