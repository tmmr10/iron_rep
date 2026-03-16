import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/enums.dart';
import '../../models/exercise.dart';
import '../../providers/database_provider.dart';
import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/tap_scale.dart';

class EditExerciseSheet extends ConsumerStatefulWidget {
  final ExerciseWithEquipment exercise;
  final ScrollController? scrollController;

  const EditExerciseSheet({
    super.key,
    required this.exercise,
    this.scrollController,
  });

  @override
  ConsumerState<EditExerciseSheet> createState() => _EditExerciseSheetState();
}

class _EditExerciseSheetState extends ConsumerState<EditExerciseSheet> {
  late final TextEditingController _nameController;
  late final TextEditingController _instructionsController;
  late MuscleGroup _muscleGroup;
  late ExerciseCategory _category;
  late Set<EquipmentType> _equipment;
  late bool _trackWeight;
  bool _saving = false;

  bool get _hasChanges {
    return _nameController.text.trim() != widget.exercise.name ||
        (_instructionsController.text.trim()) !=
            (widget.exercise.instructions ?? '') ||
        _muscleGroup != widget.exercise.muscleGroup ||
        _category != widget.exercise.category ||
        _trackWeight != widget.exercise.trackWeight ||
        !_setEquals(_equipment, widget.exercise.equipment.toSet());
  }

  bool _setEquals(Set<EquipmentType> a, Set<EquipmentType> b) {
    return a.length == b.length && a.containsAll(b);
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final c = AppColors.of(ctx);
        return AlertDialog(
          backgroundColor: c.surface,
          title: Text('Änderungen verwerfen?',
              style: TextStyle(color: c.textPrimary)),
          content: Text('Deine Änderungen gehen verloren.',
              style: TextStyle(color: c.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Weiter bearbeiten'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Verwerfen', style: TextStyle(color: c.error)),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.exercise.name);
    _instructionsController =
        TextEditingController(text: widget.exercise.instructions ?? '');
    _muscleGroup = widget.exercise.muscleGroup;
    _category = widget.exercise.category;
    _equipment = widget.exercise.equipment.toSet();
    _trackWeight = widget.exercise.trackWeight;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      final instructions = _instructionsController.text.trim();

      await db.exerciseDao.updateExercise(
        widget.exercise.id,
        name: name,
        primaryMuscleGroup: _muscleGroup.name,
        category: _category.name,
        instructions:
            instructions.isEmpty ? const Value(null) : Value(instructions),
        trackWeight: _trackWeight,
      );

      await db.exerciseDao.replaceEquipment(
        widget.exercise.id,
        _equipment.map((e) => e.name).toList(),
      );

      if (mounted) {
        ref.invalidate(exerciseWithEquipmentProvider(widget.exercise.id));
        ref.invalidate(allExercisesProvider);
        ref.invalidate(filteredExercisesProvider);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) Navigator.of(context).pop();
      },
      child: ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.textMuted,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Text(
                'Übung bearbeiten',
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GestureDetector(
              onTap: () async {
                final shouldPop = await _confirmDiscard();
                if (shouldPop && mounted) Navigator.of(context).pop();
              },
              child: Icon(Icons.close, color: c.textMuted, size: 24),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Name
        Text('Name der Übung',
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            style: TextStyle(color: c.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Name eingeben',
              hintStyle: TextStyle(color: c.textMuted),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Track weight toggle
        Row(
          children: [
            Expanded(
              child: Text(
                'Gewicht erfassen',
                style: TextStyle(color: c.textPrimary, fontSize: 15),
              ),
            ),
            Switch.adaptive(
              value: _trackWeight,
              activeTrackColor: c.accent,
              onChanged: (v) => setState(() => _trackWeight = v),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Instructions
        Text('Anleitung (optional)',
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.border.withValues(alpha: 0.3)),
          ),
          child: TextField(
            controller: _instructionsController,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 3,
            style: TextStyle(color: c.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Ausführung beschreiben',
              hintStyle: TextStyle(color: c.textMuted),
              contentPadding: EdgeInsets.zero,
              isDense: true,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Muscle Group
        Text('Muskelgruppe',
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: MuscleGroup.values.map((m) {
            final selected = m == _muscleGroup;
            return GestureDetector(
              onTap: () => setState(() => _muscleGroup = m),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: selected
                      ? m.color.withValues(alpha: 0.2)
                      : c.elevated,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? m.color
                        : c.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  m.label,
                  style: TextStyle(
                    color: selected ? m.color : c.textSecondary,
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Category
        Text('Kategorie',
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ExerciseCategory.values.map((cat) {
            final selected = cat == _category;
            return ChoiceChip(
              label: Text(cat.label),
              selected: selected,
              onSelected: (_) => setState(() => _category = cat),
              selectedColor: c.accent.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: selected ? c.accent : c.textSecondary,
              ),
              side: BorderSide(
                color: selected
                    ? c.accent
                    : c.border.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // Equipment (Multi-Select)
        Text('Geräte',
            style: TextStyle(color: c.textSecondary, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: EquipmentType.values.map((eq) {
            final selected = _equipment.contains(eq);
            return FilterChip(
              label: Text(eq.label),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v) {
                    _equipment.add(eq);
                  } else {
                    _equipment.remove(eq);
                  }
                });
              },
              selectedColor: c.accent.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: selected ? c.accent : c.textSecondary,
              ),
              side: BorderSide(
                color: selected
                    ? c.accent
                    : c.border.withValues(alpha: 0.3),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),

        // Save button
        TapScale(
          onTap: _saving || _nameController.text.trim().isEmpty
              ? null
              : () => _save(),
          child: Opacity(
            opacity: _saving || _nameController.text.trim().isEmpty ? 0.5 : 1.0,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: c.accent.withValues(alpha: 0.3),
                ),
              ),
              child: _saving
                  ? Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.accent,
                        ),
                      ),
                    )
                  : Text(
                      'Speichern',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    ),
    );
  }
}
