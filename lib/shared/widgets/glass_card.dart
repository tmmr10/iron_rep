import 'dart:ui';

import 'package:flutter/material.dart';

import '../design_system.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(IronRepSpacing.lg),
          decoration: BoxDecoration(
            color: c.glassOverlay,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: c.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
