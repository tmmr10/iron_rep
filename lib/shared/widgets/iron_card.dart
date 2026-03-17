import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system.dart';
import 'tap_scale.dart';

class IronCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final Color? accentColor;
  final bool glass;

  const IronCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.accentColor,
    this.glass = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    Widget card;

    if (glass) {
      card = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: padding ?? const EdgeInsets.all(IronRepSpacing.lg),
            decoration: BoxDecoration(
              color: c.glassOverlay,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.glassBorder),
            ),
            child: child,
          ),
        ),
      );
    } else {
      card = Container(
        padding: padding ?? const EdgeInsets.all(IronRepSpacing.lg),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: c.border.withValues(alpha: 0.3),
          ),
          gradient: accentColor != null
              ? LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    accentColor!.withValues(alpha: 0.10),
                    c.card,
                  ],
                )
              : null,
        ),
        child: child,
      );
    }

    if (onTap != null) {
      return TapScale(onTap: onTap, child: card);
    }
    return card;
  }
}
