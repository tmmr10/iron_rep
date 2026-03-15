import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import '../../database/app_database.dart';
import 'package:drift/drift.dart' hide Column;

class ManualWorkoutSheet extends ConsumerStatefulWidget {
  const ManualWorkoutSheet({super.key});

  @override
  ConsumerState<ManualWorkoutSheet> createState() => _ManualWorkoutSheetState();
}

class _ManualWorkoutSheetState extends ConsumerState<ManualWorkoutSheet> {
  final _nameController = TextEditingController(text: 'Workout');
  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  int _durationMinutes = 60;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _saving = true);

    try {
      final db = ref.read(databaseProvider);
      final startedAt = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _startTime.hour,
        _startTime.minute,
      );
      final completedAt =
          startedAt.add(Duration(minutes: _durationMinutes));
      final durationSeconds = _durationMinutes * 60;

      final workoutId = await db.into(db.workouts).insert(
            WorkoutsCompanion.insert(
              startedAt: startedAt,
              name: Value(name),
              isActive: const Value(false),
              completedAt: Value(completedAt),
              durationSeconds: Value(durationSeconds),
            ),
          );

      if (mounted) {
        ref.invalidate(workoutHistoryProvider);
        ref.invalidate(enrichedWorkoutHistoryProvider);
        Navigator.of(context).pop(workoutId);
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
              'Training manuell eintragen',
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
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'z.B. Oberkörper',
              ),
            ),
            const SizedBox(height: 16),

            // Date
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Datum',
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: c.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_date.day}.${_date.month}.${_date.year}',
                      style: TextStyle(color: c.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Start time
            GestureDetector(
              onTap: _pickStartTime,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Startzeit',
                ),
                child: Row(
                  children: [
                    Icon(Icons.access_time, color: c.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(color: c.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Duration
            Text('Dauer: $_durationMinutes Minuten',
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            Slider(
              value: _durationMinutes.toDouble(),
              min: 10,
              max: 180,
              divisions: 34,
              activeColor: c.accent,
              label: '$_durationMinutes min',
              onChanged: (v) =>
                  setState(() => _durationMinutes = v.round()),
            ),
            const SizedBox(height: 12),

            Text(
              'Du kannst nach dem Anlegen Übungen und Sets über den Edit-Modus hinzufügen.',
              style: TextStyle(color: c.textMuted, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Save
            FilledButton(
              onPressed: _saving ? null : _save,
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
                      'Training anlegen',
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
