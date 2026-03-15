import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/muscle_group_chip.dart';
import 'create_exercise_sheet.dart';

class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final searchQuery = ref.watch(exerciseSearchQueryProvider);
    final muscleFilter = ref.watch(exerciseMuscleFilterProvider);
    final exercisesAsync = ref.watch(filteredExercisesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Übungen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Neue Übung',
            onPressed: () async {
              final result = await showModalBottomSheet<({int id, String name})>(
                context: context,
                isScrollControlled: true,
                backgroundColor: c.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (_) => const CreateExerciseSheet(),
              );
              if (result != null) {
                ref.invalidate(allExercisesProvider);
                ref.invalidate(filteredExercisesProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Übung suchen...',
                prefixIcon: Icon(Icons.search, color: c.textMuted),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: c.border.withValues(alpha: 0.5)),
                ),
                filled: true,
                fillColor: c.card,
              ),
              onChanged: (v) =>
                  ref.read(exerciseSearchQueryProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 12),

          // Muscle group filter
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                GestureDetector(
                  onTap: () => ref
                      .read(exerciseMuscleFilterProvider.notifier)
                      .state = null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: muscleFilter == null
                          ? c.accent.withValues(alpha: 0.2)
                          : c.elevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: muscleFilter == null
                            ? c.accent
                            : c.border.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Text(
                      'Alle',
                      style: TextStyle(
                        color: muscleFilter == null
                            ? c.accent
                            : c.textSecondary,
                        fontSize: 13,
                        fontWeight: muscleFilter == null
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ...MuscleGroup.values.map((m) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => ref
                            .read(exerciseMuscleFilterProvider.notifier)
                            .state = m,
                        child: MuscleGroupChip(
                          muscleGroup: m,
                          isSelected: muscleFilter == m,
                        ),
                      ),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Exercise list
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Text(
                      searchQuery.isNotEmpty
                          ? 'Keine Übungen gefunden'
                          : 'Keine Übungen in dieser Kategorie',
                      style: TextStyle(color: c.textMuted),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final ex = exercises[index];
                    final muscle = MuscleGroup.values.firstWhere(
                      (m) => m.name == ex.primaryMuscleGroup,
                      orElse: () => MuscleGroup.chest,
                    );
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 4,
                        height: 28,
                        decoration: BoxDecoration(
                          color: muscle.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      title: Text(
                        ex.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        muscle.label,
                        style: TextStyle(color: c.textMuted, fontSize: 12),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: c.textMuted, size: 18),
                      onTap: () =>
                          context.push('/exercise-detail/${ex.id}'),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Fehler: $e')),
            ),
          ),
        ],
      ),
    );
  }
}
