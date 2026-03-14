import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/design_system.dart';

class WorkoutCompleteScreen extends StatelessWidget {
  final int exerciseCount;
  final int totalSets;
  final double totalVolume;
  final int durationSeconds;

  const WorkoutCompleteScreen({
    super.key,
    required this.exerciseCount,
    required this.totalSets,
    required this.totalVolume,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
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
              const Icon(
                Icons.emoji_events,
                size: 80,
                color: IronRepColors.accent,
              ),
              const SizedBox(height: IronRepSpacing.xl),
              Text(
                'Workout Complete!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: IronRepSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: 'Duration', value: '${m}m'),
                  _StatItem(label: 'Exercises', value: '$exerciseCount'),
                  _StatItem(label: 'Sets', value: '$totalSets'),
                  _StatItem(label: 'Volume', value: volumeStr),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/workout'),
                  child: const Text('Done'),
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
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: IronRepColors.accent,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: IronRepColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
