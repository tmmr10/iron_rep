import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/muscle_group_chip.dart';
import 'edit_exercise_sheet.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final int exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final exerciseAsync = ref.watch(exerciseWithEquipmentProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          exerciseAsync.whenOrNull(
                data: (exercise) => IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final saved = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      isDismissible: false,
                      enableDrag: false,
                      backgroundColor: Colors.transparent,
                      builder: (_) => DraggableScrollableSheet(
                        initialChildSize: 0.85,
                        minChildSize: 0.5,
                        maxChildSize: 0.95,
                        builder: (ctx, scrollController) => Container(
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(20)),
                          ),
                          child: EditExerciseSheet(
                            exercise: exercise,
                            scrollController: scrollController,
                          ),
                        ),
                      ),
                    );
                    if (saved == true) {
                      ref.invalidate(
                          exerciseWithEquipmentProvider(exerciseId));
                    }
                  },
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: exerciseAsync.when(
        data: (exercise) => ListView(
          padding: IronRepSpacing.screenPadding,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/exercises/${exercise.nameKey}.jpg',
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),

            // Name
            Text(exercise.name,
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),

            // Tags
            Row(
              children: [
                MuscleGroupChip(
                    muscleGroup: exercise.muscleGroup, isSelected: true),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: c.elevated,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    exercise.category.label,
                    style: TextStyle(color: c.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),

            // Instructions
            if (exercise.instructions != null) ...[
              const SizedBox(height: 24),
              Text(
                'Anleitung',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.instructions!,
                style: TextStyle(
                  color: c.textPrimary,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
            ],

            // Equipment
            if (exercise.equipment.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Geräte',
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.equipment
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            e.label,
                            style: TextStyle(
                                color: c.textPrimary, fontSize: 13),
                          ),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/exercise-progress/$exerciseId'),
              icon: const Icon(Icons.show_chart),
              label: const Text('Fortschritt anzeigen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.accent),
              ),
            ),
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Fehler: $e')),
      ),
    );
  }
}
