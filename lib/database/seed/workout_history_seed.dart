import 'package:drift/drift.dart';

import '../app_database.dart';

/// One-time seed of historical workout data.
/// Checks if already seeded via settings key 'history_seeded'.
class WorkoutHistorySeed {
  static Future<void> seed(AppDatabase db) async {
    final alreadySeeded = await db.settingsDao.getValue('history_seeded');
    if (alreadySeeded == 'true') return;

    // --- Exercise name → ID mapping ---
    final allExercises = await db.exerciseDao.getAll();
    final exerciseByKey = {for (final e in allExercises) e.nameKey: e.id};

    // Create missing exercises that don't exist in seed data
    Future<int> ensureExercise(String name, String nameKey, String muscle,
        String category) async {
      if (exerciseByKey.containsKey(nameKey)) return exerciseByKey[nameKey]!;
      final id = await db.exerciseDao.insertExercise(ExercisesCompanion.insert(
        name: name,
        nameKey: nameKey,
        primaryMuscleGroup: muscle,
        category: category,
      ));
      exerciseByKey[nameKey] = id;
      return id;
    }

    // Ensure all exercises exist
    final inclineBench =
        await ensureExercise('Schrägbankdrücken', 'incline_dumbbell_press', 'chest', 'compound');
    final chestPress = exerciseByKey['machine_chest_press']!;
    final flys = exerciseByKey['cable_fly']!;
    final latPulldown = exerciseByKey['lat_pulldown']!;
    final barbellRow = exerciseByKey['barbell_row']!;
    final seatedRow = exerciseByKey['seated_cable_row']!;
    final legPress = exerciseByKey['leg_press']!;
    final bulgarianSplit =
        await ensureExercise('Bulgarian Split Squat', 'bulgarian_split_squat', 'quadriceps', 'compound');
    final legExtension = exerciseByKey['leg_extension']!;
    final legCurl = exerciseByKey['leg_curl']!;
    final lateralRaise = exerciseByKey['lateral_raise']!;
    final reverseFlys =
        await ensureExercise('Reverse Flys', 'reverse_flys', 'shoulders', 'isolation');
    final bicepCurl = exerciseByKey['barbell_curl']!;
    final tricepPush = exerciseByKey['tricep_pushdown']!;
    final abCrunch = exerciseByKey['cable_crunch']!;
    final backExtension =
        await ensureExercise('Rückenstrecker', 'back_extension', 'back', 'isolation');

    // --- Create Training Plan "Training" ---
    // Exercise → target sets (from the spreadsheet "Sätze" column)
    final planExercises = <(int exerciseId, int targetSets)>[
      (inclineBench, 2),
      (chestPress, 1),
      (flys, 1),
      (latPulldown, 2),
      (barbellRow, 2),
      (seatedRow, 1),
      (legPress, 2),
      (bulgarianSplit, 2),
      (legExtension, 1),
      (legCurl, 2),
      (lateralRaise, 2),
      (reverseFlys, 2),
      (bicepCurl, 2),
      (tricepPush, 2),
      (abCrunch, 2),
      (backExtension, 1),
    ];

    final planId = await db.planDao.createPlan('Training', colorHex: '818CF8');
    for (var i = 0; i < planExercises.length; i++) {
      final (exId, sets) = planExercises[i];
      await db.planDao.addExerciseToPlan(planId, exId, i, targetSets: sets);
    }

    // --- Workout sessions ---
    // Format: (date, exercises with sets)
    // Each set: (weight, reps)

    final sessions = <_Session>[
      // 24.02.2026
      _Session(DateTime(2026, 2, 24), 3600, [
        _Ex(inclineBench, [_S(12.5, 12)]),
        _Ex(chestPress, [_S(35, 12)]),
        _Ex(flys, [_S(12, 13)]),
        _Ex(latPulldown, [_S(50, 12)]),
        _Ex(barbellRow, [_S(52, 12)]),
        _Ex(seatedRow, [_S(57, 12)]),
        _Ex(legPress, [_S(120, 12)]),
        _Ex(bulgarianSplit, [_S(6, 12)]),
        _Ex(legExtension, [_S(68, 12)]),
        _Ex(legCurl, [_S(65, 12)]),
        _Ex(lateralRaise, [_S(4, 12)]),
        _Ex(reverseFlys, [_S(42, 12)]),
        _Ex(bicepCurl, [_S(20, 12)]),
        _Ex(tricepPush, [_S(20, 12)]),
        _Ex(backExtension, [_S(10, 12)]),
      ]),
      // 26.02.2026
      _Session(DateTime(2026, 2, 26), 3900, [
        _Ex(inclineBench, [_S(12.5, 9), _S(10, 7)]),
        _Ex(chestPress, [_S(35, 12)]),
        _Ex(flys, [_S(12, 13)]),
        _Ex(latPulldown, [_S(56, 12), _S(54, 10)]),
        _Ex(seatedRow, [_S(59, 12), _S(59, 12)]),
        _Ex(lateralRaise, [_S(4, 12)]),
        _Ex(reverseFlys, [_S(50, 10), _S(50, 6)]),
        _Ex(bicepCurl, [_S(20, 12), _S(25, 8)]),
        _Ex(tricepPush, [_S(20, 12)]),
        _Ex(backExtension, [_S(10, 12)]),
      ]),
      // 28.02.2026
      _Session(DateTime(2026, 2, 28), 4200, [
        _Ex(inclineBench, [_S(12.5, 8), _S(12.5, 9)]),
        _Ex(chestPress, [_S(37.5, 10)]),
        _Ex(flys, [_S(14, 10)]),
        _Ex(latPulldown, [_S(57, 12), _S(57, 10)]),
        _Ex(barbellRow, [_S(57, 12)]),
        _Ex(seatedRow, [_S(57, 12)]),
        _Ex(legPress, [_S(120, 12)]),
        _Ex(bulgarianSplit, [_S(6, 12)]),
        _Ex(legExtension, [_S(70, 12)]),
        _Ex(legCurl, [_S(70, 12)]),
        _Ex(lateralRaise, [_S(4, 12)]),
        _Ex(reverseFlys, [_S(50, 12), _S(50, 10)]),
        _Ex(bicepCurl, [_S(30, 8), _S(30, 7)]),
        _Ex(tricepPush, [_S(21.25, 12)]),
        _Ex(backExtension, [_S(10, 12)]),
      ]),
      // 03.03.2026
      _Session(DateTime(2026, 3, 3), 3800, [
        _Ex(inclineBench, [_S(12.5, 10), _S(12.5, 9)]),
        _Ex(chestPress, [_S(37.5, 12)]),
        _Ex(flys, [_S(14, 10)]),
        _Ex(latPulldown, [_S(57, 10)]),
        _Ex(barbellRow, [_S(57, 12), _S(57, 10)]),
        _Ex(seatedRow, [_S(57, 12)]),
        _Ex(reverseFlys, [_S(50, 12), _S(50, 12)]),
        _Ex(bicepCurl, [_S(10, 8)]),
        _Ex(tricepPush, [_S(21.5, 12)]),
      ]),
      // 05.03.2026
      _Session(DateTime(2026, 3, 5), 3600, [
        _Ex(chestPress, [_S(35, 12)]),
        _Ex(flys, [_S(14, 12)]),
        _Ex(latPulldown, [_S(57, 12), _S(47, 12)]),
        _Ex(barbellRow, [_S(57, 12)]),
        _Ex(seatedRow, [_S(57, 12)]),
        _Ex(lateralRaise, [_S(6, 12)]),
        _Ex(reverseFlys, [_S(50, 12), _S(50, 12)]),
        _Ex(bicepCurl, [_S(10, 9)]),
        _Ex(tricepPush, [_S(21.5, 12)]),
        _Ex(abCrunch, [_S(0, 12), _S(0, 12)]),
      ]),
      // 09.03.2026
      _Session(DateTime(2026, 3, 9), 3500, [
        _Ex(inclineBench, [_S(12.5, 8), _S(12.5, 8)]),
        _Ex(chestPress, [_S(35, 13)]),
        _Ex(flys, [_S(14, 13)]),
        _Ex(latPulldown, [_S(57, 12), _S(57, 10)]),
        _Ex(barbellRow, [_S(48, 10), _S(48, 12)]),
        _Ex(seatedRow, [_S(57, 12)]),
        _Ex(reverseFlys, [_S(50, 8), _S(50, 8)]),
        _Ex(bicepCurl, [_S(8, 5)]),
        _Ex(abCrunch, [_S(0, 12), _S(0, 12)]),
        _Ex(backExtension, [_S(0, 12)]),
      ]),
      // 12.03.2026
      _Session(DateTime(2026, 3, 12), 3700, [
        _Ex(inclineBench, [_S(20, 10)]),
        _Ex(chestPress, [_S(40, 12)]),
        _Ex(flys, [_S(14, 10)]),
        _Ex(latPulldown, [_S(57, 10), _S(57, 10)]),
        _Ex(barbellRow, [_S(57, 8), _S(57, 8)]),
        _Ex(seatedRow, [_S(57, 12)]),
        _Ex(reverseFlys, [_S(50, 10), _S(50, 8)]),
      ]),
      // 14.03.2026
      _Session(DateTime(2026, 3, 14), 4000, [
        _Ex(inclineBench, [_S(12.5, 8), _S(12.5, 11)]),
        _Ex(chestPress, [_S(44, 12), _S(45, 12)]),
        _Ex(flys, [_S(14, 12)]),
        _Ex(latPulldown, [_S(52, 10)]),
        _Ex(barbellRow, [_S(54, 8), _S(52, 10)]),
        _Ex(seatedRow, [_S(61, 10)]),
        _Ex(reverseFlys, [_S(52.5, 8), _S(52.5, 6)]),
      ]),
    ];

    // --- Insert all sessions ---
    for (final session in sessions) {
      final startedAt = session.date.add(const Duration(hours: 17));
      final durationSec = session.durationSeconds;
      final completedAt = startedAt.add(Duration(seconds: durationSec));

      final workoutId =
          await db.into(db.workouts).insert(WorkoutsCompanion.insert(
        startedAt: startedAt,
        name: const Value('Training'),
        planId: Value(planId),
        completedAt: Value(completedAt),
        durationSeconds: Value(durationSec),
        isActive: const Value(false),
      ));

      for (var exIdx = 0; exIdx < session.exercises.length; exIdx++) {
        final ex = session.exercises[exIdx];
        final weId = await db.into(db.workoutExercises)
            .insert(WorkoutExercisesCompanion.insert(
          workoutId: workoutId,
          exerciseId: ex.exerciseId,
          sortOrder: exIdx,
        ));

        for (var setIdx = 0; setIdx < ex.sets.length; setIdx++) {
          final s = ex.sets[setIdx];
          await db.into(db.workoutSets).insert(WorkoutSetsCompanion.insert(
            workoutExerciseId: weId,
            setNumber: setIdx + 1,
            weight: Value(s.weight),
            reps: Value(s.reps),
            isCompleted: const Value(true),
            completedAt: Value(completedAt),
          ));
        }
      }
    }

    await db.settingsDao.setValue('history_seeded', 'true');
  }
}

class _Session {
  final DateTime date;
  final int durationSeconds;
  final List<_Ex> exercises;
  const _Session(this.date, this.durationSeconds, this.exercises);
}

class _Ex {
  final int exerciseId;
  final List<_S> sets;
  const _Ex(this.exerciseId, this.sets);
}

class _S {
  final double weight;
  final int reps;
  const _S(this.weight, this.reps);
}
