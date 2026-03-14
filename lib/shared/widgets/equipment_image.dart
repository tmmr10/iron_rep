import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../design_system.dart';

class EquipmentImage extends StatelessWidget {
  final EquipmentType equipment;
  final double size;

  const EquipmentImage({
    super.key,
    required this.equipment,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final path = equipment.assetPath;
    if (path == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: IronRepColors.elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.fitness_center,
          color: IronRepColors.textMuted,
          size: size * 0.4,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        path,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: IronRepColors.elevated,
          child: Icon(
            Icons.fitness_center,
            color: IronRepColors.textMuted,
            size: size * 0.4,
          ),
        ),
      ),
    );
  }
}
