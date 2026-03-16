import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/muscle_group_chip.dart';
import '../exercises/create_exercise_sheet.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final void Function(int exerciseId, String exerciseName) onSelect;
  final Set<int> excludeIds;

  const ExercisePickerSheet({
    super.key,
    required this.scrollController,
    required this.onSelect,
    this.excludeIds = const {},
  });

  @override
  ConsumerState<ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _createExercise(BuildContext context) async {
    final result = await showModalBottomSheet<({int id, String name})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateExerciseSheet(),
    );
    if (result != null && mounted) {
      widget.onSelect(result.id, result.name);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final exercises = ref.watch(filteredExercisesProvider);
    final selectedMuscle = ref.watch(exerciseMuscleFilterProvider);

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: c.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) =>
                      ref.read(exerciseSearchQueryProvider.notifier).state = v,
                  decoration: const InputDecoration(
                    hintText: 'Übungen suchen...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => _createExercise(context),
                style: IconButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.background,
                ),
                icon: const Icon(Icons.add),
                tooltip: 'Neue Übung erstellen',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: MuscleGroup.values.map((m) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: MuscleGroupChip(
                  muscleGroup: m,
                  isSelected: selectedMuscle == m,
                  onTap: () {
                    ref.read(exerciseMuscleFilterProvider.notifier).state =
                        selectedMuscle == m ? null : m;
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: exercises.when(
            data: (list) {
              final filtered = list
                  .where((e) => !widget.excludeIds.contains(e.id))
                  .toList();
              return ListView.builder(
                controller: widget.scrollController,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final e = filtered[index];
                  final muscle = MuscleGroup.values.firstWhere(
                    (m) => m.name == e.primaryMuscleGroup,
                    orElse: () => MuscleGroup.chest,
                  );
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          muscle.color.withValues(alpha: 0.2),
                      child: Icon(muscle.icon,
                          color: muscle.color, size: 20),
                    ),
                    title: Text(e.name,
                        style: TextStyle(color: c.textPrimary)),
                    subtitle: Text(muscle.label,
                        style: TextStyle(
                            color: c.textSecondary, fontSize: 12)),
                    onTap: () => widget.onSelect(e.id, e.name),
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
    );
  }
}
