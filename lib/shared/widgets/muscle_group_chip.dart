import 'package:flutter/material.dart';

import '../../l10n/enum_labels.dart';
import '../../models/enums.dart';
import '../design_system.dart';
import 'tap_scale.dart';

class MuscleGroupChip extends StatelessWidget {
  final MuscleGroup muscleGroup;
  final bool isSelected;
  final VoidCallback? onTap;

  const MuscleGroupChip({
    super.key,
    required this.muscleGroup,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? muscleGroup.color.withValues(alpha: 0.3)
              : Colors.transparent,
          border: Border.all(
            color: isSelected ? muscleGroup.color : AppColors.of(context).border,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          muscleGroup.localizedLabel(context),
          style: TextStyle(
            color: isSelected ? muscleGroup.color : AppColors.of(context).textSecondary,
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
