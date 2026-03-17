import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/l10n_helper.dart';
import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';

class WeeklyVolumeChart extends ConsumerWidget {
  const WeeklyVolumeChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final dataAsync = ref.watch(weeklyVolumeProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child: Text(context.l10n.noDataYet,
                style: TextStyle(color: c.textMuted)),
          );
        }

        final maxVol =
            data.fold<double>(0, (m, d) => d.volume > m ? d.volume : m);
        final maxY = maxVol * 1.2;

        return LineChart(
          LineChartData(
            maxY: maxY,
            minY: 0,
            lineBarsData: [
              LineChartBarData(
                spots: data.asMap().entries.map((e) {
                  return FlSpot(e.key.toDouble(), e.value.volume);
                }).toList(),
                isCurved: true,
                curveSmoothness: 0.3,
                gradient: LinearGradient(
                  colors: [c.accentGradientStart, c.accentGradientEnd],
                ),
                barWidth: 2.5,
                isStrokeCapRound: true,
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
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      c.accent.withValues(alpha: 0.15),
                      c.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == maxY) {
                      return const SizedBox.shrink();
                    }
                    String label;
                    if (value >= 1000) {
                      label = '${(value / 1000).toStringAsFixed(1)}t';
                    } else {
                      label = '${value.toInt()} kg';
                    }
                    return Text(
                      label,
                      style: TextStyle(color: c.textMuted, fontSize: 10),
                    );
                  },
                ),
              ),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= data.length) {
                      return const SizedBox.shrink();
                    }
                    final d = data[idx].weekStart;
                    final dayOfYear =
                        d.difference(DateTime(d.year, 1, 1)).inDays;
                    final weekNum =
                        ((dayOfYear - d.weekday + 10) / 7).floor();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'KW$weekNum',
                        style: TextStyle(color: c.textMuted, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (touchedSpots) {
                  return touchedSpots.map((spot) {
                    String label;
                    if (spot.y >= 1000) {
                      label = '${(spot.y / 1000).toStringAsFixed(1)}k kg';
                    } else {
                      label = '${spot.y.toStringAsFixed(0)} kg';
                    }
                    return LineTooltipItem(
                      label,
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
