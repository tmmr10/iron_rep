import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../l10n/enum_labels.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/enums.dart';
import '../../providers/database_provider.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/tap_scale.dart';

class CreateExerciseSheet extends ConsumerStatefulWidget {
  const CreateExerciseSheet({super.key});

  @override
  ConsumerState<CreateExerciseSheet> createState() =>
      _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends ConsumerState<CreateExerciseSheet> {
  final _nameController = TextEditingController();
  MuscleGroup _muscleGroup = MuscleGroup.chest;
  EquipmentType? _equipment;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      final nameKey =
          'custom_${name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

      final id = await db.exerciseDao.insertExercise(
        ExercisesCompanion.insert(
          name: name,
          nameKey: nameKey,
          primaryMuscleGroup: _muscleGroup.name,
          category: 'compound',
          isCustom: const Value(true),
        ),
      );

      if (_equipment != null) {
        await db.exerciseDao.insertEquipment(
          ExerciseEquipmentCompanion.insert(
            exerciseId: id,
            equipmentType: _equipment!.name,
          ),
        );
      }

      if (mounted) {
        Navigator.of(context).pop((id: id, name: name));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.error('$e'))),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final l = context.l10n;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Text(
              l.createNewExercise,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Name
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              style: TextStyle(color: c.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                labelText: l.exerciseName,
                hintText: l.exerciseNameHint,
              ),
            ),
            const SizedBox(height: 20),

            // Muscle Group
            Text(l.muscleGroup,
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
                      m.localizedLabel(context),
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

            // Gerät (optional)
            Text(l.equipmentOptional,
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border.withValues(alpha: 0.3)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EquipmentType?>(
                  value: _equipment,
                  isExpanded: true,
                  menuMaxHeight: 300,
                  dropdownColor: c.card,
                  hint: Text(l.noEquipment,
                      style: TextStyle(color: c.textMuted)),
                  icon:
                      Icon(Icons.keyboard_arrow_down, color: c.textMuted),
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  items: [
                    DropdownMenuItem<EquipmentType?>(
                      value: null,
                      child: Text(l.noEquipment,
                          style: TextStyle(color: c.textMuted)),
                    ),
                    ...EquipmentType.values.map((eq) {
                      return DropdownMenuItem<EquipmentType?>(
                        value: eq,
                        child: Text(eq.localizedLabel(context)),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _equipment = v),
                ),
              ),
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
                          l.createExercise,
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
          ],
        ),
      ),
    );
  }
}
