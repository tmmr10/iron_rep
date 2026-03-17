import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_helper.dart';
import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';

class StrengthChart extends ConsumerWidget {
  final int exerciseId;

  const StrengthChart({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final dataAsync = ref.watch(strengthProgressProvider(exerciseId));

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Text(context.l10n.noDataYet,
                style: TextStyle(color: c.textMuted)),
          );
        }

        final spots = data.asMap().entries.map((e) {
          return FlSpot(e.key.toDouble(), e.value.maxWeight);
        }).toList();

        final maxW =
            data.map((d) => d.maxWeight).reduce((a, b) => a > b ? a : b);

        return LineChart(
          LineChartData(
            maxY: maxW * 1.15,
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                curveSmoothness: 0.3,
                color: c.accent,
                barWidth: 2.5,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, bar, index) =>
                      FlDotCirclePainter(
                    radius: 3,
                    color: c.accent,
                    strokeWidth: 0,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: c.accent.withValues(alpha: 0.1),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) => Text(
                    '${value.toInt()}',
                    style: TextStyle(color: c.textMuted, fontSize: 10),
                  ),
                ),
              ),
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
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: c.divider,
                strokeWidth: 0.5,
              ),
            ),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    return LineTooltipItem(
                      '${spot.y.toStringAsFixed(1)} kg',
                      TextStyle(color: c.textPrimary, fontSize: 12),
                    );
                  }).toList();
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
