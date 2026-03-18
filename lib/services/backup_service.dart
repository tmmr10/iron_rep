import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';

class BackupData {
  final int version;
  final String exportedAt;
  final List<Map<String, dynamic>> exercises;
  final List<Map<String, dynamic>> plans;
  final List<Map<String, dynamic>> workouts;
  final List<Map<String, dynamic>> personalRecords;

  const BackupData({
    required this.version,
    required this.exportedAt,
    required this.exercises,
    required this.plans,
    required this.workouts,
    required this.personalRecords,
  });

  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      version: json['v'] as int,
      exportedAt: json['exportedAt'] as String,
      exercises: (json['exercises'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      plans: (json['plans'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      workouts: (json['workouts'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      personalRecords: (json['personalRecords'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
    );
  }
}

class BackupPreview {
  final int exerciseCount;
  final int planCount;
  final int workoutCount;
  final int personalRecordCount;
  final String exportedAt;

  const BackupPreview({
    required this.exerciseCount,
    required this.planCount,
    required this.workoutCount,
    required this.personalRecordCount,
    required this.exportedAt,
  });
}

class ImportResult {
  final int exercisesImported;
  final int plansImported;
  final int workoutsImported;
  final int personalRecordsImported;

  const ImportResult({
    required this.exercisesImported,
    required this.plansImported,
    required this.workoutsImported,
    required this.personalRecordsImported,
  });
}

class BackupService {
  static Future<Map<String, dynamic>> exportToJson(
    AppDatabase db, {
    bool exportExercises = true,
    bool exportPlans = true,
    bool exportWorkouts = true,
    bool exportRecords = true,
  }) async {
    final exercises = exportExercises ? await _exportExercises(db) : <Map<String, dynamic>>[];
    final plans = exportPlans ? await _exportPlans(db) : <Map<String, dynamic>>[];
    final workouts = exportWorkouts ? await _exportWorkouts(db) : <Map<String, dynamic>>[];
    final personalRecords = exportRecords ? await _exportPersonalRecords(db) : <Map<String, dynamic>>[];

    return {
      'v': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'exercises': exercises,
      'plans': plans,
      'workouts': workouts,
      'personalRecords': personalRecords,
    };
  }

  static Future<File> exportToFile(
    AppDatabase db, {
    bool exportExercises = true,
    bool exportPlans = true,
    bool exportWorkouts = true,
    bool exportRecords = true,
  }) async {
    final json = await exportToJson(
      db,
      exportExercises: exportExercises,
      exportPlans: exportPlans,
      exportWorkouts: exportWorkouts,
      exportRecords: exportRecords,
    );
    final jsonStr = jsonEncode(json);
    final compressed = gzip.encode(utf8.encode(jsonStr));

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '-')
        .split('.')
        .first;
    final file = File('${tempDir.path}/IronRep-Backup-$timestamp.ironrep');
    await file.writeAsBytes(compressed);
    return file;
  }

  /// Returns counts of exportable data for the preview screen.
  static Future<BackupPreview> previewExport(AppDatabase db) async {
    final exercises = await db.exerciseDao.getAll();
    final customExercises = exercises.where((e) => e.isCustom).length;
    final plans = await db.planDao.getAllPlans();
    final workouts = await (db.select(db.workouts)
          ..where((t) => t.completedAt.isNotNull()))
        .get();
    final records = await db.select(db.personalRecords).get();

    return BackupPreview(
      exerciseCount: customExercises,
      planCount: plans.length,
      workoutCount: workouts.length,
      personalRecordCount: records.length,
      exportedAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  static BackupData? parseBackup(File file) {
    try {
      final bytes = file.readAsBytesSync();
      final jsonStr = utf8.decode(gzip.decode(bytes));
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return BackupData.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static BackupPreview previewBackup(BackupData data) {
    return BackupPreview(
      exerciseCount: data.exercises.length,
      planCount: data.plans.length,
      workoutCount: data.workouts.length,
      personalRecordCount: data.personalRecords.length,
      exportedAt: data.exportedAt,
    );
  }

  static Future<ImportResult> importBackup(
    AppDatabase db,
    BackupData data, {
    bool importExercises = true,
    bool importPlans = true,
    bool importWorkouts = true,
    bool importRecords = true,
  }) async {
    int exercisesImported = 0;
    int plansImported = 0;
    int workoutsImported = 0;
    int personalRecordsImported = 0;

    // Step 1: Import custom exercises
    for (final exJson in data.exercises) {
      if (!importExercises) break;
      final nameKey = exJson['nameKey'] as String;
      final isCustom = exJson['isCustom'] as bool? ?? false;
      if (!isCustom) continue;

      final existing = await db.exerciseDao.getByNameKey(nameKey);
      if (existing != null) continue;

      await db.exerciseDao.insertExercise(
        ExercisesCompanion.insert(
          name: exJson['name'] as String,
          nameKey: nameKey,
          primaryMuscleGroup: exJson['primaryMuscleGroup'] as String? ?? 'chest',
          category: exJson['category'] as String? ?? 'compound',
          trackWeight: Value(exJson['trackWeight'] as bool? ?? true),
          isCustom: const Value(true),
          createdAt: Value(DateTime.now()),
        ),
      );

      // Import equipment if present
      final equipment = exJson['equipment'] as List?;
      if (equipment != null) {
        final exercise = await db.exerciseDao.getByNameKey(nameKey);
        if (exercise != null) {
          for (final eq in equipment) {
            await db.exerciseDao.insertEquipment(
              ExerciseEquipmentCompanion.insert(
                exerciseId: exercise.id,
                equipmentType: eq as String,
              ),
            );
          }
        }
      }

      exercisesImported++;
    }

    // Step 2: Import plans
    if (importPlans) {
      for (final planJson in data.plans) {
        final planName = planJson['name'] as String;

        // Check if plan with same name exists
        final existingPlans = await db.planDao.getAllPlans();
        final exists = existingPlans.any((p) => p.name == planName);
        if (exists) continue;

        final colorHex = planJson['colorHex'] as String?;
        final planId = await db.planDao.createPlan(planName, colorHex: colorHex);

        final planExercises = planJson['exercises'] as List? ?? [];
        for (var i = 0; i < planExercises.length; i++) {
          final peJson = planExercises[i] as Map<String, dynamic>;
          final nameKey = peJson['nameKey'] as String;
          final exercise = await db.exerciseDao.getByNameKey(nameKey);
          if (exercise == null) continue;

          await db.planDao.addExerciseToPlan(
            planId,
            exercise.id,
            peJson['sortOrder'] as int? ?? i,
            targetSets: peJson['targetSets'] as int? ?? 3,
          );
        }

        plansImported++;
      }
    }

    // Step 3: Import workouts
    if (importWorkouts) {
      for (final wJson in data.workouts) {
        final startedAtStr = wJson['startedAt'] as String;
        final startedAt = DateTime.parse(startedAtStr);

        // Duplicate check: same startedAt timestamp
        final existingWorkouts = await (db.select(db.workouts)
              ..where((t) => t.startedAt.equals(startedAt)))
            .get();
        if (existingWorkouts.isNotEmpty) continue;

        // Resolve planId by name
        int? planId;
        final planName = wJson['planName'] as String?;
        if (planName != null) {
          final allPlans = await db.planDao.getAllPlans();
          final matchingPlan = allPlans.where((p) => p.name == planName);
          if (matchingPlan.isNotEmpty) planId = matchingPlan.first.id;
        }

        final completedAtStr = wJson['completedAt'] as String?;
        final completedAt =
            completedAtStr != null ? DateTime.parse(completedAtStr) : null;

        final workoutId = await db.into(db.workouts).insert(
              WorkoutsCompanion.insert(
                startedAt: startedAt,
                name: Value(wJson['name'] as String?),
                planId: Value(planId),
                completedAt: Value(completedAt),
                durationSeconds:
                    Value(wJson['durationSeconds'] as int?),
                isActive: const Value(false),
              ),
            );

        final wExercises = wJson['exercises'] as List? ?? [];
        for (var i = 0; i < wExercises.length; i++) {
          final weJson = wExercises[i] as Map<String, dynamic>;
          final nameKey = weJson['nameKey'] as String;
          final exercise = await db.exerciseDao.getByNameKey(nameKey);
          if (exercise == null) continue;

          final weId = await db.into(db.workoutExercises).insert(
                WorkoutExercisesCompanion.insert(
                  workoutId: workoutId,
                  exerciseId: exercise.id,
                  sortOrder: weJson['sortOrder'] as int? ?? i,
                ),
              );

          final sets = weJson['sets'] as List? ?? [];
          for (final setJson in sets) {
            final sMap = setJson as Map<String, dynamic>;
            final completedAtSet = sMap['completedAt'] as String?;
            await db.into(db.workoutSets).insert(
                  WorkoutSetsCompanion.insert(
                    workoutExerciseId: weId,
                    setNumber: sMap['setNumber'] as int,
                    weight: Value((sMap['weight'] as num?)?.toDouble()),
                    reps: Value(sMap['reps'] as int?),
                    durationSeconds: Value(sMap['durationSeconds'] as int?),
                    setType: Value(sMap['setType'] as String? ?? 'working'),
                    isCompleted:
                        Value(sMap['isCompleted'] as bool? ?? false),
                    completedAt: Value(completedAtSet != null
                        ? DateTime.parse(completedAtSet)
                        : null),
                  ),
                );
          }
        }

        workoutsImported++;
      }
    }

    // Step 4: Import personal records (only if better than existing)
    if (!importRecords) {
      return ImportResult(
        exercisesImported: exercisesImported,
        plansImported: plansImported,
        workoutsImported: workoutsImported,
        personalRecordsImported: personalRecordsImported,
      );
    }
    for (final prJson in data.personalRecords) {
      final nameKey = prJson['nameKey'] as String;
      final exercise = await db.exerciseDao.getByNameKey(nameKey);
      if (exercise == null) continue;

      final recordType = prJson['recordType'] as String;
      final value = (prJson['value'] as num).toDouble();

      final existing = await (db.select(db.personalRecords)
            ..where((t) =>
                t.exerciseId.equals(exercise.id) &
                t.recordType.equals(recordType)))
          .getSingleOrNull();

      if (existing == null || value > existing.value) {
        // We need a workout reference — use the most recent workout for this exercise
        final recentWe = await (db.select(db.workoutExercises)
              ..where((t) => t.exerciseId.equals(exercise.id))
              ..orderBy([(t) => OrderingTerm.desc(t.id)])
              ..limit(1))
            .getSingleOrNull();
        if (recentWe == null) continue;

        final achievedAtStr = prJson['achievedAt'] as String;
        final achievedAt = DateTime.parse(achievedAtStr);

        if (existing == null) {
          await db.into(db.personalRecords).insert(
                PersonalRecordsCompanion.insert(
                  exerciseId: exercise.id,
                  recordType: recordType,
                  value: value,
                  achievedAt: achievedAt,
                  workoutId: recentWe.workoutId,
                ),
              );
        } else {
          await (db.update(db.personalRecords)
                ..where((t) => t.id.equals(existing.id)))
              .write(PersonalRecordsCompanion(
            value: Value(value),
            achievedAt: Value(achievedAt),
            workoutId: Value(recentWe.workoutId),
          ));
        }
        personalRecordsImported++;
      }
    }

    return ImportResult(
      exercisesImported: exercisesImported,
      plansImported: plansImported,
      workoutsImported: workoutsImported,
      personalRecordsImported: personalRecordsImported,
    );
  }

  // --- Private export helpers ---

  static Future<List<Map<String, dynamic>>> _exportExercises(
      AppDatabase db) async {
    final exercises = await db.exerciseDao.getAll();
    final result = <Map<String, dynamic>>[];

    for (final ex in exercises) {
      final equipment = await db.exerciseDao.getEquipmentForExercise(ex.id);
      result.add({
        'nameKey': ex.nameKey,
        'name': ex.name,
        'primaryMuscleGroup': ex.primaryMuscleGroup,
        'category': ex.category,
        'trackWeight': ex.trackWeight,
        'isCustom': ex.isCustom,
        'equipment': equipment.map((e) => e.equipmentType).toList(),
      });
    }

    return result;
  }

  static Future<List<Map<String, dynamic>>> _exportPlans(
      AppDatabase db) async {
    final plans = await db.planDao.getAllPlans();
    final result = <Map<String, dynamic>>[];

    for (final plan in plans) {
      final planExercises = await db.planDao.getPlanExercises(plan.id);
      final exerciseList = <Map<String, dynamic>>[];

      for (final pe in planExercises) {
        final nameKey = await _getNameKeyForId(db, pe.exerciseId);
        exerciseList.add({
          'nameKey': nameKey,
          'sortOrder': pe.sortOrder,
          'targetSets': pe.targetSets,
        });
      }

      result.add({
        'name': plan.name,
        'colorHex': plan.colorHex,
        'exercises': exerciseList,
      });
    }

    return result;
  }

  static Future<List<Map<String, dynamic>>> _exportWorkouts(
      AppDatabase db) async {
    // Only completed workouts
    final workouts = await (db.select(db.workouts)
          ..where((t) => t.completedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();

    final result = <Map<String, dynamic>>[];

    for (final w in workouts) {
      // Resolve plan name
      String? planName;
      if (w.planId != null) {
        try {
          final plan = await db.planDao.getPlan(w.planId!);
          planName = plan.name;
        } catch (_) {}
      }

      final wExercises = await db.workoutDao.getWorkoutExercises(w.id);
      final exerciseList = <Map<String, dynamic>>[];

      for (final we in wExercises) {
        final nameKey = await _getNameKeyForId(db, we.exerciseId);
        final sets = await db.workoutDao.getSetsForWorkoutExercise(we.id);

        exerciseList.add({
          'nameKey': nameKey,
          'sortOrder': we.sortOrder,
          'sets': sets
              .map((s) => {
                    'setNumber': s.setNumber,
                    'weight': s.weight,
                    'reps': s.reps,
                    if (s.durationSeconds != null)
                      'durationSeconds': s.durationSeconds,
                    'setType': s.setType,
                    'isCompleted': s.isCompleted,
                    if (s.completedAt != null)
                      'completedAt': s.completedAt!.toUtc().toIso8601String(),
                  })
              .toList(),
        });
      }

      result.add({
        'name': w.name,
        'planName': planName,
        'startedAt': w.startedAt.toUtc().toIso8601String(),
        if (w.completedAt != null)
          'completedAt': w.completedAt!.toUtc().toIso8601String(),
        'durationSeconds': w.durationSeconds,
        'exercises': exerciseList,
      });
    }

    return result;
  }

  static Future<List<Map<String, dynamic>>> _exportPersonalRecords(
      AppDatabase db) async {
    final records = await db.select(db.personalRecords).get();
    final result = <Map<String, dynamic>>[];

    for (final pr in records) {
      final nameKey = await _getNameKeyForId(db, pr.exerciseId);
      result.add({
        'nameKey': nameKey,
        'recordType': pr.recordType,
        'value': pr.value,
        'achievedAt': pr.achievedAt.toUtc().toIso8601String(),
      });
    }

    return result;
  }

  static Future<String> _getNameKeyForId(AppDatabase db, int exerciseId) async {
    final exercise = await (db.select(db.exercises)
          ..where((t) => t.id.equals(exerciseId)))
        .getSingleOrNull();
    return exercise?.nameKey ?? 'unknown_$exerciseId';
  }
}
