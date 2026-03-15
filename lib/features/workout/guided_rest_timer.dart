import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/timer_providers.dart';
import '../../shared/design_system.dart';

class GuidedRestTimer extends ConsumerWidget {
  final String? nextExerciseName;
  final String? nextSetInfo;

  const GuidedRestTimer({
    super.key,
    this.nextExerciseName,
    this.nextSetInfo,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final timer = ref.watch(restTimerProvider);

    if (!timer.isRunning) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        // Circular countdown
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: timer.progress,
                  strokeWidth: 6,
                  color: c.accent,
                  backgroundColor: c.elevated,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timer.displayTime,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    'Pause',
                    style: TextStyle(color: c.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // +/- 15s controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TimerAdjustButton(
              label: '-15s',
              onTap: () =>
                  ref.read(restTimerProvider.notifier).addTime(-15),
            ),
            const SizedBox(width: 16),
            _TimerAdjustButton(
              label: '+15s',
              onTap: () =>
                  ref.read(restTimerProvider.notifier).addTime(15),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Skip button
        TextButton.icon(
          onPressed: () {
            ref.read(restTimerProvider.notifier).skip();
          },
          icon: Icon(Icons.skip_next, color: c.accent),
          label: Text('Überspringen',
              style: TextStyle(color: c.accent, fontSize: 16)),
        ),
        // Next set or next exercise preview
        if (nextSetInfo != null) ...[
          const SizedBox(height: 20),
          Text(
            'Nächster Satz',
            style: TextStyle(color: c.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            nextSetInfo!,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ] else if (nextExerciseName != null) ...[
          const SizedBox(height: 20),
          Text(
            'Nächste Übung',
            style: TextStyle(color: c.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            nextExerciseName!,
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _TimerAdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _TimerAdjustButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: c.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
