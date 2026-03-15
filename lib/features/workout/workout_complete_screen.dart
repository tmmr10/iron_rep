import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/design_system.dart';

class WorkoutCompleteScreen extends StatelessWidget {
  final String? planName;
  final int exerciseCount;
  final int totalSets;
  final double totalVolume;
  final int durationSeconds;
  final int skippedCount;

  const WorkoutCompleteScreen({
    super.key,
    this.planName,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolume,
    required this.durationSeconds,
    this.skippedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final m = durationSeconds ~/ 60;
    final volumeStr = totalVolume >= 1000
        ? '${(totalVolume / 1000).toStringAsFixed(1)}t'
        : '${totalVolume.toStringAsFixed(0)} kg';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: IronRepSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(Icons.emoji_events, size: 80, color: c.accent),
              const SizedBox(height: IronRepSpacing.xl),
              Text(
                'Workout abgeschlossen!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (planName != null) ...[
                const SizedBox(height: 8),
                Text(
                  planName!,
                  style: TextStyle(color: c.textSecondary, fontSize: 16),
                ),
              ],
              const SizedBox(height: IronRepSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: 'Dauer', value: '${m}m'),
                  _StatItem(label: 'Übungen', value: '$exerciseCount'),
                  _StatItem(label: 'Sätze', value: '$totalSets'),
                  _StatItem(label: 'Volumen', value: volumeStr),
                ],
              ),
              if (skippedCount > 0) ...[
                const SizedBox(height: IronRepSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.skip_next_rounded,
                        color: c.warning, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '$skippedCount übersprungen',
                      style: TextStyle(
                        color: c.warning,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/workout'),
                  child: const Text('Fertig'),
                ),
              ),
              const SizedBox(height: IronRepSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: c.accent,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: c.textSecondary, fontSize: 13),
        ),
      ],
    );
  }
}
