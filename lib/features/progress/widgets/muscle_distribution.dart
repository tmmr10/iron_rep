import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums.dart';
import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';

class MuscleDistribution extends ConsumerWidget {
  const MuscleDistribution({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final dataAsync = ref.watch(muscleDistributionProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('Noch keine Daten',
                style: TextStyle(color: c.textMuted)),
          );
        }

        final total = data.fold<int>(0, (sum, d) => sum + d.count);

        final sections = data.map((d) {
          final muscle = MuscleGroup.values.firstWhere(
            (m) => m.name == d.muscleGroup,
            orElse: () => MuscleGroup.fullBody,
          );
          final percent = d.count / total * 100;
          return _MuscleSection(
            muscle: muscle,
            count: d.count,
            percent: percent,
          );
        }).toList();

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 50,
                  sections: sections.map((s) {
                    return PieChartSectionData(
                      color: s.muscle.color,
                      value: s.count.toDouble(),
                      title: '',
                      radius: 40,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: sections.map((s) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: s.muscle.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${s.muscle.label} ${s.percent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class _MuscleSection {
  final MuscleGroup muscle;
  final int count;
  final double percent;

  const _MuscleSection({
    required this.muscle,
    required this.count,
    required this.percent,
  });
}
