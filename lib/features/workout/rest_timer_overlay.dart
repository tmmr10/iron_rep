import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/timer_providers.dart';
import '../../shared/design_system.dart';

class RestTimerOverlay extends ConsumerWidget {
  const RestTimerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);

    if (!timer.isRunning) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: IronRepColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: IronRepColors.accent, width: 1),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              value: timer.progress,
              strokeWidth: 3,
              color: IronRepColors.accent,
              backgroundColor: IronRepColors.elevated,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Rest Timer',
                    style: TextStyle(
                      color: IronRepColors.textSecondary,
                      fontSize: 12,
                    )),
                Text(
                  timer.displayTime,
                  style: const TextStyle(
                    color: IronRepColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove, color: IronRepColors.textSecondary),
            onPressed: () =>
                ref.read(restTimerProvider.notifier).addTime(-15),
          ),
          IconButton(
            icon: const Icon(Icons.add, color: IronRepColors.textSecondary),
            onPressed: () =>
                ref.read(restTimerProvider.notifier).addTime(15),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: IronRepColors.accent),
            onPressed: () => ref.read(restTimerProvider.notifier).skip(),
          ),
        ],
      ),
    );
  }
}
