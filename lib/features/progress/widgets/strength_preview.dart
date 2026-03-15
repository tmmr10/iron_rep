import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';
import '../progress_tab.dart';
import 'strength_chart.dart';

final strengthTrendProvider = FutureProvider.family<
    ({double current, double change}), int>((ref, exerciseId) async {
  final data = await ref.watch(strengthProgressProvider(exerciseId).future);
  if (data.isEmpty) return (current: 0.0, change: 0.0);
  if (data.length < 2) return (current: data.first.maxWeight, change: 0.0);
  final current = data.last.maxWeight;
  final previous = data[data.length - 2].maxWeight;
  final change = previous > 0 ? (current - previous) / previous * 100 : 0.0;
  return (current: current, change: change);
});

class StrengthPreview extends ConsumerStatefulWidget {
  const StrengthPreview({super.key});

  @override
  ConsumerState<StrengthPreview> createState() => _StrengthPreviewState();
}

class _StrengthPreviewState extends ConsumerState<StrengthPreview> {
  int? _selectedExerciseId;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final exercisesAsync = ref.watch(trainedExercisesProvider);

    return exercisesAsync.when(
      data: (exercises) {
        if (exercises.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              'Schließe ein Workout ab, um Kraftentwicklung zu sehen',
              style: TextStyle(color: c.textMuted),
            ),
          );
        }

        _selectedExerciseId ??= exercises.first.id;

        final selected = exercises.firstWhere(
          (e) => e.id == _selectedExerciseId,
          orElse: () => exercises.first,
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise dropdown selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border.withValues(alpha: 0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: selected.id,
                  isExpanded: true,
                  dropdownColor: c.card,
                  icon: Icon(Icons.keyboard_arrow_down, color: c.textMuted),
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  items: exercises.map((ex) {
                    return DropdownMenuItem<int>(
                      value: ex.id,
                      child: Text(ex.name),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) setState(() => _selectedExerciseId = id);
                  },
                ),
              ),
            ),
            const SizedBox(height: IronRepSpacing.md),
            // Chart
            SizedBox(
              height: 180,
              child: StrengthChart(exerciseId: _selectedExerciseId!),
            ),
            const SizedBox(height: IronRepSpacing.md),
            // Trend indicator
            _TrendRow(exerciseId: _selectedExerciseId!),
          ],
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class _TrendRow extends ConsumerWidget {
  final int exerciseId;
  const _TrendRow({required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final trendAsync = ref.watch(strengthTrendProvider(exerciseId));

    return trendAsync.when(
      data: (trend) {
        if (trend.current == 0) return const SizedBox.shrink();

        final isUp = trend.change > 0;
        final isDown = trend.change < 0;
        final trendColor =
            isUp ? c.success : (isDown ? c.error : c.textSecondary);
        final trendIcon = isUp
            ? Icons.trending_up
            : (isDown ? Icons.trending_down : Icons.trending_flat);

        return Row(
          children: [
            Text(
              'Aktuell: ${trend.current.toStringAsFixed(1)} kg',
              style: TextStyle(
                color: c.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Icon(trendIcon, color: trendColor, size: 18),
            const SizedBox(width: 4),
            Text(
              '${trend.change >= 0 ? '+' : ''}${trend.change.toStringAsFixed(1)}%',
              style: TextStyle(
                color: trendColor,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(height: 20),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
