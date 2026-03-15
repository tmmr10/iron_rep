import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/enums.dart';
import '../../../providers/plan_providers.dart';
import '../../../providers/stats_providers.dart';
import '../../../shared/design_system.dart';

const _periodOptions = [
  (weeks: 1, label: '1 Woche'),
  (weeks: 2, label: '2 Wochen'),
  (weeks: 4, label: '4 Wochen'),
  (weeks: 8, label: '8 Wochen'),
  (weeks: 12, label: '12 Wochen'),
  (weeks: 26, label: '6 Monate'),
  (weeks: 52, label: '1 Jahr'),
  (weeks: 0, label: 'Gesamt'),
];

class OverallProgressCard extends ConsumerStatefulWidget {
  const OverallProgressCard({super.key});

  @override
  ConsumerState<OverallProgressCard> createState() =>
      _OverallProgressCardState();
}

class _OverallProgressCardState extends ConsumerState<OverallProgressCard> {
  int _selectedPlanId = 0;
  int _selectedWeeks = 0;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final plansAsync = ref.watch(allPlansProvider);
    final params = (planId: _selectedPlanId, weeks: _selectedWeeks);
    final dataAsync = ref.watch(overallProgressProvider(params));
    final exercisesAsync = ref.watch(exerciseProgressProvider(params));

    return Column(
      children: [
        // Plan + Zeitraum Selektoren
        Row(
          children: [
            Expanded(
              child: plansAsync.when(
                data: (plans) {
                  return _Dropdown<int>(
                    value: _selectedPlanId,
                    items: [
                      const DropdownMenuItem(
                          value: 0, child: Text('Alle Pläne')),
                      ...plans.map((p) => DropdownMenuItem(
                          value: p.id, child: Text(p.name))),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedPlanId = v ?? 0),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Dropdown<int>(
                value: _selectedWeeks,
                items: _periodOptions
                    .map((o) => DropdownMenuItem(
                        value: o.weeks, child: Text(o.label)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedWeeks = v ?? 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Aggregate overview row
        dataAsync.when(
          data: (data) {
            if (!data.hasPriorData) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: c.elevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: c.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Noch keine Daten im Vergleichszeitraum. '
                          'Trainiere weiter — die Steigerung wird sichtbar, '
                          'sobald genug Verlauf vorhanden ist.',
                          style: TextStyle(
                              color: c.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  _MetricChip(
                    label: 'Volumen',
                    value: data.volumeChange,
                    icon: Icons.show_chart,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'Frequenz',
                    value: data.frequencyChange,
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(width: 8),
                  _MetricChip(
                    label: 'Gewicht',
                    value: data.avgWeightChange,
                    icon: Icons.fitness_center,
                  ),
                ],
              ),
            );
          },
          loading: () => const SizedBox(height: 60),
          error: (e, _) => Text('Error: $e'),
        ),

        // Per-exercise breakdown
        exercisesAsync.when(
          data: (exercises) {
            if (exercises.isEmpty) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, top: 4),
                  child: Text(
                    'Pro Übung',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...exercises.map((ex) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ExerciseProgressRow(exercise: ex),
                    )),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isUp = value > 0;
    final isDown = value < 0;
    final color = isUp ? c.success : (isDown ? c.error : c.textMuted);
    final sign = value >= 0 ? '+' : '';

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: c.textMuted, size: 16),
            const SizedBox(height: 4),
            Text(
              '$sign${value.toStringAsFixed(1)}%',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseProgressRow extends StatelessWidget {
  final ({
    int exerciseId,
    String name,
    String muscleGroup,
    double recentMax,
    double priorMax,
    double change,
  }) exercise;

  const _ExerciseProgressRow({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final ex = exercise;
    final isUp = ex.change > 0;
    final isDown = ex.change < 0;
    final color = isUp ? c.success : (isDown ? c.error : c.textMuted);
    final sign = ex.change >= 0 ? '+' : '';
    final arrow = isUp
        ? Icons.arrow_upward_rounded
        : (isDown ? Icons.arrow_downward_rounded : Icons.remove);

    final muscle = MuscleGroup.values.firstWhere(
      (m) => m.name == ex.muscleGroup,
      orElse: () => MuscleGroup.chest,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 28,
            decoration: BoxDecoration(
              color: muscle.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ex.name,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${ex.priorMax.toStringAsFixed(1)} → ${ex.recentMax.toStringAsFixed(1)} kg',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(arrow, color: color, size: 16),
          const SizedBox(width: 4),
          Text(
            '$sign${ex.change.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dropdown<T> extends StatelessWidget {
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _Dropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border.withValues(alpha: 0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: c.card,
          icon: Icon(Icons.keyboard_arrow_down, color: c.textMuted),
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
