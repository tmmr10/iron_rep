import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';

class FrequencyChart extends ConsumerWidget {
  const FrequencyChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final dataAsync = ref.watch(weeklyFrequencyProvider);

    return dataAsync.when(
      data: (data) {
        if (data.isEmpty) {
          return Center(
            child:
                Text('Noch keine Daten', style: TextStyle(color: c.textMuted)),
          );
        }

        final maxCount = data.fold<int>(0, (m, d) => d.count > m ? d.count : m);
        final maxY = (maxCount + 1).toDouble().clamp(4.0, 7.0);

        return BarChart(
          BarChartData(
            maxY: maxY,
            barGroups: data.asMap().entries.map((e) {
              return BarChartGroupData(
                x: e.key,
                barRods: [
                  BarChartRodData(
                    toY: e.value.count.toDouble(),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [c.accentGradientStart, c.accentGradientEnd],
                    ),
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6)),
                  ),
                ],
              );
            }).toList(),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    if (value == 0 || value == maxY) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      '${value.toInt()}',
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
                    // Calculate ISO week number
                    final dayOfYear = d.difference(DateTime(d.year, 1, 1)).inDays;
                    final weekNum = ((dayOfYear - d.weekday + 10) / 7).floor();
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
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final count = rod.toY.toInt();
                  return BarTooltipItem(
                    '$count Workout${count != 1 ? 's' : ''}',
                    TextStyle(color: c.textPrimary, fontSize: 12),
                  );
                },
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
