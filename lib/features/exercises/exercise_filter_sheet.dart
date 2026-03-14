import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/muscle_group_chip.dart';

class ExerciseFilterSheet extends ConsumerWidget {
  const ExerciseFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(exerciseMuscleFilterProvider);

    return Container(
      padding: const EdgeInsets.all(IronRepSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filter by Muscle Group',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: IronRepSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MuscleGroup.values.map((m) {
              return MuscleGroupChip(
                muscleGroup: m,
                isSelected: selected == m,
                onTap: () {
                  ref.read(exerciseMuscleFilterProvider.notifier).state =
                      selected == m ? null : m;
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: IronRepSpacing.lg),
          if (selected != null)
            TextButton(
              onPressed: () {
                ref.read(exerciseMuscleFilterProvider.notifier).state = null;
                Navigator.pop(context);
              },
              child: const Text('Clear Filter'),
            ),
        ],
      ),
    );
  }
}
