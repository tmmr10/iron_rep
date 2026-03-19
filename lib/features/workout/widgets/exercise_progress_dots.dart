import 'package:flutter/material.dart';

import '../../../shared/design_system.dart';

class ExerciseProgressDots extends StatelessWidget {
  final int total;
  final int currentIndex;
  final Set<int> completedIndices;
  final ValueChanged<int>? onTap;

  const ExerciseProgressDots({
    super.key,
    required this.total,
    required this.currentIndex,
    this.completedIndices = const {},
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (index) {
          final isCurrent = index == currentIndex;
          final isDone = completedIndices.contains(index);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap != null ? () => onTap!(index) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
              child: SizedBox(
                width: isCurrent ? 28 : 16,
                height: 28,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: isCurrent ? 28 : 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isDone
                          ? c.success
                          : isCurrent
                              ? c.accent
                              : Colors.transparent,
                      border: isDone || isCurrent
                          ? null
                          : Border.all(color: c.border, width: 1.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isDone && !isCurrent
                        ? Icon(Icons.check, size: 8, color: Colors.white)
                        : null,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
