import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/database_provider.dart';
import '../../providers/plan_providers.dart';
import '../../services/backup_service.dart';
import '../../shared/design_system.dart';
import '../../l10n/l10n_helper.dart';
import '../../shared/widgets/tap_scale.dart';

class BackupImportScreen extends ConsumerStatefulWidget {
  final String filePath;

  const BackupImportScreen({super.key, required this.filePath});

  @override
  ConsumerState<BackupImportScreen> createState() =>
      _BackupImportScreenState();
}

class _BackupImportScreenState extends ConsumerState<BackupImportScreen> {
  BackupData? _data;
  BackupPreview? _preview;
  bool _importExercises = true;
  bool _importPlans = true;
  bool _importWorkouts = true;
  bool _importRecords = true;
  bool _isImporting = false;
  ImportResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _parseFile();
  }

  void _parseFile() {
    final file = File(widget.filePath);
    if (!file.existsSync()) {
      setState(() => _error = 'File not found');
      return;
    }
    final data = BackupService.parseBackup(file);
    if (data == null) {
      setState(() => _error = 'Invalid backup file');
      return;
    }
    setState(() {
      _data = data;
      _preview = BackupService.previewBackup(data);
    });
  }

  Future<void> _import() async {
    if (_data == null) return;
    setState(() => _isImporting = true);
    try {
      final db = ref.read(databaseProvider);
      final result = await BackupService.importBackup(
        db,
        _data!,
        importExercises: _importExercises,
        importPlans: _importPlans,
        importWorkouts: _importWorkouts,
        importRecords: _importRecords,
      );
      ref.invalidate(allPlansProvider);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.backupImport),
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
    if (_isImporting) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: c.accent),
            const SizedBox(height: 20),
            Text(
              context.l10n.backupImportProgress,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.backupNoDuplicates,
              style: TextStyle(color: c.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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

    if (_result != null) {
      return _buildResultView(c);
    }

    return _buildPreviewView(c);
  }

  Widget _buildResultView(AppColors c) {
    final r = _result!;
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
              context.l10n.backupImportSuccess,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            if (r.workoutsImported > 0)
              _resultRow(c, Icons.fitness_center,
                  context.l10n.backupWorkoutsImported(r.workoutsImported)),
            if (r.plansImported > 0)
              _resultRow(c, Icons.list_alt,
                  context.l10n.backupPlansImported(r.plansImported)),
            if (r.exercisesImported > 0)
              _resultRow(c, Icons.sports_gymnastics,
                  context.l10n.backupExercisesImported(r.exercisesImported)),
            if (r.personalRecordsImported > 0)
              _resultRow(c, Icons.emoji_events,
                  context.l10n.backupRecordsImported(r.personalRecordsImported)),
            const SizedBox(height: 32),
            TapScale(
              onTap: () => context.go('/workout'),
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

  Widget _resultRow(AppColors c, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c.textSecondary, size: 18),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: c.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildPreviewView(AppColors c) {
    final p = _preview!;
    final exportDate = DateTime.tryParse(p.exportedAt);
    final dateStr = exportDate != null
        ? '${exportDate.day.toString().padLeft(2, '0')}.${exportDate.month.toString().padLeft(2, '0')}.${exportDate.year}'
        : p.exportedAt;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            children: [
              // Header
              Text(
                context.l10n.backupImportPreview,
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ).animate().fadeIn(duration: 200.ms),
              const SizedBox(height: 4),
              Text(
                context.l10n.backupExportedAt(dateStr),
                style: TextStyle(color: c.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Toggleable category cards
              _toggleCard(c, Icons.fitness_center,
                  context.l10n.workouts, '${p.workoutCount}',
                  _importWorkouts,
                  p.workoutCount > 0
                      ? (v) => setState(() => _importWorkouts = v ?? true)
                      : null,
                  enabled: p.workoutCount > 0),
              _toggleCard(c, Icons.list_alt,
                  context.l10n.backupPlans, '${p.planCount}',
                  _importPlans,
                  p.planCount > 0
                      ? (v) => setState(() => _importPlans = v ?? true)
                      : null,
                  enabled: p.planCount > 0),
              _toggleCard(c, Icons.sports_gymnastics,
                  context.l10n.exercises, '${p.exerciseCount}',
                  _importExercises,
                  p.exerciseCount > 0
                      ? (v) => setState(() => _importExercises = v ?? true)
                      : null,
                  enabled: p.exerciseCount > 0),
              _toggleCard(c, Icons.emoji_events,
                  context.l10n.personalRecords, '${p.personalRecordCount}',
                  _importRecords,
                  p.personalRecordCount > 0
                      ? (v) => setState(() => _importRecords = v ?? true)
                      : null,
                  enabled: p.personalRecordCount > 0),

              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: c.textMuted, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        context.l10n.backupNoDuplicates,
                        style: TextStyle(color: c.textMuted, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
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
                    border: Border.all(color: c.accent.withValues(alpha: 0.3)),
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
                              context.l10n.backupImportStart,
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

  Widget _toggleCard(AppColors c, IconData icon, String label, String count,
      bool value, ValueChanged<bool?>? onChanged, {bool enabled = true}) {
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
