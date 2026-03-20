import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'plan_sharing_service.dart';

class ShareableSet {
  final double? weight;
  final int? reps;
  final String? setType;
  final int? durationSecs;

  const ShareableSet({this.weight, this.reps, this.setType, this.durationSecs});

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (weight != null) map['w'] = weight;
    if (reps != null) map['r'] = reps;
    if (setType != null && setType != 'working') map['t'] = setType;
    if (durationSecs != null) map['dr'] = durationSecs;
    return map;
  }

  factory ShareableSet.fromJson(Map<String, dynamic> json) {
    return ShareableSet(
      weight: (json['w'] as num?)?.toDouble(),
      reps: json['r'] as int?,
      setType: json['t'] as String?,
      durationSecs: json['dr'] as int?,
    );
  }
}

class ShareableWorkoutExercise {
  final String nameKey;
  final List<ShareableSet> sets;
  final String? customName;
  final String? muscleGroup;
  final String? category;

  const ShareableWorkoutExercise({
    required this.nameKey,
    required this.sets,
    this.customName,
    this.muscleGroup,
    this.category,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'k': nameKey,
      's': sets.map((s) => s.toJson()).toList(),
    };
    if (customName != null) map['cn'] = customName;
    if (muscleGroup != null) map['mg'] = muscleGroup;
    if (category != null) map['cat'] = category;
    return map;
  }

  factory ShareableWorkoutExercise.fromJson(Map<String, dynamic> json) {
    return ShareableWorkoutExercise(
      nameKey: json['k'] as String,
      sets: (json['s'] as List)
          .map((s) => ShareableSet.fromJson(s as Map<String, dynamic>))
          .toList(),
      customName: json['cn'] as String?,
      muscleGroup: json['mg'] as String?,
      category: json['cat'] as String?,
    );
  }
}

class SharedWorkout {
  final int version;
  final String name;
  final int? durationSeconds;
  final List<ShareableWorkoutExercise> exercises;

  const SharedWorkout({
    required this.version,
    required this.name,
    this.durationSeconds,
    required this.exercises,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'v': version,
      'n': name,
      'x': exercises.map((e) => e.toJson()).toList(),
    };
    if (durationSeconds != null) map['d'] = durationSeconds;
    return map;
  }

  factory SharedWorkout.fromJson(Map<String, dynamic> json) {
    return SharedWorkout(
      version: json['v'] as int,
      name: json['n'] as String,
      durationSeconds: json['d'] as int?,
      exercises: (json['x'] as List)
          .map((e) =>
              ShareableWorkoutExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MatchedWorkoutExercise {
  final ShareableWorkoutExercise source;
  final ExerciseMatchStatus status;
  final String displayName;

  const MatchedWorkoutExercise({
    required this.source,
    required this.status,
    required this.displayName,
  });
}

class WorkoutSharingService {
  static String encodeWorkout(SharedWorkout workout) {
    final json = jsonEncode(workout.toJson());
    final compressed = gzip.encode(utf8.encode(json));
    return base64Url.encode(compressed);
  }

  static SharedWorkout? decodeWorkout(String encoded) {
    try {
      final compressed = base64Url.decode(encoded);
      final json = utf8.decode(gzip.decode(compressed));
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SharedWorkout.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static String buildShareUrl(String encoded) =>
      'https://tmmr10.github.io/ironrep-share/#w:$encoded';

  static Future<List<MatchedWorkoutExercise>> matchExercises(
      AppDatabase db, SharedWorkout workout) async {
    final results = <MatchedWorkoutExercise>[];
    for (final ex in workout.exercises) {
      final existing = await db.exerciseDao.getByNameKey(ex.nameKey);
      if (existing != null) {
        results.add(MatchedWorkoutExercise(
          source: ex,
          status: ExerciseMatchStatus.found,
          displayName: existing.name,
        ));
      } else if (ex.customName != null) {
        results.add(MatchedWorkoutExercise(
          source: ex,
          status: ExerciseMatchStatus.createdCustom,
          displayName: ex.customName!,
        ));
      } else {
        results.add(MatchedWorkoutExercise(
          source: ex,
          status: ExerciseMatchStatus.createdCustom,
          displayName: nameKeyToDisplayName(ex.nameKey),
        ));
      }
    }
    return results;
  }

  static Future<int> importWorkout(AppDatabase db, SharedWorkout workout) async {
    // Create completed workout entry
    final now = DateTime.now();
    final workoutId = await db.into(db.workouts).insert(
      WorkoutsCompanion.insert(
        startedAt: now,
        name: Value(workout.name),
        completedAt: Value(now),
        durationSeconds: Value(workout.durationSeconds),
        isActive: const Value(false),
      ),
    );

    for (var i = 0; i < workout.exercises.length; i++) {
      final ex = workout.exercises[i];

      // Resolve or create exercise
      var existing = await db.exerciseDao.getByNameKey(ex.nameKey);
      if (existing == null) {
        final name = ex.customName ?? nameKeyToDisplayName(ex.nameKey);
        await db.exerciseDao.insertExercise(
          ExercisesCompanion.insert(
            name: name,
            nameKey: ex.nameKey,
            primaryMuscleGroup: ex.muscleGroup ?? 'chest',
            category: ex.category ?? 'compound',
            isCustom: const Value(true),
            createdAt: Value(DateTime.now()),
          ),
        );
        existing = await db.exerciseDao.getByNameKey(ex.nameKey);
        if (existing == null) continue;
      }

      // Add exercise to workout
      final weId =
          await db.workoutDao.addExerciseToWorkout(workoutId, existing.id);

      // Add sets
      for (var j = 0; j < ex.sets.length; j++) {
        final s = ex.sets[j];
        final setId = await db.workoutDao.addSet(weId);
        await db.workoutDao.updateSet(
          setId,
          weight: s.weight,
          reps: s.reps,
          setType: s.setType,
        );
        await db.workoutDao.completeSet(setId);
      }
    }

    // Do NOT recalculate personal records for imported workouts
    return workoutId;
  }
}
