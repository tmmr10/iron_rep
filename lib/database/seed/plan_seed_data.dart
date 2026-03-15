import '../app_database.dart';

class PlanSeedData {
  static Future<void> seed(AppDatabase db) async {
    // Only seed if no plans exist
    final existing = await db.planDao.getAllPlans();
    if (existing.isNotEmpty) {
      // Update default plan colors to match current palette
      for (final plan in existing) {
        {
          final color = switch (plan.name) {
            'Upper Body' || 'Oberkörper' => 'C4756E',
            'Lower Body' || 'Unterkörper' => '6BA38E',
            'Full Body' || 'Ganzkörper' => '7B9BC7',
            _ => null,
          };
          if (color != null) {
            await db.planDao.updatePlan(plan.id, colorHex: color);
          }
        }
      }
      return;
    }

    // Look up exercises by nameKey
    Future<int?> exerciseId(String nameKey) async {
      final e = await db.exerciseDao.getByNameKey(nameKey);
      return e?.id;
    }

    // Upper Body plan (dusty rose)
    final upperId = await db.planDao.createPlan('Oberkörper', colorHex: 'C4756E');
    final upperExercises = [
      'bench_press',
      'incline_bench_press',
      'overhead_press',
      'lat_pulldown',
      'barbell_row',
      'barbell_curl',
      'tricep_pushdown',
    ];
    for (var i = 0; i < upperExercises.length; i++) {
      final id = await exerciseId(upperExercises[i]);
      if (id != null) {
        await db.planDao.addExerciseToPlan(upperId, id, i);
      }
    }

    // Lower Body plan (sage green)
    final lowerId = await db.planDao.createPlan('Unterkörper', colorHex: '6BA38E');
    final lowerExercises = [
      'barbell_squat',
      'leg_press',
      'leg_extension',
      'romanian_deadlift',
      'leg_curl',
      'hip_thrust',
      'standing_calf_raise',
    ];
    for (var i = 0; i < lowerExercises.length; i++) {
      final id = await exerciseId(lowerExercises[i]);
      if (id != null) {
        await db.planDao.addExerciseToPlan(lowerId, id, i);
      }
    }

    // Full Body plan (steel blue)
    final fullId = await db.planDao.createPlan('Ganzkörper', colorHex: '7B9BC7');
    final fullExercises = [
      'bench_press',
      'barbell_row',
      'overhead_press',
      'barbell_squat',
      'deadlift',
      'barbell_curl',
      'tricep_pushdown',
    ];
    for (var i = 0; i < fullExercises.length; i++) {
      final id = await exerciseId(fullExercises[i]);
      if (id != null) {
        await db.planDao.addExerciseToPlan(fullId, id, i);
      }
    }
  }
}
