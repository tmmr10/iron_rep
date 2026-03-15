import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system.dart';

class WeightSlider extends StatelessWidget {
  final double value;
  final double? previousValue;
  final double min;
  final double max;
  final double step;
  final ValueChanged<double> onChanged;

  const WeightSlider({
    super.key,
    required this.value,
    this.previousValue,
    this.min = 0,
    this.max = 200,
    this.step = 0.5,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Column(
      children: [
        // Large weight display
        Text(
          '${value.toStringAsFixed(1)} kg',
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 40,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (previousValue != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Letztes Mal: ${previousValue!.toStringAsFixed(1)} kg',
              style: TextStyle(color: c.textMuted, fontSize: 13),
            ),
          ),
        const SizedBox(height: 16),
        // Slider
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: c.accent,
            inactiveTrackColor: c.elevated,
            thumbColor: c.accent,
            overlayColor: c.accent.withValues(alpha: 0.12),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: ((max - min) / step).round(),
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
        const SizedBox(height: 8),
        // Fine adjustment buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(
              label: '+0.5',
              onTap: () {
                if (value + 0.5 <= max) {
                  HapticFeedback.lightImpact();
                  onChanged(value + 0.5);
                }
              },
              colors: c,
            ),
            const SizedBox(width: 12),
            _AdjustButton(
              label: '+1',
              onTap: () {
                if (value + 1 <= max) {
                  HapticFeedback.lightImpact();
                  onChanged(value + 1);
                }
              },
              colors: c,
            ),
            const SizedBox(width: 12),
            _AdjustButton(
              label: '+2.5',
              onTap: () {
                if (value + 2.5 <= max) {
                  HapticFeedback.lightImpact();
                  onChanged(value + 2.5);
                }
              },
              colors: c,
            ),
          ],
        ),
      ],
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppColors colors;

  const _AdjustButton({
    required this.label,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
