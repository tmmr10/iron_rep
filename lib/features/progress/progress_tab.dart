import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../providers/database_provider.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/iron_card.dart';
import '../../shared/widgets/section_header.dart';
import 'widgets/muscle_distribution.dart';
import 'widgets/overall_progress_card.dart';
import '../../l10n/l10n_helper.dart';
import 'widgets/strength_preview.dart';

// Provider for exercises the user has actually trained
final trainedExercisesProvider = FutureProvider<
    List<({int id, String name, String muscleGroup, double lastWeight})>>(
    (ref) async {
  final db = ref.watch(databaseProvider);
  final results = await db.customSelect(
    '''
    SELECT e.id, e.name, e.primary_muscle_group,
           (SELECT s.weight FROM workout_sets s
            JOIN workout_exercises we2 ON s.workout_exercise_id = we2.id
            WHERE we2.exercise_id = e.id AND s.weight IS NOT NULL AND s.is_completed = 1
            ORDER BY s.completed_at DESC LIMIT 1) AS last_weight
    FROM exercises e
    WHERE e.id IN (
      SELECT DISTINCT we.exercise_id FROM workout_exercises we
      JOIN workouts w ON we.workout_id = w.id
      WHERE w.completed_at IS NOT NULL
    )
    ORDER BY e.name
    ''',
  ).get();

  return results
      .map((row) => (
            id: row.read<int>('id'),
            name: row.read<String>('name'),
            muscleGroup: row.read<String>('primary_muscle_group'),
            lastWeight: row.readNullable<double>('last_weight') ?? 0.0,
          ))
      .toList();
});

class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final trainedExercises = ref.watch(trainedExercisesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.progress)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
        children: [
          SectionHeader(title: context.l10n.yourProgress),
          const OverallProgressCard(),

          const SizedBox(height: IronRepSpacing.xl),
          SectionHeader(title: context.l10n.muscleDistribution),
          const MuscleDistribution(),

          const SizedBox(height: IronRepSpacing.xl),
          SectionHeader(title: context.l10n.strengthDevelopment),
          const StrengthPreview(),

          const SizedBox(height: IronRepSpacing.xl),
          SectionHeader(title: context.l10n.yourExercises),
          trainedExercises.when(
            data: (exercises) {
              if (exercises.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    context.l10n.completeWorkoutToSeeExercises,
                    style: TextStyle(color: c.textMuted),
                  ),
                );
              }
              return Column(
                children: exercises.map((ex) {
                  final muscle = MuscleGroup.values.firstWhere(
                    (m) => m.name == ex.muscleGroup,
                    orElse: () => MuscleGroup.chest,
                  );
                  return Padding(
                    padding:
                        const EdgeInsets.only(bottom: IronRepSpacing.sm),
                    child: IronCard(
                      onTap: () =>
                          context.push('/exercise-progress/${ex.id}'),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 20,
                            decoration: BoxDecoration(
                              color: muscle.color,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: IronRepSpacing.md),
                          Expanded(
                            child: Text(
                              ex.name,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (ex.lastWeight > 0)
                            Text(
                              '${ex.lastWeight.toStringAsFixed(1)} kg',
                              style: TextStyle(
                                color: c.accent,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right,
                              color: c.textMuted, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            },
            loading: () => const SizedBox(height: 60),
            error: (e, _) => Text(context.l10n.error('$e')),
          ),

          const SizedBox(height: IronRepSpacing.lg),
        ],
      ),
    );
  }
}

