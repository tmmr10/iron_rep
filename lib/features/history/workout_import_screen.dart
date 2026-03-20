import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/database_provider.dart';
import '../../providers/workout_providers.dart';
import '../../services/plan_sharing_service.dart';
import '../../services/workout_sharing_service.dart';
import '../../shared/design_system.dart';
import '../../l10n/l10n_helper.dart';
import '../../shared/widgets/tap_scale.dart';

class WorkoutImportScreen extends ConsumerStatefulWidget {
  final SharedWorkout workout;

  const WorkoutImportScreen({super.key, required this.workout});

  @override
  ConsumerState<WorkoutImportScreen> createState() =>
      _WorkoutImportScreenState();
}

class _WorkoutImportScreenState extends ConsumerState<WorkoutImportScreen> {
  List<MatchedWorkoutExercise>? _matched;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _matchExercises();
  }

  Future<void> _matchExercises() async {
    final db = ref.read(databaseProvider);
    final matched =
        await WorkoutSharingService.matchExercises(db, widget.workout);
    if (mounted) setState(() => _matched = matched);
  }

  Future<void> _import() async {
    setState(() => _isImporting = true);
    final db = ref.read(databaseProvider);
    await WorkoutSharingService.importWorkout(db, widget.workout);
    ref.invalidate(workoutHistoryProvider);
    ref.invalidate(enrichedWorkoutHistoryProvider);
    if (mounted) context.go('/history');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final w = widget.workout;

    // Summary stats
    final totalSets =
        w.exercises.fold<int>(0, (sum, ex) => sum + ex.sets.length);
    final totalVolume = w.exercises.fold<double>(
        0,
        (sum, ex) =>
            sum +
            ex.sets.fold<double>(
                0, (s, set_) => s + (set_.weight ?? 0) * (set_.reps ?? 0)));
    final durationStr = w.durationSeconds != null
        ? '${w.durationSeconds! ~/ 60}m ${w.durationSeconds! % 60}s'
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.importWorkout),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/history');
            }
          },
        ),
      ),
      body: _matched == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      // Workout name headline
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [c.accent, c.accent.withValues(alpha: 0.7)],
                        ).createShader(bounds),
                        child: Text(
                          w.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
                      const SizedBox(height: 8),
                      // Summary row
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          _SummaryChip(
                            icon: Icons.fitness_center,
                            label:
                                '${w.exercises.length} ${context.l10n.exercises}',
                            colors: c,
                          ),
                          _SummaryChip(
                            icon: Icons.repeat,
                            label: '$totalSets ${context.l10n.sets}',
                            colors: c,
                          ),
                          _SummaryChip(
                            icon: Icons.monitor_weight_outlined,
                            label: '${totalVolume.round()} kg',
                            colors: c,
                          ),
                          if (durationStr != null)
                            _SummaryChip(
                              icon: Icons.timer_outlined,
                              label: durationStr,
                              colors: c,
                            ),
                        ],
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 24),
                      // Exercise list with sets
                      ...List.generate(_matched!.length, (i) {
                        final m = _matched![i];
                        final isCustom =
                            m.status == ExerciseMatchStatus.createdCustom;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.border.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: c.accent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${i + 1}',
                                      style: TextStyle(
                                        color: c.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m.displayName,
                                          style: TextStyle(
                                            color: c.textPrimary,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 15,
                                          ),
                                        ),
                                        if (isCustom)
                                          Text(
                                            context.l10n.customExerciseCreated,
                                            style: TextStyle(
                                              color: c.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (m.source.sets.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...m.source.sets.asMap().entries.map((entry) {
                                  final j = entry.key + 1;
                                  final s = entry.value;
                                  final weight = s.weight != null
                                      ? '${_fmtWeight(s.weight!)} kg'
                                      : '-';
                                  final reps = s.reps != null
                                      ? '${s.reps} reps'
                                      : '-';
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        left: 40, bottom: 2),
                                    child: Text(
                                      '$j. $weight × $reps',
                                      style: TextStyle(
                                        color: c.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(
                              delay: Duration(milliseconds: 50 * i),
                              duration: 200.ms,
                            );
                      }),
                    ],
                  ),
                ),
                // Import button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    child: TapScale(
                      onTap: _isImporting ? null : _import,
                      child: Opacity(
                        opacity: _isImporting ? 0.5 : 1.0,
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
                          child: _isImporting
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
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.download_rounded,
                                        color: c.accent, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.l10n.importWorkout,
                                      style: TextStyle(
                                        color: c.accent,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

String _fmtWeight(double w) =>
    (w - w.roundToDouble()).abs() < 0.01 ? '${w.round()}' : w.toStringAsFixed(1);

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;

  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: colors.textMuted, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
