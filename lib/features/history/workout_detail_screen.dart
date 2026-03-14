import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/iron_card.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Workout Details')),
      body: FutureBuilder(
        future: _loadWorkoutDetail(db, workoutId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final detail = snapshot.data!;
          final w = detail.workout;
          final duration = w.durationSeconds != null
              ? '${w.durationSeconds! ~/ 60}m ${w.durationSeconds! % 60}s'
              : '--';

          return ListView(
            padding: IronRepSpacing.screenPadding,
            children: [
              Text(w.name ?? 'Workout',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                '${w.startedAt.day}.${w.startedAt.month}.${w.startedAt.year} · $duration',
                style: const TextStyle(color: IronRepColors.textSecondary),
              ),
              const SizedBox(height: IronRepSpacing.xl),
              ...detail.exercises.map((ed) => Padding(
                    padding:
                        const EdgeInsets.only(bottom: IronRepSpacing.md),
                    child: IronCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ed.exerciseName,
                            style: const TextStyle(
                              color: IronRepColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...ed.sets.map((s) => Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 30,
                                      child: Text(
                                        '${s.setNumber}',
                                        style: const TextStyle(
                                            color:
                                                IronRepColors.textMuted),
                                      ),
                                    ),
                                    Text(
                                      '${s.weight?.toStringAsFixed(1) ?? '-'} kg × ${s.reps ?? '-'}',
                                      style: TextStyle(
                                        color: s.isCompleted
                                            ? IronRepColors.textPrimary
                                            : IronRepColors.textMuted,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (s.isCompleted)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8),
                                        child: Icon(Icons.check,
                                            color: IronRepColors.success,
                                            size: 16),
                                      ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  )),
            ],
          );
        },
      ),
    );
  }
}

class _WorkoutDetail {
  final Workout workout;
  final List<_ExerciseDetail> exercises;
  _WorkoutDetail(this.workout, this.exercises);
}

class _ExerciseDetail {
  final String exerciseName;
  final List<WorkoutSet> sets;
  _ExerciseDetail(this.exerciseName, this.sets);
}

Future<_WorkoutDetail> _loadWorkoutDetail(
    AppDatabase db, int workoutId) async {
  final workout = await (db.select(db.workouts)
        ..where((t) => t.id.equals(workoutId)))
      .getSingle();
  final wes = await db.workoutDao.getWorkoutExercises(workoutId);
  final exercises = <_ExerciseDetail>[];

  for (final we in wes) {
    final ex = await (db.select(db.exercises)
          ..where((t) => t.id.equals(we.exerciseId)))
        .getSingle();
    final sets = await db.workoutDao.getSetsForWorkoutExercise(we.id);
    exercises.add(_ExerciseDetail(ex.name, sets));
  }

  return _WorkoutDetail(workout, exercises);
}
