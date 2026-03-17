import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/purchase_providers.dart';
import '../../services/ad_service.dart';
import '../../l10n/l10n_helper.dart';
import '../../shared/design_system.dart';

class WorkoutCompleteScreen extends ConsumerStatefulWidget {
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
  ConsumerState<WorkoutCompleteScreen> createState() =>
      _WorkoutCompleteScreenState();
}

class _WorkoutCompleteScreenState extends ConsumerState<WorkoutCompleteScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adsRemoved =
          ref.read(isAdsRemovedProvider).valueOrNull ?? false;
      if (!adsRemoved) {
        AdService.showInterstitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final m = widget.durationSeconds ~/ 60;
    final volumeStr = widget.totalVolume >= 1000
        ? '${(widget.totalVolume / 1000).toStringAsFixed(1)}t'
        : '${widget.totalVolume.toStringAsFixed(0)} kg';

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
                context.l10n.workoutCompleted,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              if (widget.planName != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.planName!,
                  style: TextStyle(color: c.textSecondary, fontSize: 16),
                ),
              ],
              const SizedBox(height: IronRepSpacing.xxl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatItem(label: context.l10n.duration, value: '${m}m'),
                  _StatItem(
                      label: context.l10n.exercises, value: '${widget.exerciseCount}'),
                  _StatItem(label: context.l10n.sets, value: '${widget.totalSets}'),
                  _StatItem(label: context.l10n.volume, value: volumeStr),
                ],
              ),
              if (widget.skippedCount > 0) ...[
                const SizedBox(height: IronRepSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.skip_next_rounded,
                        color: c.warning, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      context.l10n.skippedCount(widget.skippedCount),
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
                  child: Text(context.l10n.done),
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
