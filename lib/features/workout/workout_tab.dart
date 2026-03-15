import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/app_database.dart';
import '../../providers/plan_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/tap_scale.dart';

class WorkoutTab extends ConsumerWidget {
  const WorkoutTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeWorkout = ref.watch(activeWorkoutProvider);
    final plansAsync = ref.watch(allPlansProvider);
    final userName = ref.watch(userNameProvider);
    final streak = ref.watch(currentStreakProvider);
    final totalWorkouts = ref.watch(totalWorkoutsProvider);
    final workoutsThisWeek = ref.watch(workoutsThisWeekProvider);
    final c = AppColors.of(context);

    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 11
        ? 'Guten Morgen'
        : hour < 17
            ? 'Guten Tag'
            : 'Guten Abend';
    final greeting = userName != null && userName.isNotEmpty
        ? '$greetingPrefix, $userName!'
        : '$greetingPrefix!';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        toolbarHeight: 72,
        title: Text(
          greeting,
          style: TextStyle(
            color: c.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: plansAsync.when(
          data: (plans) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
              children: [
                Row(
                  children: [
                    _StatCard(
                      label: 'Streak',
                      value: '${streak.valueOrNull ?? 0}W',
                      icon: Icons.local_fire_department_outlined,
                      iconColor: c.statIconColor,
                    ),
                    const SizedBox(width: IronRepSpacing.sm),
                    _StatCard(
                      label: 'Workouts',
                      value: totalWorkouts.valueOrNull?.toString() ?? '0',
                      icon: Icons.fitness_center,
                      iconColor: c.statIconColor,
                    ),
                    const SizedBox(width: IronRepSpacing.sm),
                    _StatCard(
                      label: 'Diese Woche',
                      value: workoutsThisWeek.valueOrNull?.toString() ?? '0',
                      icon: Icons.trending_up,
                      iconColor: c.statIconColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Text(
                      'DEINE WORKOUTS',
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: c.border.withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (activeWorkout.isActive) ...[
                  _ResumeCard(
                    planName: activeWorkout.planName,
                    elapsed: activeWorkout.elapsed,
                    isPaused: activeWorkout.isPaused,
                    onTap: () => context.push('/active-workout'),
                    onTogglePause: () => ref
                        .read(activeWorkoutProvider.notifier)
                        .togglePause(),
                  )
                      .animate(onPlay: (c) => c.forward())
                      .shimmer(
                        duration: 2000.ms,
                        delay: 500.ms,
                        color: AppColors.of(context)
                            .accent
                            .withValues(alpha: 0.08),
                      ),
                  const SizedBox(height: 20),
                ],
                ...plans.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _PlanCard(
                        plan: entry.value,
                        isDisabled: activeWorkout.isActive,
                        onTap: () => _showPlanDetail(
                            context, ref, entry.value, activeWorkout.isActive),
                        onPlay: () =>
                            _startPlan(context, ref, entry.value),
                      )
                          .animate()
                          .fadeIn(
                            duration: 400.ms,
                            delay: (100 * entry.key).ms,
                          )
                          .slideY(
                            begin: 0.1,
                            duration: 400.ms,
                            delay: (100 * entry.key).ms,
                            curve: Curves.easeOut,
                          ),
                    )),
                const SizedBox(height: 8),
                TapScale(
                  onTap: () => context.push('/plan-editor'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.border,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add, color: c.textMuted, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Neuer Plan',
                          style: TextStyle(
                            color: c.textMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
    );
  }

  Future<void> _startPlan(
      BuildContext context, WidgetRef ref, TrainingPlan plan) async {
    final notifier = ref.read(activeWorkoutProvider.notifier);
    await notifier.preparePlan(plan.id);
    await notifier.startWorkout(planId: plan.id);
    if (context.mounted) context.push('/active-workout');
  }

  void _showPlanDetail(BuildContext context, WidgetRef ref, TrainingPlan plan,
      bool hasActiveWorkout) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanDetailSheet(
        plan: plan,
        isDisabled: hasActiveWorkout,
        onEdit: () {
          Navigator.pop(context);
          context.push('/plan-editor', extra: plan.id);
        },
        onStart: () {
          Navigator.pop(context);
          _startPlan(context, ref, plan);
        },
      ),
    );
  }
}

class _ResumeCard extends StatelessWidget {
  final String? planName;
  final Duration elapsed;
  final bool isPaused;
  final VoidCallback onTap;
  final VoidCallback onTogglePause;

  const _ResumeCard({
    required this.planName,
    required this.elapsed,
    this.isPaused = false,
    required this.onTap,
    required this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final m = elapsed.inMinutes;
    final s = elapsed.inSeconds % 60;
    final glowColor = isPaused ? c.warning : c.success;

    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: glowColor.withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withValues(alpha: 0.12),
              blurRadius: 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onTogglePause,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      glowColor.withValues(alpha: 0.25),
                      glowColor.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: glowColor,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    planName ?? 'Workout',
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        '${m}m ${s}s',
                        style: TextStyle(
                          color: isPaused ? c.warning : c.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      if (isPaused)
                        Text(
                          ' \u00b7 Pausiert',
                          style: TextStyle(
                            color: c.warning,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          ' \u00b7 Tippe zum Fortsetzen',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: c.textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

String _timeAgo(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(date.year, date.month, date.day);
  final days = today.difference(dateDay).inDays;
  if (days == 0) return 'heute';
  if (days == 1) return 'gestern';
  if (days <= 6) return 'vor $days Tagen';
  if (days <= 27) return 'vor ${days ~/ 7} Wochen';
  return 'vor ${days ~/ 30} Monaten';
}

class _PlanCard extends ConsumerWidget {
  final TrainingPlan plan;
  final bool isDisabled;
  final VoidCallback onTap;
  final VoidCallback onPlay;

  const _PlanCard({
    required this.plan,
    required this.isDisabled,
    required this.onTap,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final exercisesAsync = ref.watch(planExercisesProvider(plan.id));
    final historyAsync = ref.watch(planHistoryProvider(plan.id));
    final completionAsync = ref.watch(planCompletionProvider(plan.id));
    final exerciseCount = exercisesAsync.valueOrNull?.length ?? 0;
    final totalSets = exercisesAsync.valueOrNull
            ?.fold<int>(0, (s, e) => s + e.targetSets) ??
        0;
    final lastWorkout = historyAsync.valueOrNull?.firstOrNull?.completedAt;
    final completion = completionAsync.valueOrNull;

    return TapScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plan.name,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$exerciseCount Übungen · $totalSets Sets',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 1),
                  if (lastWorkout != null)
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: 'Zuletzt ${_timeAgo(lastWorkout)}'),
                          if (completion != null &&
                              completion.done < completion.planned)
                            TextSpan(
                              text:
                                  ' · ${completion.done}/${completion.planned} Übungen',
                              style: TextStyle(color: c.warning),
                            ),
                        ],
                      ),
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            GestureDetector(
              onTap: isDisabled ? null : onPlay,
              behavior: HitTestBehavior.opaque,
              child: Opacity(
                opacity: isDisabled ? 0.4 : 1.0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: c.accent,
                    size: 20,
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

class _PlanDetailSheet extends ConsumerWidget {
  final TrainingPlan plan;
  final bool isDisabled;
  final VoidCallback onEdit;
  final VoidCallback onStart;

  const _PlanDetailSheet({
    required this.plan,
    required this.isDisabled,
    required this.onEdit,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final exerciseNamesAsync = ref.watch(planExerciseNamesProvider(plan.id));
    final historyAsync = ref.watch(planHistoryProvider(plan.id));
    final completionAsync = ref.watch(planCompletionProvider(plan.id));
    final lastWorkout = historyAsync.valueOrNull?.firstOrNull?.completedAt;
    final completion = completionAsync.valueOrNull;
    final exercises = exerciseNamesAsync.valueOrNull ?? [];
    final totalSets = exercises.fold<int>(0, (s, e) => s + e.targetSets);

    return Container(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan.name,
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: onEdit,
                    child: Text(
                      'Bearbeiten',
                      style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Subtitle
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${exercises.length} Übungen · $totalSets Sets'),
                    if (lastWorkout != null)
                      TextSpan(text: ' · Zuletzt ${_timeAgo(lastWorkout)}'),
                    if (completion != null &&
                        completion.done < completion.planned)
                      TextSpan(
                        text: ' · ${completion.done}/${completion.planned}',
                        style: TextStyle(color: c.warning),
                      ),
                  ],
                ),
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              // Exercise list
              if (exerciseNamesAsync.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                ...exercises.map((e) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: c.textMuted,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              e.name,
                              style: TextStyle(
                                color: c.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            '${e.targetSets} Sets',
                            style: TextStyle(
                              color: c.textMuted,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 20),
              // Start button
              TapScale(
                onTap: isDisabled ? null : onStart,
                child: Opacity(
                  opacity: isDisabled ? 0.4 : 1.0,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_arrow_rounded,
                            color: c.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Training starten',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 18),
            const SizedBox(height: 6),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [c.accentGradientStart, c.accentGradientEnd],
              ).createShader(bounds),
              child: Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 500.ms)
          .scale(
              begin: const Offset(0.95, 0.95),
              duration: 500.ms,
              curve: Curves.easeOut),
    );
  }
}
