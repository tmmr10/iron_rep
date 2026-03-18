import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

class ShareableExercise {
  final String nameKey;
  final int targetSets;
  final bool isCustom;
  final String? customName;
  final String? muscleGroup;
  final String? category;

  const ShareableExercise({
    required this.nameKey,
    required this.targetSets,
    this.isCustom = false,
    this.customName,
    this.muscleGroup,
    this.category,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'k': nameKey,
      's': targetSets,
    };
    if (isCustom) {
      if (customName != null) map['cn'] = customName;
      if (muscleGroup != null) map['mg'] = muscleGroup;
      if (category != null) map['cat'] = category;
    }
    return map;
  }

  factory ShareableExercise.fromJson(Map<String, dynamic> json) {
    return ShareableExercise(
      nameKey: json['k'] as String,
      targetSets: json['s'] as int,
      isCustom: json.containsKey('cn'),
      customName: json['cn'] as String?,
      muscleGroup: json['mg'] as String?,
      category: json['cat'] as String?,
    );
  }
}

class SharedPlan {
  final int version;
  final String name;
  final List<ShareableExercise> exercises;

  const SharedPlan({
    required this.version,
    required this.name,
    required this.exercises,
  });

  factory SharedPlan.fromJson(Map<String, dynamic> json) {
    return SharedPlan(
      version: json['v'] as int,
      name: json['n'] as String,
      exercises: (json['e'] as List)
          .map((e) => ShareableExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'v': version,
        'n': name,
        'e': exercises.map((e) => e.toJson()).toList(),
      };
}

enum ExerciseMatchStatus { found, createdCustom, unknown }

class MatchedExercise {
  final ShareableExercise source;
  final ExerciseMatchStatus status;
  final String displayName;

  const MatchedExercise({
    required this.source,
    required this.status,
    required this.displayName,
  });
}

/// Converts a snake_case nameKey to Title Case display name.
/// e.g. `bench_press` → `Bench Press`
String _nameKeyToDisplayName(String nameKey) {
  return nameKey
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class PlanSharingService {
  static String encodePlan(String name, List<ShareableExercise> exercises) {
    final plan = SharedPlan(version: 1, name: name, exercises: exercises);
    final json = jsonEncode(plan.toJson());
    final compressed = gzip.encode(utf8.encode(json));
    return base64Url.encode(compressed);
  }

  static SharedPlan? decodePlan(String encoded) {
    try {
      final compressed = base64Url.decode(encoded);
      final json = utf8.decode(gzip.decode(compressed));
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SharedPlan.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  static String buildShareUrl(String encoded) =>
      'https://tmmr10.github.io/ironrep-share/#$encoded';

  static Future<List<MatchedExercise>> matchExercises(
      AppDatabase db, SharedPlan plan) async {
    final results = <MatchedExercise>[];
    for (final ex in plan.exercises) {
      final existing = await db.exerciseDao.getByNameKey(ex.nameKey);
      if (existing != null) {
        results.add(MatchedExercise(
          source: ex,
          status: ExerciseMatchStatus.found,
          displayName: existing.name,
        ));
      } else if (ex.isCustom && ex.customName != null) {
        results.add(MatchedExercise(
          source: ex,
          status: ExerciseMatchStatus.createdCustom,
          displayName: ex.customName!,
        ));
      } else {
        final generatedName = _nameKeyToDisplayName(ex.nameKey);
        results.add(MatchedExercise(
          source: ex,
          status: ExerciseMatchStatus.createdCustom,
          displayName: generatedName,
        ));
      }
    }
    return results;
  }

  static Future<int> importPlan(AppDatabase db, SharedPlan plan) async {
    final planId = await db.planDao.createPlan(plan.name);

    for (var i = 0; i < plan.exercises.length; i++) {
      final ex = plan.exercises[i];
      var existing = await db.exerciseDao.getByNameKey(ex.nameKey);

      if (existing == null && ex.isCustom && ex.customName != null) {
        await db.exerciseDao.insertExercise(
          ExercisesCompanion.insert(
            name: ex.customName!,
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

      if (existing == null) {
        // Create as custom exercise with name derived from nameKey
        final generatedName = _nameKeyToDisplayName(ex.nameKey);
        await db.exerciseDao.insertExercise(
          ExercisesCompanion.insert(
            name: generatedName,
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

      await db.planDao.addExerciseToPlan(
        planId,
        existing.id,
        i,
        targetSets: ex.targetSets,
      );
    }

    return planId;
  }
}
