import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/workout_providers.dart';
import '../../providers/timer_providers.dart';
import '../../providers/database_provider.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/tap_scale.dart';

final previousSetsProvider = FutureProvider.family<
    List<WorkoutSet>, ({int exerciseId, int workoutId})>((ref, params) {
  final db = ref.watch(databaseProvider);
  return db.workoutDao
      .getPreviousSetsForExercise(params.exerciseId, params.workoutId);
});

class SetLoggerCard extends ConsumerStatefulWidget {
  final WorkoutExercise workoutExercise;
  final int workoutId;
  final bool initiallyExpanded;

  const SetLoggerCard({
    super.key,
    required this.workoutExercise,
    required this.workoutId,
    this.initiallyExpanded = false,
  });

  @override
  ConsumerState<SetLoggerCard> createState() => _SetLoggerCardState();
}

class _SetLoggerCardState extends ConsumerState<SetLoggerCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final setsAsync =
        ref.watch(setsForWorkoutExerciseProvider(widget.workoutExercise.id));
    final allExercises = ref.watch(allExercisesProvider);
    final previousSetsAsync = ref.watch(previousSetsProvider((
      exerciseId: widget.workoutExercise.exerciseId,
      workoutId: widget.workoutId,
    )));

    final exerciseData = allExercises.whenOrNull(
      data: (list) {
        final e =
            list.where((e) => e.id == widget.workoutExercise.exerciseId);
        return e.isNotEmpty ? e.first : null;
      },
    );
    final exerciseName = exerciseData?.name ?? 'Exercise';
    final muscleGroup = exerciseData != null
        ? MuscleGroup.values.firstWhere(
            (m) => m.name == exerciseData.primaryMuscleGroup,
            orElse: () => MuscleGroup.chest,
          )
        : null;

    final previousSets = previousSetsAsync.valueOrNull ?? [];

    return setsAsync.when(
      data: (sets) {
        final completedCount = sets.where((s) => s.isCompleted).length;
        final totalCount = sets.length;
        final allDone = completedCount == totalCount && totalCount > 0;

        String? lastInfo;
        if (previousSets.isNotEmpty) {
          final bestWeight = previousSets
              .where((s) => s.weight != null)
              .map((s) => s.weight!)
              .fold<double>(0, (a, b) => a > b ? a : b);
          if (bestWeight > 0) {
            lastInfo = '${bestWeight.toStringAsFixed(0)} kg';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TapScale(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    if (muscleGroup != null) ...[
                      Container(
                        width: 3,
                        height: 20,
                        decoration: BoxDecoration(
                          color: allDone ? c.success : muscleGroup.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        exerciseName,
                        style: TextStyle(
                          color: allDone ? c.success : c.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (!_isExpanded) ...[
                      if (completedCount > 0)
                        Text(
                          '$completedCount/$totalCount',
                          style: TextStyle(
                            color: allDone ? c.success : c.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else if (lastInfo != null)
                        Text(
                          lastInfo,
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: c.textMuted,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (_isExpanded) ...[
              const SizedBox(height: 4),
              ...sets.asMap().entries.map((entry) {
                final index = entry.key;
                final s = entry.value;
                final prevSet =
                    index < previousSets.length ? previousSets[index] : null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Dismissible(
                    key: ValueKey('set_${s.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: c.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child:
                          Icon(Icons.delete_outline, color: c.error, size: 20),
                    ),
                    onDismissed: (_) => ref
                        .read(activeWorkoutProvider.notifier)
                        .deleteSet(s.id),
                    child: _SetRow(
                      set_: s,
                      previousSet: prevSet,
                      workoutExerciseId: widget.workoutExercise.id,
                      exerciseId: widget.workoutExercise.exerciseId,
                      workoutId: widget.workoutId,
                    ),
                  ),
                );
              }),
              TapScale(
                onTap: () => ref
                    .read(activeWorkoutProvider.notifier)
                    .addSet(widget.workoutExercise.id),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, size: 14, color: c.textMuted),
                      const SizedBox(width: 4),
                      Text('Set hinzufügen',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
      loading: () => const SizedBox(height: 40),
      error: (e, _) => Text('Error: $e'),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final WorkoutSet set_;
  final WorkoutSet? previousSet;
  final int workoutExerciseId;
  final int exerciseId;
  final int workoutId;

  const _SetRow({
    required this.set_,
    this.previousSet,
    required this.workoutExerciseId,
    required this.exerciseId,
    required this.workoutId,
  });

  @override
  ConsumerState<_SetRow> createState() => _SetRowState();
}

class _SetRowState extends ConsumerState<_SetRow> {
  late final TextEditingController _weightCtrl;
  late final TextEditingController _repsCtrl;

  @override
  void initState() {
    super.initState();
    final w = widget.set_.weight ?? widget.previousSet?.weight;
    final r = widget.set_.reps ?? widget.previousSet?.reps;
    _weightCtrl =
        TextEditingController(text: w != null ? w.toStringAsFixed(1) : '');
    _repsCtrl = TextEditingController(text: r != null ? '$r' : '');

    if (widget.set_.weight == null && w != null ||
        widget.set_.reps == null && r != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeWorkoutProvider.notifier).updateSet(
              widget.set_.id,
              weight: w,
              reps: r?.toInt(),
            );
      });
    }
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  String? get _prevWeightHint {
    final pw = widget.previousSet?.weight;
    return pw != null ? pw.toStringAsFixed(1) : null;
  }

  String? get _prevRepsHint {
    final pr = widget.previousSet?.reps;
    return pr != null ? '$pr' : null;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final s = widget.set_;
    final isCompleted = s.isCompleted;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? c.success.withValues(alpha: 0.08)
            : c.surface,
        borderRadius: BorderRadius.circular(10),
        border: isCompleted
            ? Border.all(color: c.success.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${s.setNumber}',
              style: TextStyle(
                color: isCompleted ? c.success : c.textMuted,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: _CompactInput(
              controller: _weightCtrl,
              enabled: !isCompleted,
              hint: _prevWeightHint ?? '–',
              suffix: 'kg',
              decimal: true,
              onChanged: (v) {
                ref.read(activeWorkoutProvider.notifier).updateSet(
                      s.id,
                      weight: double.tryParse(v),
                      reps: int.tryParse(_repsCtrl.text),
                    );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CompactInput(
              controller: _repsCtrl,
              enabled: !isCompleted,
              hint: _prevRepsHint ?? '–',
              suffix: 'reps',
              decimal: false,
              onChanged: (v) {
                ref.read(activeWorkoutProvider.notifier).updateSet(
                      s.id,
                      weight: double.tryParse(_weightCtrl.text),
                      reps: int.tryParse(v),
                    );
              },
            ),
          ),
          const SizedBox(width: 8),
          TapScale(
            onTap: isCompleted
                ? () async {
                    await ref
                        .read(activeWorkoutProvider.notifier)
                        .uncompleteSet(s.id);
                    HapticFeedback.lightImpact();
                  }
                : () async {
                    var w = double.tryParse(_weightCtrl.text);
                    var r = int.tryParse(_repsCtrl.text);
                    if (w == null && widget.previousSet?.weight != null) {
                      w = widget.previousSet!.weight!;
                      _weightCtrl.text = w.toStringAsFixed(1);
                    }
                    if (r == null && widget.previousSet?.reps != null) {
                      r = widget.previousSet!.reps!;
                      _repsCtrl.text = '$r';
                    }
                    if (w != null || r != null) {
                      await ref
                          .read(activeWorkoutProvider.notifier)
                          .updateSet(s.id, weight: w, reps: r);
                    }
                    await ref
                        .read(activeWorkoutProvider.notifier)
                        .completeSet(s.id);
                    HapticFeedback.mediumImpact();
                    final restSeconds =
                        await ref.read(defaultRestSecondsProvider.future);
                    ref.read(restTimerProvider.notifier).start(restSeconds);
                  },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? c.success : Colors.transparent,
                border: isCompleted ? null : Border.all(color: c.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.check_rounded,
                size: 18,
                color: isCompleted ? Colors.white : c.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactInput extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final String hint;
  final String suffix;
  final bool decimal;
  final ValueChanged<String> onChanged;

  const _CompactInput({
    required this.controller,
    required this.enabled,
    required this.hint,
    required this.suffix,
    required this.decimal,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            enabled: enabled,
            keyboardType: decimal
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.number,
            inputFormatters:
                decimal ? null : [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.right,
            style: TextStyle(
              color: c.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: c.textMuted,
                fontWeight: FontWeight.w400,
              ),
              isDense: true,
              filled: false,
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          suffix,
          style: TextStyle(color: c.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
