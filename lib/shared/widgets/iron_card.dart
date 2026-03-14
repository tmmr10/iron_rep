import 'package:flutter/material.dart';

import '../design_system.dart';

class IronCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const IronCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding ?? const EdgeInsets.all(IronRepSpacing.lg),
      decoration: BoxDecoration(
        color: IronRepColors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}
