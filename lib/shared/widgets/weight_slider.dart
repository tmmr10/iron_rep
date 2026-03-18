import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system.dart';
import 'tap_scale.dart';

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

  void _adjust(double delta) {
    final newVal = (value + delta).clamp(min, max);
    if (newVal != value) {
      HapticFeedback.lightImpact();
      onChanged(newVal);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    // 1kg steps on slider; fine-tuning via buttons
    const sliderStep = 1.0;
    final divisions = ((max - min) / sliderStep).round();

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
        // Slider with dot track
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: c.accent,
            inactiveTrackColor: c.elevated,
            thumbColor: c.accent,
            overlayColor: c.accent.withValues(alpha: 0.12),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
            trackShape: _DotTrackShape(
              dotSpacing: 5.0,
              activeColor: c.accent,
              inactiveColor: c.textMuted.withValues(alpha: 0.3),
            ),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Adjustment buttons: minus and plus
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(label: '\u22121', onTap: () => _adjust(-1), colors: c),
            const SizedBox(width: 10),
            _AdjustButton(label: '\u22120.5', onTap: () => _adjust(-0.5), colors: c),
            const SizedBox(width: 20),
            _AdjustButton(label: '+0.5', onTap: () => _adjust(0.5), colors: c, accent: true),
            const SizedBox(width: 10),
            _AdjustButton(label: '+1', onTap: () => _adjust(1), colors: c, accent: true),
          ],
        ),
      ],
    );
  }
}

/// Custom track that draws dots instead of a continuous bar, like the duration slider.
class _DotTrackShape extends SliderTrackShape {
  final double dotSpacing;
  final Color activeColor;
  final Color inactiveColor;

  const _DotTrackShape({
    required this.dotSpacing,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 6;
    final trackLeft = offset.dx + 12;
    final trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width - 24;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final rect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
    );
    final canvas = context.canvas;
    final dotRadius = 2.5;
    final cy = rect.center.dy;

    // Calculate number of dots
    final totalDots = math.max(1, (rect.width / dotSpacing).floor());

    for (int i = 0; i <= totalDots; i++) {
      final x = rect.left + (i / totalDots) * rect.width;
      final isActive = x <= thumbCenter.dx;
      canvas.drawCircle(
        Offset(x, cy),
        dotRadius,
        Paint()..color = isActive ? activeColor : inactiveColor,
      );
    }
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final AppColors colors;
  final bool accent;

  const _AdjustButton({
    required this.label,
    required this.onTap,
    required this.colors,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: accent
              ? colors.accent.withValues(alpha: 0.1)
              : colors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: accent
                ? colors.accent.withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accent ? colors.accent : colors.textSecondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
