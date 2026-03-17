import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/l10n_helper.dart';

import '../design_system.dart';

class RepsStepper extends StatelessWidget {
  final int value;
  final int? previousValue;
  final ValueChanged<int> onChanged;

  const RepsStepper({
    super.key,
    required this.value,
    this.previousValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Minus button
            GestureDetector(
              onTap: () {
                if (value > 0) {
                  HapticFeedback.lightImpact();
                  onChanged(value - 1);
                }
              },
              onLongPressStart: (_) => _startAutoDecrement(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Icon(Icons.remove, color: c.textPrimary, size: 28),
              ),
            ),
            // Reps display
            SizedBox(
              width: 120,
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    context.l10n.reps,
                    style: TextStyle(color: c.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
            // Plus button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onChanged(value + 1);
              },
              onLongPressStart: (_) => _startAutoIncrement(context),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.border),
                ),
                child: Icon(Icons.add, color: c.textPrimary, size: 28),
              ),
            ),
          ],
        ),
        if (previousValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Letztes Mal: $previousValue',
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
          ),
      ],
    );
  }

  void _startAutoIncrement(BuildContext context) {
    // Auto-increment handled via long press gesture
    // Simple single increment on long press start
    HapticFeedback.lightImpact();
    onChanged(value + 1);
  }

  void _startAutoDecrement(BuildContext context) {
    if (value > 0) {
      HapticFeedback.lightImpact();
      onChanged(value - 1);
    }
  }
}
