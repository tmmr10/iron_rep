import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/muscle_group_chip.dart';

class AddExerciseSheet extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final void Function(int exerciseId) onSelect;

  const AddExerciseSheet({
    super.key,
    required this.scrollController,
    required this.onSelect,
  });

  @override
  ConsumerState<AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends ConsumerState<AddExerciseSheet> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercises = ref.watch(filteredExercisesProvider);
    final selectedMuscle = ref.watch(exerciseMuscleFilterProvider);

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: IronRepColors.textMuted,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            onChanged: (v) =>
                ref.read(exerciseSearchQueryProvider.notifier).state = v,
            decoration: const InputDecoration(
              hintText: 'Search exercises...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
        ),
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
            data: (list) => ListView.builder(
              controller: widget.scrollController,
              itemCount: list.length,
              itemBuilder: (context, index) {
                final e = list[index];
                final muscle = MuscleGroup.values.firstWhere(
                  (m) => m.name == e.primaryMuscleGroup,
                  orElse: () => MuscleGroup.chest,
                );
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: muscle.color.withValues(alpha: 0.2),
                    child: Icon(muscle.icon,
                        color: muscle.color, size: 20),
                  ),
                  title: Text(e.name,
                      style: const TextStyle(
                          color: IronRepColors.textPrimary)),
                  subtitle: Text(muscle.label,
                      style: const TextStyle(
                          color: IronRepColors.textSecondary,
                          fontSize: 12)),
                  onTap: () => widget.onSelect(e.id),
                );
              },
            ),
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ),
      ],
    );
  }
}
