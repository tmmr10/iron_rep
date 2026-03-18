import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/database_provider.dart';
import '../../services/backup_service.dart';
import '../../shared/design_system.dart';
import '../../l10n/l10n_helper.dart';
import '../../shared/widgets/tap_scale.dart';

class BackupExportScreen extends ConsumerStatefulWidget {
  const BackupExportScreen({super.key});

  @override
  ConsumerState<BackupExportScreen> createState() =>
      _BackupExportScreenState();
}

class _BackupExportScreenState extends ConsumerState<BackupExportScreen> {
  BackupPreview? _preview;
  bool _exportExercises = true;
  bool _exportPlans = true;
  bool _exportWorkouts = true;
  bool _exportRecords = true;
  bool _isExporting = false;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final db = ref.read(databaseProvider);
      final preview = await BackupService.previewExport(db);
      if (mounted) setState(() => _preview = preview);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  bool get _hasSelection =>
      (_exportExercises && (_preview?.exerciseCount ?? 0) > 0) ||
      (_exportPlans && (_preview?.planCount ?? 0) > 0) ||
      (_exportWorkouts && (_preview?.workoutCount ?? 0) > 0) ||
      (_exportRecords && (_preview?.personalRecordCount ?? 0) > 0);

  Future<void> _export() async {
    if (_isExporting || !_hasSelection) return;
    setState(() => _isExporting = true);

    try {
      final db = ref.read(databaseProvider);
      final file = await BackupService.exportToFile(
        db,
        exportExercises: _exportExercises,
        exportPlans: _exportPlans,
        exportWorkouts: _exportWorkouts,
        exportRecords: _exportRecords,
      );

      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'IronRep Backup',
        );
        setState(() => _done = true);
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.backupExport),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
      ),
      body: _buildBody(c),
    );
  }

  Widget _buildBody(AppColors c) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: c.error, size: 48),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: c.error, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (_preview == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_done) {
      return _buildDoneView(c);
    }

    return _buildSelectionView(c);
  }

  Widget _buildDoneView(AppColors c) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, color: c.success, size: 56)
                .animate()
                .scale(begin: const Offset(0.5, 0.5), duration: 300.ms),
            const SizedBox(height: 20),
            Text(
              context.l10n.backupExportSuccess,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 32),
            TapScale(
              onTap: () => context.go('/settings'),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: c.accent.withValues(alpha: 0.3)),
                ),
                child: Text(
                  context.l10n.done,
                  style: TextStyle(
                    color: c.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionView(AppColors c) {
    final p = _preview!;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              Text(
                context.l10n.backupExportPreview,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 200.ms),
              const SizedBox(height: 4),
              Text(
                context.l10n.backupExportSelectHint,
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              _toggleCard(
                c,
                Icons.fitness_center,
                context.l10n.workouts,
                '${p.workoutCount}',
                _exportWorkouts,
                p.workoutCount > 0
                    ? (v) => setState(() => _exportWorkouts = v ?? true)
                    : null,
                enabled: p.workoutCount > 0,
              ),
              _toggleCard(
                c,
                Icons.list_alt,
                context.l10n.backupPlans,
                '${p.planCount}',
                _exportPlans,
                p.planCount > 0
                    ? (v) => setState(() => _exportPlans = v ?? true)
                    : null,
                enabled: p.planCount > 0,
              ),
              _toggleCard(
                c,
                Icons.sports_gymnastics,
                context.l10n.backupExportCustomExercises,
                '${p.exerciseCount}',
                _exportExercises,
                p.exerciseCount > 0
                    ? (v) => setState(() => _exportExercises = v ?? true)
                    : null,
                enabled: p.exerciseCount > 0,
              ),
              _toggleCard(
                c,
                Icons.emoji_events,
                context.l10n.personalRecords,
                '${p.personalRecordCount}',
                _exportRecords,
                p.personalRecordCount > 0
                    ? (v) => setState(() => _exportRecords = v ?? true)
                    : null,
                enabled: p.personalRecordCount > 0,
              ),
            ],
          ),
        ),

        // Export button
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: TapScale(
              onTap: (_isExporting || !_hasSelection) ? null : _export,
              child: Opacity(
                opacity: (_isExporting || !_hasSelection) ? 0.5 : 1.0,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: c.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: c.accent.withValues(alpha: 0.3)),
                  ),
                  child: _isExporting
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
                            Icon(Icons.upload_rounded,
                                color: c.accent, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              context.l10n.backupExportStart,
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
    );
  }

  Widget _toggleCard(
    AppColors c,
    IconData icon,
    String label,
    String count,
    bool value,
    ValueChanged<bool?>? onChanged, {
    bool enabled = true,
  }) {
    final effectiveValue = enabled && value;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: effectiveValue
              ? c.accent.withValues(alpha: 0.3)
              : c.border.withValues(alpha: 0.3),
        ),
      ),
      child: CheckboxListTile(
        secondary: Icon(icon,
            color: enabled
                ? (effectiveValue ? c.accent : c.textMuted)
                : c.textMuted.withValues(alpha: 0.4),
            size: 22),
        title: Text(label,
            style: TextStyle(
              color: enabled ? c.textPrimary : c.textMuted,
              fontSize: 15,
            )),
        subtitle: Text(count,
            style: TextStyle(
              color: enabled ? c.accent : c.textMuted.withValues(alpha: 0.5),
              fontWeight: FontWeight.w700,
              fontSize: 16,
            )),
        value: effectiveValue,
        onChanged: onChanged,
        activeColor: c.accent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}
