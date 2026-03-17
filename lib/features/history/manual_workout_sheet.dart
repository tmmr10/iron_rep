import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_provider.dart';
import '../../providers/plan_providers.dart';
import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import '../../database/app_database.dart';
import 'package:drift/drift.dart' hide Column;

import '../../l10n/l10n_helper.dart';

class ManualWorkoutSheet extends ConsumerStatefulWidget {
  const ManualWorkoutSheet({super.key});

  @override
  ConsumerState<ManualWorkoutSheet> createState() => _ManualWorkoutSheetState();
}

class _ManualWorkoutSheetState extends ConsumerState<ManualWorkoutSheet> {
  late final TextEditingController _nameController;
  late DateTime _date;
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  int _durationMinutes = 60;
  bool _saving = false;
  int? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_nameInitialized) {
      _nameController = TextEditingController(text: context.l10n.defaultWorkoutName);
      _nameInitialized = true;
    }
  }

  bool _nameInitialized = false;

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
              planId: Value(_selectedPlanId),
              isActive: const Value(false),
              completedAt: Value(completedAt),
              durationSeconds: Value(durationSeconds),
            ),
          );

      // Insert plan exercises into the workout
      if (_selectedPlanId != null) {
        final planExercises =
            await db.planDao.getPlanExercises(_selectedPlanId!);
        for (var i = 0; i < planExercises.length; i++) {
          await db.into(db.workoutExercises).insert(
                WorkoutExercisesCompanion.insert(
                  workoutId: workoutId,
                  exerciseId: planExercises[i].exerciseId,
                  sortOrder: i,
                ),
              );
        }
      }

      if (mounted) {
        ref.invalidate(workoutHistoryProvider);
        ref.invalidate(enrichedWorkoutHistoryProvider);
        Navigator.of(context).pop(workoutId);
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
              context.l10n.logManualWorkout,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Plan (optional)
            Text(context.l10n.trainingPlanOptional,
                style: TextStyle(color: c.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            Consumer(builder: (context, ref, _) {
              final plansAsync = ref.watch(allPlansProvider);
              return plansAsync.when(
                data: (plans) {
                  if (plans.isEmpty) return const SizedBox.shrink();
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: c.card,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: c.border.withValues(alpha: 0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int?>(
                        value: _selectedPlanId,
                        isExpanded: true,
                        menuMaxHeight: 300,
                        dropdownColor: c.card,
                        hint: Text(context.l10n.noPlan,
                            style: TextStyle(color: c.textMuted)),
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: c.textMuted),
                        style:
                            TextStyle(color: c.textPrimary, fontSize: 15),
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(context.l10n.noPlan,
                                style: TextStyle(color: c.textMuted)),
                          ),
                          ...plans.map((p) => DropdownMenuItem<int?>(
                                value: p.id,
                                child: Text(p.name),
                              )),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedPlanId = v;
                            if (v != null) {
                              final plan =
                                  plans.firstWhere((p) => p.id == v);
                              _nameController.text = plan.name;
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              );
            }),
            const SizedBox(height: 16),

            // Name
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.name,
                hintText: context.l10n.workoutNameHint,
              ),
            ),
            const SizedBox(height: 16),

            // Date
            GestureDetector(
              onTap: _pickDate,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: context.l10n.dateLabel,
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
                decoration: InputDecoration(
                  labelText: context.l10n.startTime,
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
            Text(context.l10n.durationMinutes(_durationMinutes),
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
              _selectedPlanId != null
                  ? context.l10n.planExercisesAutoImport
                  : context.l10n.manualExercisesAddLater,
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
                  : Text(
                      context.l10n.createWorkout,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
