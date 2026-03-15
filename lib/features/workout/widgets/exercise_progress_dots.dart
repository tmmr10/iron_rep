import 'package:flutter/material.dart';

import '../../../shared/design_system.dart';

class ExerciseProgressDots extends StatelessWidget {
  final int total;
  final int currentIndex;
  final ValueChanged<int>? onTap;

  const ExerciseProgressDots({
    super.key,
    required this.total,
    required this.currentIndex,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (index) {
        final isCurrent = index == currentIndex;
        final isDone = index < currentIndex;

        return GestureDetector(
          onTap: onTap != null ? () => onTap!(index) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isCurrent ? 24 : 10,
            height: 10,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isDone
                  ? c.success
                  : isCurrent
                      ? c.accent
                      : Colors.transparent,
              border: isDone || isCurrent
                  ? null
                  : Border.all(color: c.border, width: 1.5),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        );
      }),
    );
  }
}
