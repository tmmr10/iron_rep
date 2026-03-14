import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import 'widgets/strength_chart.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  final int exerciseId;

  const ExerciseProgressScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseAsync = ref.watch(exerciseWithEquipmentProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: exerciseAsync.whenOrNull(
              data: (e) => Text(e.name),
            ) ??
            const Text('Progress'),
      ),
      body: ListView(
        padding: IronRepSpacing.screenPadding,
        children: [
          Text('Strength Over Time',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: IronRepSpacing.md),
          SizedBox(
            height: 250,
            child: StrengthChart(exerciseId: exerciseId),
          ),
          const SizedBox(height: IronRepSpacing.xl),
          Text('Personal Records',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: IronRepSpacing.md),
          _RecordsSection(exerciseId: exerciseId),
        ],
      ),
    );
  }
}

class _RecordsSection extends ConsumerWidget {
  final int exerciseId;
  const _RecordsSection({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    return FutureBuilder(
      future: db.workoutDao.getRecordsForExercise(exerciseId),
      builder: (context, snapshot) {
        final records = snapshot.data;
        if (records == null || records.isEmpty) {
          return const Text('No records yet',
              style: TextStyle(color: IronRepColors.textMuted));
        }
        return Column(
          children: records.map((r) {
            String label;
            String value;
            switch (r.recordType) {
              case 'max_weight':
                label = 'Max Weight';
                value = '${r.value.toStringAsFixed(1)} kg';
              case 'max_reps':
                label = 'Max Reps';
                value = '${r.value.toInt()}';
              case 'max_volume':
                label = 'Max Volume';
                value = '${r.value.toStringAsFixed(0)} kg';
              default:
                label = r.recordType;
                value = r.value.toString();
            }
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text(label,
                  style:
                      const TextStyle(color: IronRepColors.textPrimary)),
              trailing: Text(value,
                  style: const TextStyle(
                    color: IronRepColors.accent,
                    fontWeight: FontWeight.w700,
                  )),
            );
          }).toList(),
        );
      },
    );
  }
}
