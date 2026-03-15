import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/timer_providers.dart';
import '../../shared/design_system.dart';

class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final timer = ref.watch(restTimerProvider);

    if (!timer.isRunning) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.accent, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: timer.progress,
              strokeWidth: 3,
              color: c.accent,
              backgroundColor: c.elevated,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rest Timer',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 12,
                    )),
                Text(
                  timer.displayTime,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.remove, color: c.textSecondary),
            onPressed: () =>
                ref.read(restTimerProvider.notifier).addTime(-15),
          ),
          IconButton(
            icon: Icon(Icons.add, color: c.textSecondary),
            onPressed: () =>
                ref.read(restTimerProvider.notifier).addTime(15),
          ),
          IconButton(
            icon: Icon(Icons.skip_next, color: c.accent),
            onPressed: () => ref.read(restTimerProvider.notifier).skip(),
          ),
        ],
      ),
    );
  }
}
