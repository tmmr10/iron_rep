import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/database_provider.dart';
import '../../providers/plan_providers.dart';
import '../../services/plan_sharing_service.dart';
import '../../shared/design_system.dart';
import '../../l10n/l10n_helper.dart';
import '../../shared/widgets/tap_scale.dart';

class PlanImportScreen extends ConsumerStatefulWidget {
  final SharedPlan plan;

  const PlanImportScreen({super.key, required this.plan});

  @override
  ConsumerState<PlanImportScreen> createState() => _PlanImportScreenState();
}

class _PlanImportScreenState extends ConsumerState<PlanImportScreen> {
  List<MatchedExercise>? _matched;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _matchExercises();
  }

  Future<void> _matchExercises() async {
    final db = ref.read(databaseProvider);
    final matched =
        await PlanSharingService.matchExercises(db, widget.plan);
    if (mounted) setState(() => _matched = matched);
  }

  Future<void> _import() async {
    setState(() => _isImporting = true);
    final db = ref.read(databaseProvider);
    await PlanSharingService.importPlan(db, widget.plan);
    ref.invalidate(allPlansProvider);
    if (mounted) context.go('/workout');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.importPlan),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/workout');
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
                      // Plan name headline
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [c.accent, c.accent.withValues(alpha: 0.7)],
                        ).createShader(bounds),
                        child: Text(
                          widget.plan.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
                      const SizedBox(height: 4),
                      Text(
                        context.l10n.exercisesCount(widget.plan.exercises.length, widget.plan.exercises.fold<int>(0, (s, e) => s + e.targetSets)),
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 14,
                        ),
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 24),
                      // Exercise list
                      ...List.generate(_matched!.length, (i) {
                        final m = _matched![i];
                        final isCustom =
                            m.status == ExerciseMatchStatus.createdCustom;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: c.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.border.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      m.displayName,
                                      style: TextStyle(
                                        color: c.textPrimary,
                                        fontWeight: FontWeight.w500,
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
                              Text(
                                '${m.source.targetSets} ${context.l10n.sets}',
                                style: TextStyle(
                                  color: c.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
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
                                      context.l10n.importPlan,
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
