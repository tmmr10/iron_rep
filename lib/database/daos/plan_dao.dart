import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/training_plans_table.dart';
import '../tables/plan_exercises_table.dart';
import '../tables/exercises_table.dart';
import '../tables/workouts_table.dart';

part 'plan_dao.g.dart';

@DriftAccessor(
    tables: [TrainingPlans, PlanExercises, Exercises, Workouts])
class PlanDao extends DatabaseAccessor<AppDatabase> with _$PlanDaoMixin {
  PlanDao(super.db);

  // --- Plan CRUD ---

  Stream<List<TrainingPlan>> watchAllPlans() {
    return (select(trainingPlans)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<List<TrainingPlan>> getAllPlans() {
    return (select(trainingPlans)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  Future<TrainingPlan> getPlan(int id) {
    return (select(trainingPlans)..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<int> createPlan(String name, {String? colorHex}) {
    return into(trainingPlans).insert(TrainingPlansCompanion.insert(
      name: name,
      colorHex: Value(colorHex),
    ));
  }

  Future<void> updatePlan(int id, {String? name, String? colorHex}) async {
    await (update(trainingPlans)..where((t) => t.id.equals(id))).write(
      TrainingPlansCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        colorHex: colorHex != null ? Value(colorHex) : const Value.absent(),
      ),
    );
  }

  Future<void> deletePlan(int id) async {
    await (delete(planExercises)..where((t) => t.planId.equals(id))).go();
    await (delete(trainingPlans)..where((t) => t.id.equals(id))).go();
  }

  // --- Plan Exercises ---

  Stream<List<PlanExercise>> watchPlanExercises(int planId) {
    return (select(planExercises)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .watch();
  }

  Future<List<PlanExercise>> getPlanExercises(int planId) {
    return (select(planExercises)
          ..where((t) => t.planId.equals(planId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<void> addExerciseToPlan(
      int planId, int exerciseId, int sortOrder,
      {int targetSets = 3}) {
    return into(planExercises).insert(PlanExercisesCompanion.insert(
      planId: planId,
      exerciseId: exerciseId,
      sortOrder: sortOrder,
      targetSets: Value(targetSets),
    ));
  }

  Future<void> removeExerciseFromPlan(int planExerciseId) {
    return (delete(planExercises)
          ..where((t) => t.id.equals(planExerciseId)))
        .go();
  }

  Future<void> updatePlanExerciseOrder(int id, int newOrder) async {
    await (update(planExercises)..where((t) => t.id.equals(id))).write(
      PlanExercisesCompanion(sortOrder: Value(newOrder)),
    );
  }

  Future<void> updateTargetSets(int id, int targetSets) async {
    await (update(planExercises)..where((t) => t.id.equals(id))).write(
      PlanExercisesCompanion(targetSets: Value(targetSets)),
    );
  }

  Future<void> replacePlanExercises(
      int planId, List<({int exerciseId, int targetSets})> exercises) async {
    await (delete(planExercises)..where((t) => t.planId.equals(planId))).go();
    for (var i = 0; i < exercises.length; i++) {
      await into(planExercises).insert(PlanExercisesCompanion.insert(
        planId: planId,
        exerciseId: exercises[i].exerciseId,
        sortOrder: i,
        targetSets: Value(exercises[i].targetSets),
      ));
    }
  }

  // --- Last used plan ---

  Future<int?> getLastUsedPlanId() async {
    final result = await customSelect(
      '''
      SELECT plan_id FROM workouts
      WHERE plan_id IS NOT NULL AND completed_at IS NOT NULL
      ORDER BY completed_at DESC
      LIMIT 1
      ''',
    ).getSingleOrNull();
    return result?.read<int?>('plan_id');
  }

  // --- History for a plan ---

  Future<List<Workout>> getPlanHistory(int planId, {int limit = 20}) {
    return (select(workouts)
          ..where(
              (t) => t.planId.equals(planId) & t.completedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)])
          ..limit(limit))
        .get();
  }

  Future<int> getPlanWorkoutCount(int planId) async {
    final result = await customSelect(
      'SELECT COUNT(*) AS cnt FROM workouts WHERE plan_id = ? AND completed_at IS NOT NULL',
      variables: [Variable.withInt(planId)],
    ).getSingle();
    return result.read<int>('cnt');
  }
}
