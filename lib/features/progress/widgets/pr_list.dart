import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../../providers/exercise_providers.dart';
import '../../../shared/design_system.dart';

class PrList extends ConsumerWidget {
  const PrList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final recordsAsync = ref.watch(allPersonalRecordsProvider);
    final exercisesAsync = ref.watch(allExercisesProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Noch keine persönlichen Rekorde',
                style: TextStyle(color: c.textMuted)),
          );
        }

        final exerciseNames = exercisesAsync.whenOrNull(
              data: (list) => {for (final e in list) e.id: e.name},
            ) ??
            {};

        final weightRecords =
            records.where((r) => r.recordType == 'max_weight').toList();

        return Column(
          children: weightRecords.map((r) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.emoji_events,
                  color: c.warning, size: 20),
              title: Text(
                exerciseNames[r.exerciseId] ?? 'Exercise #${r.exerciseId}',
                style: TextStyle(color: c.textPrimary),
              ),
              subtitle: Text(
                '${r.achievedAt.day}.${r.achievedAt.month}.${r.achievedAt.year}',
                style: TextStyle(color: c.textMuted, fontSize: 12),
              ),
              trailing: Text(
                '${r.value.toStringAsFixed(1)} kg',
                style: TextStyle(
                  color: c.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(height: 100),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
