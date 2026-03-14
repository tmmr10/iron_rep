import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/enums.dart';
import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/muscle_group_chip.dart';

class ExercisesTab extends ConsumerWidget {
  const ExercisesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercises = ref.watch(filteredExercisesProvider);
    final selectedMuscle = ref.watch(exerciseMuscleFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercises'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(96),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => ref
                      .read(exerciseSearchQueryProvider.notifier)
                      .state = v,
                  decoration: const InputDecoration(
                    hintText: 'Search exercises...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 36,
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
                          ref
                              .read(exerciseMuscleFilterProvider.notifier)
                              .state = selectedMuscle == m ? null : m;
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: exercises.when(
              data: (list) => ListView.builder(
                itemCount: list.length,
                itemBuilder: (context, index) {
                  final e = list[index];
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
                        style: const TextStyle(
                            color: IronRepColors.textPrimary)),
                    subtitle: Text(
                      '${muscle.label} · ${e.category}',
                      style: const TextStyle(
                          color: IronRepColors.textSecondary,
                          fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        color: IronRepColors.textMuted),
                    onTap: () =>
                        context.push('/exercise-detail/${e.id}'),
                  );
                },
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
          const AdBannerWidget(),
        ],
      ),
    );
  }
}
