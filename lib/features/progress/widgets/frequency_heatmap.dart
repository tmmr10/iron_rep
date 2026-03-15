import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';

class FrequencyHeatmap extends ConsumerWidget {
  final int weeksToShow;

  const FrequencyHeatmap({super.key, this.weeksToShow = 16});

  static const _dayLabels = ['M', 'D', 'M', 'D', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final daysAsync = ref.watch(workoutDaysProvider);

    return daysAsync.when(
      data: (days) {
        if (days.isEmpty) {
          return SizedBox(
            height: 100,
            child: Center(
              child: Text('Noch keine Aktivität',
                  style: TextStyle(color: c.textMuted)),
            ),
          );
        }

        final volumeMap = <String, double>{};
        double maxVolume = 0;
        for (final d in days) {
          final key =
              '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}-${d.date.day.toString().padLeft(2, '0')}';
          volumeMap[key] = d.volume;
          if (d.volume > maxVolume) maxVolume = d.volume;
        }

        final now = DateTime.now();
        final startDate =
            now.subtract(Duration(days: weeksToShow * 7));

        return SizedBox(
          height: 100,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Column(
                children: List.generate(7, (i) {
                  return Container(
                    width: 16,
                    height: 12,
                    margin: const EdgeInsets.all(1),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _dayLabels[i],
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 9,
                        height: 1,
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 2),
              // Heatmap grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(weeksToShow, (weekIdx) {
                      return Column(
                        children: List.generate(7, (dayIdx) {
                          final date = startDate
                              .add(Duration(days: weekIdx * 7 + dayIdx));
                          final key =
                              '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                          final volume = volumeMap[key] ?? 0;
                          final intensity =
                              maxVolume > 0 ? volume / maxVolume : 0.0;

                          return Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: intensity > 0
                                  ? c.success.withValues(
                                      alpha: 0.2 + intensity * 0.8)
                                  : c.elevated,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 100),
      error: (e, _) => Text('Error: $e'),
    );
  }
}
