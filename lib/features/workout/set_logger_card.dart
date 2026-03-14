import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/workout_providers.dart';
import '../../providers/timer_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/iron_card.dart';

class SetLoggerCard extends ConsumerWidget {
  final WorkoutExercise workoutExercise;
  final int workoutId;

  const SetLoggerCard({
    super.key,
    required this.workoutExercise,
    required this.workoutId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync =
        ref.watch(setsForWorkoutExerciseProvider(workoutExercise.id));
    final allExercises = ref.watch(allExercisesProvider);
    final exerciseName = allExercises.whenOrNull(
      data: (list) {
        final e = list.where((e) => e.id == workoutExercise.exerciseId);
        return e.isNotEmpty ? e.first.name : 'Exercise';
      },
    ) ?? 'Exercise';

    return IronCard(
      padding: const EdgeInsets.all(IronRepSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  exerciseName,
                  style: const TextStyle(
                    color: IronRepColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: IronRepColors.error, size: 20),
                onPressed: () => ref
                    .read(activeWorkoutProvider.notifier)
                    .removeExercise(workoutExercise.id),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Header row
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                SizedBox(width: 40, child: Text('SET',
                    style: TextStyle(color: IronRepColors.textMuted, fontSize: 11))),
                SizedBox(width: 48),
                Expanded(child: Center(child: Text('KG',
                    style: TextStyle(color: IronRepColors.textMuted, fontSize: 11)))),
                SizedBox(width: 8),
                SizedBox(width: 14),
                SizedBox(width: 8),
                Expanded(child: Center(child: Text('REPS',
                    style: TextStyle(color: IronRepColors.textMuted, fontSize: 11)))),
                SizedBox(width: 48),
              ],
            ),
          ),
          const SizedBox(height: 4),
          setsAsync.when(
            data: (sets) => Column(
              children: [
                ...sets.map((s) => Padding(
                      padding:
                          const EdgeInsets.only(bottom: IronRepSpacing.xs),
                      child: _SetRow(
                        set_: s,
                        workoutExerciseId: workoutExercise.id,
                        exerciseId: workoutExercise.exerciseId,
                        workoutId: workoutId,
                      ),
                    )),
                TextButton.icon(
                  onPressed: () => ref
                      .read(activeWorkoutProvider.notifier)
                      .addSet(workoutExercise.id),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Set'),
                  style: TextButton.styleFrom(
                    foregroundColor: IronRepColors.accent,
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(height: 40),
            error: (e, _) => Text('Error: $e'),
          ),
        ],
      ),
    );
  }
}

class _SetRow extends ConsumerStatefulWidget {
  final WorkoutSet set_;
  final int workoutExerciseId;
  final int exerciseId;
  final int workoutId;

  const _SetRow({
    required this.set_,
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
    _weightCtrl = TextEditingController(
        text: widget.set_.weight?.toStringAsFixed(1) ?? '');
    _repsCtrl = TextEditingController(
        text: widget.set_.reps?.toString() ?? '');
  }

  @override
  void dispose() {
    _weightCtrl.dispose();
    _repsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.set_;
    final isCompleted = s.isCompleted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isCompleted ? IronRepColors.successDim : IronRepColors.elevated,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              '${s.setNumber}',
              style: TextStyle(
                color: isCompleted
                    ? IronRepColors.success
                    : IronRepColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              SetType.values
                  .firstWhere((t) => t.name == s.setType,
                      orElse: () => SetType.working)
                  .label,
              style: const TextStyle(
                  color: IronRepColors.textMuted, fontSize: 11),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _weightCtrl,
              enabled: !isCompleted,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: IronRepColors.textPrimary,
                  fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'kg',
                isDense: true,
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              ),
              onChanged: (v) {
                final w = double.tryParse(v);
                ref.read(activeWorkoutProvider.notifier).updateSet(
                      s.id,
                      weight: w,
                      reps: int.tryParse(_repsCtrl.text),
                    );
              },
            ),
          ),
          const Text('×',
              style: TextStyle(color: IronRepColors.textMuted)),
          Expanded(
            child: TextField(
              controller: _repsCtrl,
              enabled: !isCompleted,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: IronRepColors.textPrimary,
                  fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'reps',
                isDense: true,
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              ),
              onChanged: (v) {
                final r = int.tryParse(v);
                ref.read(activeWorkoutProvider.notifier).updateSet(
                      s.id,
                      weight: double.tryParse(_weightCtrl.text),
                      reps: r,
                    );
              },
            ),
          ),
          IconButton(
            icon: Icon(
              isCompleted
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
              color: isCompleted
                  ? IronRepColors.success
                  : IronRepColors.textMuted,
            ),
            onPressed: isCompleted
                ? null
                : () async {
                    // Save values first
                    final w = double.tryParse(_weightCtrl.text);
                    final r = int.tryParse(_repsCtrl.text);
                    if (w != null) {
                      await ref
                          .read(activeWorkoutProvider.notifier)
                          .updateSet(s.id, weight: w, reps: r);
                    }
                    await ref
                        .read(activeWorkoutProvider.notifier)
                        .completeSet(s.id);
                    HapticFeedback.mediumImpact();

                    // Start rest timer
                    final restSeconds = await ref
                        .read(defaultRestSecondsProvider.future);
                    ref
                        .read(restTimerProvider.notifier)
                        .start(restSeconds);
                  },
          ),
        ],
      ),
    );
  }
}
