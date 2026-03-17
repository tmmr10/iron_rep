import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_helper.dart';
import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';

class VolumeChart extends ConsumerWidget {
  const VolumeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final dataAsync = ref.watch(volumePerWorkoutProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Text(context.l10n.noDataYet,
                style: TextStyle(color: c.textMuted)),
          );
        }

        final maxVol =
            data.map((d) => d.volume).reduce((a, b) => a > b ? a : b);

        return BarChart(
          BarChartData(
            maxY: maxVol * 1.2,
            barGroups: data.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.volume,
                    color: c.accent,
                    width: 12,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) {
                      return const SizedBox.shrink();
                    }
                    final d = data[idx].date;
                    return Text(
                      '${d.day}.${d.month}',
                      style: TextStyle(color: c.textMuted, fontSize: 10),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${rod.toY.toStringAsFixed(0)} kg',
                    TextStyle(color: c.textPrimary, fontSize: 12),
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(context.l10n.error('$e'))),
    );
  }
}
