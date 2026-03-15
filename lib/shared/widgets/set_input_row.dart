import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/enums.dart';
import '../design_system.dart';

class SetInputRow extends StatelessWidget {
  final int setNumber;
  final String setType;
  final double? previousWeight;
  final int? previousReps;
  final bool isCompleted;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final VoidCallback onComplete;
  final VoidCallback? onDelete;

  const SetInputRow({
    super.key,
    required this.setNumber,
    required this.setType,
    this.previousWeight,
    this.previousReps,
    required this.isCompleted,
    required this.weightController,
    required this.repsController,
    required this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final typeLabel = SetType.values
        .firstWhere((t) => t.name == setType, orElse: () => SetType.working)
        .label;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: IronRepSpacing.md, vertical: IronRepSpacing.sm),
      decoration: BoxDecoration(
        color: isCompleted ? c.successDim : c.elevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '$setNumber',
              style: TextStyle(
                color: isCompleted ? c.success : c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              typeLabel,
              style: TextStyle(color: c.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: _buildInput(
              context: context,
              controller: weightController,
              hint: previousWeight?.toStringAsFixed(1) ?? 'kg',
              enabled: !isCompleted,
            ),
          ),
          const SizedBox(width: 8),
          Text('×', style: TextStyle(color: c.textMuted)),
          const SizedBox(width: 8),
          Expanded(
            child: _buildInput(
              context: context,
              controller: repsController,
              hint: previousReps?.toString() ?? 'reps',
              enabled: !isCompleted,
              isInt: true,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isCompleted ? Icons.check_circle : Icons.check_circle_outline,
              color: isCompleted ? c.success : c.textMuted,
            ),
            onPressed: isCompleted ? null : onComplete,
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required BuildContext context,
    required TextEditingController controller,
    required String hint,
    required bool enabled,
    bool isInt = false,
  }) {
    final c = AppColors.of(context);
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: isInt
          ? [FilteringTextInputFormatter.digitsOnly]
          : [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
      textAlign: TextAlign.center,
      style: TextStyle(
        color: c.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: c.textMuted, fontSize: 14),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: InputBorder.none,
        filled: false,
      ),
    );
  }
}
