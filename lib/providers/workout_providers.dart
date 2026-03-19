import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/app_database.dart';
import '../models/workout_history_item.dart';
import '../models/workout_summary.dart';
import '../services/timer_service.dart';
import 'database_provider.dart';
import 'timer_providers.dart';

// Notification info for background workout notification
class WorkoutNotificationInfo {
  final String? exerciseName;
  final int currentSetIndex;
  final int totalSets;
  final String? nextExerciseName;

  const WorkoutNotificationInfo({
    this.exerciseName,
    this.currentSetIndex = 0,
    this.totalSets = 0,
    this.nextExerciseName,
  });
}

final workoutNotificationInfoProvider = StateProvider<WorkoutNotificationInfo>(
  (ref) => const WorkoutNotificationInfo(),
);

// Active workout state
class ActiveWorkoutState {
  final int? workoutId;
  final int? planId;
  final String? planName;
  final bool isActive;
  final bool isPaused;
  final Duration elapsed;
  final List<int> workoutExerciseIds;

  const ActiveWorkoutState({
    this.workoutId,
    this.planId,
    this.planName,
    this.isActive = false,
    this.isPaused = false,
    this.elapsed = Duration.zero,
    this.workoutExerciseIds = const [],
    this.startedAt,
  });

  final DateTime? startedAt;

  ActiveWorkoutState copyWith({
    int? workoutId,
    int? planId,
    String? planName,
    bool? isActive,
    bool? isPaused,
    Duration? elapsed,
    List<int>? workoutExerciseIds,
    DateTime? startedAt,
  }) {
    return ActiveWorkoutState(
      workoutId: workoutId ?? this.workoutId,
      planId: planId ?? this.planId,
      planName: planName ?? this.planName,
      isActive: isActive ?? this.isActive,
      isPaused: isPaused ?? this.isPaused,
      elapsed: elapsed ?? this.elapsed,
      workoutExerciseIds: workoutExerciseIds ?? this.workoutExerciseIds,
      startedAt: startedAt ?? this.startedAt,
    );
  }
}

/// Set to true when Live Activity is disabled and user hasn't been warned yet
final liveActivityDisabledWarningProvider = StateProvider<bool>((ref) => false);

class ActiveWorkoutNotifier extends StateNotifier<ActiveWorkoutState> {
  final AppDatabase _db;
  final Ref _ref;
  Timer? _timer;

  ActiveWorkoutNotifier(this._db, this._ref) : super(const ActiveWorkoutState()) {
    _checkForActiveWorkout();
  }

  Future<void> _checkLiveActivityPermission() async {
    if (!Platform.isIOS) return;
    final enabled = await TimerService.isLiveActivityEnabled();
    if (!enabled) {
      final prefs = await SharedPreferences.getInstance();
      final warned = prefs.getBool('liveActivityWarningShown') ?? false;
      if (!warned) {
        _ref.read(liveActivityDisabledWarningProvider.notifier).state = true;
        await prefs.setBool('liveActivityWarningShown', true);
      }
    }
  }

  Future<void> _checkForActiveWorkout() async {
    final active = await _db.workoutDao.getActiveWorkout();
    if (active != null) {
      final elapsed = DateTime.now().difference(active.startedAt);
      String? planName;
      if (active.planId != null) {
        try {
          final plan = await _db.planDao.getPlan(active.planId!);
          planName = plan.name;
        } catch (_) {}
      }
      state = ActiveWorkoutState(
        workoutId: active.id,
        planId: active.planId,
        planName: planName ?? active.name,
        isActive: true,
        elapsed: elapsed,
        startedAt: active.startedAt,
      );
      _startTimer();
      TimerService.startWorkoutActivity(
        workoutName: planName ?? active.name ?? 'Training',
        startedAtMs: active.startedAt.millisecondsSinceEpoch,
      );
      // Load current exercise info for Live Activity
      _updateLiveActivityWithCurrentExercise(active.id);
    }
  }

  Future<void> _updateLiveActivityWithCurrentExercise(int workoutId) async {
    final exercises = await _db.workoutDao.getWorkoutExercises(workoutId);
    final allExercises = await _db.exerciseDao.getAll();
    for (var i = 0; i < exercises.length; i++) {
      final we = exercises[i];
      final sets = await _db.workoutDao.getSetsForWorkoutExercise(we.id);
      final completedCount = sets.where((s) => s.isCompleted == true).length;
      if (completedCount < sets.length) {
        final exercise = allExercises.where((e) => e.id == we.exerciseId);
        final name = exercise.isNotEmpty ? exercise.first.name : null;
        String? nextName;
        for (var j = i + 1; j < exercises.length; j++) {
          final nextEx = allExercises.where((e) => e.id == exercises[j].exerciseId);
          if (nextEx.isNotEmpty) { nextName = nextEx.first.name; break; }
        }
        if (name != null) {
          TimerService.updateWorkoutActivity(
            exerciseName: name,
            nextExerciseName: nextName,
            currentSet: completedCount + 1,
            totalSets: sets.length,
          );
        }
        return;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.isActive && !state.isPaused) {
        state = state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1));
      }
    });
  }

  void togglePause() {
    final wasPaused = state.isPaused;
    state = state.copyWith(isPaused: !wasPaused);
    if (!wasPaused) {
      TimerService.pauseWorkoutActivity(elapsedSeconds: state.elapsed.inSeconds);
    } else {
      TimerService.resumeWorkoutActivity(elapsedSeconds: state.elapsed.inSeconds);
    }
  }

  Future<void> preparePlan(int planId) async {
    final plan = await _db.planDao.getPlan(planId);
    state = ActiveWorkoutState(
      planId: planId,
      planName: plan.name,
      isActive: false,
      isPaused: false,
      elapsed: Duration.zero,
    );
  }

  Future<void> startWorkout({String? name, int? planId}) async {
    String? planName = name;
    if (planId != null) {
      final plan = await _db.planDao.getPlan(planId);
      planName = plan.name;
    }
    final now = DateTime.now();
    final id = await _db.workoutDao.startWorkout(
        name: planName, planId: planId);
    state = ActiveWorkoutState(
      workoutId: id,
      planId: planId,
      planName: planName,
      isActive: true,
      elapsed: Duration.zero,
      startedAt: now,
    );
    _startTimer();
    TimerService.startWorkoutActivity(
      workoutName: planName ?? 'Training',
      startedAtMs: now.millisecondsSinceEpoch,
    );
    // Check Live Activity permission
    _checkLiveActivityPermission();

    // If starting from a plan, pre-load exercises with target sets
    if (planId != null) {
      final planExercises = await _db.planDao.getPlanExercises(planId);
      for (final pe in planExercises) {
        final weId =
            await _db.workoutDao.addExerciseToWorkout(id, pe.exerciseId);
        // Pre-create target sets
        for (var i = 0; i < pe.targetSets; i++) {
          await _db.workoutDao.addSet(weId);
        }
      }
    }
  }

  Future<void> addExercise(int exerciseId) async {
    if (state.workoutId == null) return;
    final weId = await _db.workoutDao
        .addExerciseToWorkout(state.workoutId!, exerciseId);
    // If workout is from a plan, use the plan's target sets for this exercise
    int targetSets = 1;
    if (state.planId != null) {
      final planExercises = await _db.planDao.getPlanExercises(state.planId!);
      final match = planExercises.where((pe) => pe.exerciseId == exerciseId);
      if (match.isNotEmpty) {
        targetSets = match.first.targetSets;
      }
    }
    // Default to 3 sets if not from plan
    if (targetSets <= 1 && state.planId == null) targetSets = 3;
    for (var i = 0; i < targetSets; i++) {
      await _db.workoutDao.addSet(weId);
    }
  }

  Future<void> removeExercise(int workoutExerciseId) async {
    await _db.workoutDao.removeExerciseFromWorkout(workoutExerciseId);
  }

  Future<int> addSet(int workoutExerciseId) async {
    return _db.workoutDao.addSet(workoutExerciseId);
  }

  Future<void> updateSet(int setId,
      {double? weight, int? reps, String? setType}) async {
    await _db.workoutDao.updateSet(setId,
        weight: weight, reps: reps, setType: setType);
  }

  Future<void> completeSet(int setId) async {
    await _db.workoutDao.completeSet(setId);
  }

  Future<void> uncompleteSet(int setId) async {
    await _db.workoutDao.uncompleteSet(setId);
  }

  Future<void> deleteSet(int setId) async {
    await _db.workoutDao.deleteSet(setId);
  }

  Future<WorkoutSummary?> finishWorkout() async {
    if (state.workoutId == null) return null;
    final workoutId = state.workoutId!;

    // Calculate PRs
    final workoutExercises =
        await _db.workoutDao.getWorkoutExercises(workoutId);
    int prCount = 0;
    int totalSets = 0;
    double totalVolume = 0;

    for (final we in workoutExercises) {
      final sets = await _db.workoutDao.getSetsForWorkoutExercise(we.id);
      final completedSets = sets.where((s) => s.isCompleted == true).toList();
      totalSets += completedSets.length;
      for (final s in completedSets) {
        totalVolume += (s.weight ?? 0) * (s.reps ?? 0);
      }
      await _db.workoutDao
          .updatePersonalRecords(we.exerciseId, workoutId, completedSets);
    }

    // Calculate skipped exercises if workout is plan-based
    int skippedCount = 0;
    if (state.planId != null) {
      final planExercises =
          await _db.planDao.getPlanExercises(state.planId!);
      final workoutExerciseIds =
          workoutExercises.map((we) => we.exerciseId).toSet();
      skippedCount = planExercises
          .where((pe) => !workoutExerciseIds.contains(pe.exerciseId))
          .length;
    }

    await _db.workoutDao.finishWorkout(workoutId);
    _timer?.cancel();
    _ref.read(restTimerProvider.notifier).skip();
    TimerService.dismissWorkoutNotification();
    TimerService.endWorkoutActivity();

    final workout = await (_db.select(_db.workouts)
          ..where((t) => t.id.equals(workoutId)))
        .getSingle();

    final summary = WorkoutSummary(
      workoutId: workoutId,
      name: workout.name,
      startedAt: workout.startedAt,
      completedAt: workout.completedAt,
      durationSeconds: workout.durationSeconds,
      exerciseCount: workoutExercises.length,
      totalSets: totalSets,
      totalVolume: totalVolume,
      prCount: prCount,
      skippedCount: skippedCount,
    );

    state = const ActiveWorkoutState();
    return summary;
  }

  Future<void> cancelWorkout() async {
    if (state.workoutId == null) return;
    await _db.workoutDao.cancelWorkout(state.workoutId!);
    _timer?.cancel();
    _ref.read(restTimerProvider.notifier).skip();
    TimerService.dismissWorkoutNotification();
    TimerService.endWorkoutActivity();
    state = const ActiveWorkoutState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final activeWorkoutProvider =
    StateNotifierProvider<ActiveWorkoutNotifier, ActiveWorkoutState>((ref) {
  final db = ref.watch(databaseProvider);
  return ActiveWorkoutNotifier(db, ref);
});

// Plan exercises with names (for pre-start view)
final planExerciseNamesProvider =
    FutureProvider.family<List<({String name, int targetSets})>, int>(
        (ref, planId) async {
  final db = ref.watch(databaseProvider);
  final planExercises = await db.planDao.getPlanExercises(planId);
  final allExercises = await db.exerciseDao.getAll();
  return planExercises.map((pe) {
    final ex = allExercises.firstWhere((e) => e.id == pe.exerciseId);
    return (name: ex.name, targetSets: pe.targetSets);
  }).toList();
});

// Workout exercises stream
final workoutExercisesProvider =
    StreamProvider.family<List<WorkoutExercise>, int>((ref, workoutId) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.watchWorkoutExercises(workoutId);
});

// Sets stream for a workout exercise
final setsForWorkoutExerciseProvider =
    StreamProvider.family<List<WorkoutSet>, int>((ref, workoutExerciseId) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.watchSetsForWorkoutExercise(workoutExerciseId);
});

// Completed workouts history
final workoutHistoryProvider = StreamProvider<List<Workout>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.watchCompletedWorkouts();
});

// Enriched workout history with muscle groups, set count, volume
final enrichedWorkoutHistoryProvider =
    StreamProvider<List<WorkoutHistoryItem>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.statsDao.watchEnrichedHistory();
});

// Recent workouts for templates
final recentWorkoutsProvider = FutureProvider<List<Workout>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao.getRecentWorkouts();
});
