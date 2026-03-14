import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/stats_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/ad_banner.dart';
import '../../shared/widgets/iron_card.dart';
import 'widgets/volume_chart.dart';
import 'widgets/frequency_heatmap.dart';
import 'widgets/pr_list.dart';

class ProgressTab extends ConsumerWidget {
  const ProgressTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalWorkouts = ref.watch(totalWorkoutsProvider);
    final totalSets = ref.watch(totalSetsProvider);
    final totalVolume = ref.watch(totalVolumeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: IronRepSpacing.screenPadding,
        children: [
          // Summary stats
          Row(
            children: [
              _StatCard(
                label: 'Workouts',
                value: totalWorkouts.valueOrNull?.toString() ?? '0',
              ),
              const SizedBox(width: IronRepSpacing.sm),
              _StatCard(
                label: 'Sets',
                value: totalSets.valueOrNull?.toString() ?? '0',
              ),
              const SizedBox(width: IronRepSpacing.sm),
              _StatCard(
                label: 'Volume',
                value: _formatVolume(totalVolume.valueOrNull ?? 0),
              ),
            ],
          ),
          const SizedBox(height: IronRepSpacing.xl),

          Text('Weekly Volume',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: IronRepSpacing.md),
          const SizedBox(height: 200, child: VolumeChart()),

          const SizedBox(height: IronRepSpacing.xl),
          Text('Activity',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: IronRepSpacing.md),
          const FrequencyHeatmap(),

          const SizedBox(height: IronRepSpacing.xl),
          Text('Personal Records',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: IronRepSpacing.md),
          const PrList(),

          const SizedBox(height: IronRepSpacing.lg),
          const AdBannerWidget(),
        ],
      ),
    );
  }

  String _formatVolume(double vol) {
    if (vol >= 1000000) return '${(vol / 1000000).toStringAsFixed(1)}M';
    if (vol >= 1000) return '${(vol / 1000).toStringAsFixed(1)}k';
    return vol.toStringAsFixed(0);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: IronCard(
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: IronRepColors.accent,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: IronRepColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
