import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../providers/database_provider.dart';
import '../../shared/design_system.dart';

class CreateExerciseSheet extends ConsumerStatefulWidget {
  const CreateExerciseSheet({super.key});

  @override
  ConsumerState<CreateExerciseSheet> createState() =>
      _CreateExerciseSheetState();
}

class _CreateExerciseSheetState extends ConsumerState<CreateExerciseSheet> {
  final _nameController = TextEditingController();
  MuscleGroup _muscleGroup = MuscleGroup.chest;
  ExerciseCategory _category = ExerciseCategory.compound;
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
          category: _category.name,
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
          SnackBar(content: Text('Fehler: $e')),
        );
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

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
              'Neue Übung erstellen',
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
              decoration: const InputDecoration(
                labelText: 'Name der Übung',
                hintText: 'z.B. Kurzhantel Seitheben',
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
                            : c.border.withValues(alpha: 0.5),
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
                        : c.border.withValues(alpha: 0.5),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // Gerät (optional)
            Text('Gerät (optional)',
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: c.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border.withValues(alpha: 0.5)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<EquipmentType?>(
                  value: _equipment,
                  isExpanded: true,
                  dropdownColor: c.card,
                  hint: Text('Kein Gerät',
                      style: TextStyle(color: c.textMuted)),
                  icon:
                      Icon(Icons.keyboard_arrow_down, color: c.textMuted),
                  style: TextStyle(color: c.textPrimary, fontSize: 15),
                  items: [
                    DropdownMenuItem<EquipmentType?>(
                      value: null,
                      child: Text('Kein Gerät',
                          style: TextStyle(color: c.textMuted)),
                    ),
                    ...EquipmentType.values.map((eq) {
                      return DropdownMenuItem<EquipmentType?>(
                        value: eq,
                        child: Text(eq.label),
                      );
                    }),
                  ],
                  onChanged: (v) => setState(() => _equipment = v),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Save button
            FilledButton(
              onPressed: _saving || _nameController.text.trim().isEmpty
                  ? null
                  : _save,
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.background,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Übung erstellen',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
