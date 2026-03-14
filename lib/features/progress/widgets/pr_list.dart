import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../../providers/exercise_providers.dart';
import '../../../shared/design_system.dart';

class PrList extends ConsumerWidget {
  const PrList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(allPersonalRecordsProvider);
    final exercisesAsync = ref.watch(allExercisesProvider);

    return recordsAsync.when(
      data: (records) {
        if (records.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Text('No personal records yet',
                style: TextStyle(color: IronRepColors.textMuted)),
          );
        }

        final exerciseNames = exercisesAsync.whenOrNull(
          data: (list) => {for (final e in list) e.id: e.name},
        ) ?? {};

        // Group by exercise, show max_weight only for brevity
        final weightRecords =
            records.where((r) => r.recordType == 'max_weight').toList();

        return Column(
          children: weightRecords.map((r) {
            return ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.emoji_events,
                  color: IronRepColors.warning, size: 20),
              title: Text(
                exerciseNames[r.exerciseId] ?? 'Exercise #${r.exerciseId}',
                style: const TextStyle(color: IronRepColors.textPrimary),
              ),
              subtitle: Text(
                '${r.achievedAt.day}.${r.achievedAt.month}.${r.achievedAt.year}',
                style: const TextStyle(
                    color: IronRepColors.textMuted, fontSize: 12),
              ),
              trailing: Text(
                '${r.value.toStringAsFixed(1)} kg',
                style: const TextStyle(
                  color: IronRepColors.accent,
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
