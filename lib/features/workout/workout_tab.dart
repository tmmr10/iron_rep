import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/app_database.dart';
import '../../providers/plan_providers.dart';
import '../../services/plan_sharing_service.dart';
import '../../providers/settings_providers.dart';
import '../../providers/stats_providers.dart';
import '../../providers/workout_providers.dart';
import '../../shared/design_system.dart';
import '../../l10n/l10n_helper.dart';
import '../../shared/widgets/section_header.dart';
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
    final totalVolume = ref.watch(totalVolumeProvider);
    final avgDuration = ref.watch(avgWorkoutDurationProvider);
    final c = AppColors.of(context);

    final hour = DateTime.now().hour;
    final greetingPrefix = hour < 11
        ? context.l10n.greetingMorning
        : hour < 17
            ? context.l10n.greetingAfternoon
            : context.l10n.greetingEvening;
    final hasName = userName != null && userName.isNotEmpty;

    final weekCount = workoutsThisWeek.valueOrNull ?? 0;
    final streakVal = streak.valueOrNull ?? 0;
    final subline = _motivationalSubline(context, hour, weekCount, streakVal);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$greetingPrefix${hasName ? ', ' : ''}',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasName)
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [c.accentGradientStart, c.accentGradientEnd],
                          ).createShader(bounds),
                          child: Text(
                            userName!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subline,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: plansAsync.when(
                data: (plans) {
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                    children: [
                SectionHeader(title: context.l10n.yourStats),
                Row(
                  children: [
                    _StatCard(
                      label: context.l10n.streak,
                      value: '${streak.valueOrNull ?? 0}W',
                      icon: Icons.local_fire_department_outlined,
                      iconColor: c.statIconColor,
                    ),
                    const SizedBox(width: IronRepSpacing.sm),
                    _StatCard(
                      label: context.l10n.workouts,
                      value: totalWorkouts.valueOrNull?.toString() ?? '0',
                      icon: Icons.fitness_center,
                      iconColor: c.statIconColor,
                    ),
                    const SizedBox(width: IronRepSpacing.sm),
                    _StatCard(
                      label: context.l10n.thisWeek,
                      value: workoutsThisWeek.valueOrNull?.toString() ?? '0',
                      icon: Icons.trending_up,
                      iconColor: c.statIconColor,
                    ),
                  ],
                ),
                const SizedBox(height: IronRepSpacing.sm),
                Row(
                  children: [
                    _StatCard(
                      label: context.l10n.volume,
                      value: _formatVolume(totalVolume.valueOrNull ?? 0),
                      icon: Icons.monitor_weight_outlined,
                      iconColor: c.statIconColor,
                    ),
                    const SizedBox(width: IronRepSpacing.sm),
                    _StatCard(
                      label: context.l10n.avgDuration,
                      value: _formatDuration(avgDuration.valueOrNull ?? 0),
                      icon: Icons.timer_outlined,
                      iconColor: c.statIconColor,
                    ),
                    const SizedBox(width: IronRepSpacing.sm),
                    _StatCard(
                      label: context.l10n.prs,
                      value: ref.watch(totalPRsProvider).valueOrNull?.toString() ?? '0',
                      icon: Icons.emoji_events_outlined,
                      iconColor: c.statIconColor,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SectionHeader(title: context.l10n.yourWorkouts),
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
                if (plans.isEmpty) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.fitness_center,
                            color: c.textMuted, size: 40),
                        const SizedBox(height: 16),
                        Text(
                          context.l10n.createFirstPlanTitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.l10n.createFirstPlanSubtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TapScale(
                          onTap: () => context.push('/plan-editor'),
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
                                Icon(Icons.add, color: c.accent, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  context.l10n.createPlan,
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
                      ],
                    ),
                  ),
                ] else ...[
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
                      child: Center(
                        child: Text(
                          context.l10n.newPlan,
                          style: TextStyle(
                            color: c.textMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(child: Text(context.l10n.error(e.toString()))),
                ),
              ),
            ],
          ),
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
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanDetailSheet(
        plan: plan,
        isDisabled: hasActiveWorkout,
        onEdit: () {
          Navigator.of(context, rootNavigator: true).pop();
          context.push('/plan-editor', extra: plan.id);
        },
        onStart: () {
          Navigator.of(context, rootNavigator: true).pop();
          _startPlan(context, ref, plan);
        },
      ),
    );
  }
}

String _formatVolume(double volume) {
  if (volume >= 1000000) return '${(volume / 1000000).toStringAsFixed(1)}M';
  if (volume >= 1000) return '${(volume / 1000).toStringAsFixed(1)}k';
  return volume.round().toString();
}

String _formatDuration(int seconds) {
  if (seconds <= 0) return '--';
  final minutes = seconds ~/ 60;
  return '${minutes}m';
}

String _motivationalSubline(BuildContext context, int hour, int weekCount, int streakWeeks) {
  final l = context.l10n;
  // Use day-of-year as seed for daily rotation
  final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;

  // --- Streak-based (highest priority) ---
  if (streakWeeks >= 4) {
    final lines = [
      l.motivationStrongStreak1,
      l.streakWeeksMotivation(streakWeeks),
      l.motivationStrongStreak3,
    ];
    return lines[dayOfYear % lines.length];
  }
  if (streakWeeks >= 2) {
    final lines = [
      l.motivationStreakRunning1,
      l.motivationStreakRunning2,
    ];
    return lines[dayOfYear % lines.length];
  }

  // --- Week progress based ---
  if (weekCount >= 4) {
    final lines = [
      l.motivationWeekGreat1,
      l.motivationWeekGreat2,
      l.motivationWeekGreat3,
    ];
    return lines[dayOfYear % lines.length];
  }
  if (weekCount >= 2) {
    final lines = [
      l.workoutsThisWeekMotivation(weekCount),
      l.motivationWeekGood1,
      l.motivationWeekGood2,
    ];
    return lines[dayOfYear % lines.length];
  }
  if (weekCount == 1) {
    final lines = [
      l.motivationWeekOne1,
      l.motivationWeekOne2,
      l.motivationWeekOne3,
    ];
    return lines[dayOfYear % lines.length];
  }

  // --- No workouts this week, by time of day ---
  if (hour < 11) {
    final lines = [
      l.motivationMorning1,
      l.motivationMorning2,
      l.motivationMorning3,
      l.motivationMorning4,
    ];
    return lines[dayOfYear % lines.length];
  }
  if (hour < 17) {
    final lines = [
      l.motivationDay1,
      l.motivationDay2,
      l.motivationDay3,
      l.motivationDay4,
    ];
    return lines[dayOfYear % lines.length];
  }
  // Evening
  final lines = [
    l.motivationEvening1,
    l.motivationEvening2,
    l.motivationEvening3,
    l.motivationEvening4,
  ];
  return lines[dayOfYear % lines.length];
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
                    planName ?? context.l10n.training,
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
                          ' \u00b7 ${context.l10n.paused}',
                          style: TextStyle(
                            color: c.warning,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        )
                      else
                        Text(
                          ' \u00b7 ${context.l10n.tapToResume}',
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

String _timeAgo(BuildContext context, DateTime date) {
  final l = context.l10n;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final dateDay = DateTime(date.year, date.month, date.day);
  final days = today.difference(dateDay).inDays;
  if (days == 0) return l.timeAgoToday;
  if (days == 1) return l.timeAgoYesterday;
  if (days <= 6) return l.timeAgoDays(days);
  if (days <= 27) return l.timeAgoWeeks(days ~/ 7);
  return l.timeAgoMonths(days ~/ 30);
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
          border: Border.all(color: c.border.withValues(alpha: 0.3)),
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
                    context.l10n.exercisesCount(exerciseCount, totalSets),
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
                          TextSpan(text: context.l10n.lastWorkout(_timeAgo(context, lastWorkout))),
                          if (completion != null &&
                              completion.done < completion.planned)
                            TextSpan(
                              text:
                                  ' · ${context.l10n.completionOfPlanned(completion.done, completion.planned)}',
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: c.accent,
                    size: 26,
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
                      context.l10n.edit,
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
                    TextSpan(text: context.l10n.exercisesCount(exercises.length, totalSets)),
                    if (lastWorkout != null)
                      TextSpan(text: ' · ${context.l10n.lastWorkout(_timeAgo(context, lastWorkout))}'),
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
                            context.l10n.setsLabel(e.targetSets),
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
                          context.l10n.startTraining,
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: c.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor.withValues(alpha: 0.7), size: 14),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 10,
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
