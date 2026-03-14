import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/equipment_image.dart';
import '../../shared/widgets/iron_card.dart';
import '../../shared/widgets/muscle_group_chip.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final int exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseWithEquipmentProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(title: const Text('Exercise')),
      body: exerciseAsync.when(
        data: (exercise) => ListView(
          padding: IronRepSpacing.screenPadding,
          children: [
            // Equipment image
            if (exercise.primaryEquipment != null)
              Center(
                child: EquipmentImage(
                  equipment: exercise.primaryEquipment!,
                  size: 160,
                ),
              ),
            const SizedBox(height: IronRepSpacing.xl),

            Text(exercise.name,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: IronRepSpacing.sm),

            Wrap(
              spacing: 8,
              children: [
                MuscleGroupChip(
                    muscleGroup: exercise.muscleGroup, isSelected: true),
                Chip(
                  label: Text(exercise.category.label),
                  backgroundColor: IronRepColors.elevated,
                  labelStyle: const TextStyle(
                      color: IronRepColors.textSecondary, fontSize: 13),
                  side: BorderSide.none,
                ),
              ],
            ),

            if (exercise.instructions != null) ...[
              const SizedBox(height: IronRepSpacing.xl),
              IronCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Instructions',
                        style: TextStyle(
                          color: IronRepColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 8),
                    Text(
                      exercise.instructions!,
                      style: const TextStyle(
                        color: IronRepColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (exercise.equipment.isNotEmpty) ...[
              const SizedBox(height: IronRepSpacing.lg),
              IronCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Equipment',
                        style: TextStyle(
                          color: IronRepColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: exercise.equipment
                          .map((e) => Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  EquipmentImage(
                                      equipment: e, size: 32),
                                  const SizedBox(width: 8),
                                  Text(e.label,
                                      style: const TextStyle(
                                          color: IronRepColors
                                              .textSecondary)),
                                ],
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: IronRepSpacing.lg),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/exercise-progress/$exerciseId'),
              icon: const Icon(Icons.show_chart),
              label: const Text('View Progress'),
              style: OutlinedButton.styleFrom(
                foregroundColor: IronRepColors.accent,
                side: const BorderSide(color: IronRepColors.accent),
              ),
            ),
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
