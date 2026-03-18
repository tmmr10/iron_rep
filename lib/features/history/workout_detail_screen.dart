import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/iron_card.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../l10n/l10n_helper.dart';
import '../plans/exercise_picker_sheet.dart';

class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final int workoutId;

  const WorkoutDetailScreen({super.key, required this.workoutId});

  @override
  ConsumerState<WorkoutDetailScreen> createState() =>
      _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen> {
  bool _isEditing = false;
  _WorkoutDetail? _detail;
  bool _loading = true;

  // Edit state: maps setId -> edited values
  final Map<int, _EditedSet> _editedSets = {};
  final Set<int> _deletedSetIds = {};
  final List<_NewSet> _newSets = [];
  final List<_NewExercise> _newExercises = [];
  final Set<int> _deletedExerciseIds = {}; // workoutExerciseIds to remove
  final _nameController = TextEditingController();
  int _newSetIdCounter = -1;
  int _newExerciseIdCounter = -1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    final db = ref.read(databaseProvider);
    final detail = await _loadWorkoutDetail(db, widget.workoutId);
    if (mounted) {
      setState(() {
        _detail = detail;
        _loading = false;
      });
    }
  }

  void _showWorkoutActions(
    BuildContext context,
    AppColors c,
    _WorkoutDetail detail,
    String duration,
    int totalSets,
    double totalVolume,
  ) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                TapScale(
                  onTap: () {
                    Navigator.pop(context);
                    _shareWorkout(detail, duration, totalSets, totalVolume);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.ios_share, color: c.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.sharePlan,
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
                const SizedBox(height: 10),
                TapScale(
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(context);
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: c.error.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.error.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.delete_outline, color: c.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.delete,
                          style: TextStyle(
                            color: c.error,
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
        ),
      ),
    );
  }

  void _shareWorkout(
    _WorkoutDetail detail,
    String duration,
    int totalSets,
    double totalVolume,
  ) async {
    final w = detail.workout;
    final name = w.name ?? 'Workout';
    final date =
        '${w.startedAt.day}.${w.startedAt.month}.${w.startedAt.year}';

    final exerciseLines = detail.exercises.map((ed) {
      final setLines = ed.sets.asMap().entries.map((entry) {
        final i = entry.key + 1;
        final s = entry.value;
        final weight = s.weight != null ? '${s.weight} kg' : '-';
        final reps = s.reps != null ? '${s.reps} reps' : '-';
        return '   $i. $weight × $reps';
      }).join('\n');
      return '${ed.exerciseName}\n$setLines';
    }).join('\n\n');

    final message = '💪 $name\n'
        '📅 $date · ⏱ $duration\n'
        '🏋️ ${detail.exercises.length} ${context.l10n.exercises} · '
        '$totalSets ${context.l10n.sets} · '
        '${totalVolume.round()} kg\n\n'
        '$exerciseLines';

    final box = context.findRenderObject() as RenderBox?;
    await Share.share(
      message,
      subject: '$name — IronRep',
      sharePositionOrigin:
          box != null ? box.localToGlobal(Offset.zero) & box.size : null,
    );
  }

  void _startEditing() {
    setState(() {
      _isEditing = true;
      _nameController.text = _detail?.workout.name ?? '';
      _editedSets.clear();
      _deletedSetIds.clear();
      _newSets.clear();
      _newExercises.clear();
      _deletedExerciseIds.clear();
    });
  }

  bool get _hasEditChanges {
    final nameChanged = _nameController.text.trim() != (_detail?.workout.name ?? '');
    return nameChanged ||
        _editedSets.isNotEmpty ||
        _deletedSetIds.isNotEmpty ||
        _newSets.isNotEmpty ||
        _newExercises.isNotEmpty ||
        _deletedExerciseIds.isNotEmpty;
  }

  Future<void> _cancelEditing() async {
    if (_hasEditChanges) {
      final c = AppColors.of(context);
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: c.surface,
          title: Text(context.l10n.discardChanges,
              style: TextStyle(color: c.textPrimary)),
          content: Text(context.l10n.changesWillBeLost,
              style: TextStyle(color: c.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(context.l10n.continueEditing),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(context.l10n.discard, style: TextStyle(color: c.error)),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    setState(() {
      _isEditing = false;
      _editedSets.clear();
      _deletedSetIds.clear();
      _newSets.clear();
      _newExercises.clear();
      _deletedExerciseIds.clear();
    });
  }

  Future<void> _saveEdits() async {
    final db = ref.read(databaseProvider);

    // Update workout name
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty && newName != _detail?.workout.name) {
      await db.workoutDao.updateWorkoutName(widget.workoutId, newName);
    }

    // Delete removed exercises
    for (final weId in _deletedExerciseIds) {
      await db.workoutDao.removeExerciseFromWorkout(weId);
    }

    // Delete removed sets
    for (final setId in _deletedSetIds) {
      await db.workoutDao.deleteSet(setId);
    }

    // Apply edits to existing sets
    for (final entry in _editedSets.entries) {
      await db.workoutDao.updateSet(
        entry.key,
        weight: entry.value.weight,
        reps: entry.value.reps,
      );
      if (entry.value.isCompleted != null) {
        if (entry.value.isCompleted!) {
          await db.workoutDao.completeSet(entry.key);
        } else {
          await db.workoutDao.uncompleteSet(entry.key);
        }
      }
    }

    // Add new exercises and their sets
    for (final ne in _newExercises) {
      final weId = await db.workoutDao
          .addExerciseToWorkout(widget.workoutId, ne.exerciseId);
      for (final ns in _newSets.where((s) => s.newExerciseId == ne.id)) {
        final setId = await db.workoutDao.addSet(weId);
        await db.workoutDao.updateSet(setId,
            weight: ns.weight, reps: ns.reps);
        if (ns.weight != null || ns.reps != null) {
          await db.workoutDao.completeSet(setId);
        }
      }
    }

    // Add new sets to existing exercises
    for (final ns in _newSets.where((s) => s.newExerciseId == null)) {
      final setId = await db.workoutDao.addSet(ns.workoutExerciseId!);
      await db.workoutDao.updateSet(setId,
          weight: ns.weight, reps: ns.reps);
      if (ns.weight != null || ns.reps != null) {
        await db.workoutDao.completeSet(setId);
      }
    }

    // Recalculate personal records
    await db.workoutDao.recalculatePersonalRecords(widget.workoutId);

    // Reload — clear edit state first so _hasEditChanges returns false
    setState(() {
      _isEditing = false;
      _loading = true;
      _editedSets.clear();
      _deletedSetIds.clear();
      _newSets.clear();
      _newExercises.clear();
      _deletedExerciseIds.clear();
    });
    await _loadDetail();
  }

  void _addSetToExercise(int workoutExerciseId) {
    setState(() {
      _newSets.add(_NewSet(
        id: _newSetIdCounter--,
        workoutExerciseId: workoutExerciseId,
      ));
    });
  }

  void _addSetToNewExercise(int newExerciseId) {
    setState(() {
      _newSets.add(_NewSet(
        id: _newSetIdCounter--,
        newExerciseId: newExerciseId,
      ));
    });
  }

  void _addExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollController) => ExercisePickerSheet(
          scrollController: scrollController,
          onSelect: (exerciseId, exerciseName) {
            Navigator.pop(ctx);
            setState(() {
              final ne = _NewExercise(
                id: _newExerciseIdCounter--,
                exerciseId: exerciseId,
                exerciseName: exerciseName,
              );
              _newExercises.add(ne);
              // Auto-add one empty set
              _newSets.add(_NewSet(
                id: _newSetIdCounter--,
                newExerciseId: ne.id,
              ));
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const SizedBox.shrink()),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final detail = _detail!;

    final w = detail.workout;
    final duration = w.durationSeconds != null
        ? '${w.durationSeconds! ~/ 60}m ${w.durationSeconds! % 60}s'
        : '--';
    final totalSets = detail.exercises
        .where((ed) => !_deletedExerciseIds.contains(ed.workoutExerciseId))
        .fold<int>(0, (sum, ed) => sum + ed.sets.length);
    final totalVolume = detail.exercises
        .where((ed) => !_deletedExerciseIds.contains(ed.workoutExerciseId))
        .fold<double>(0, (sum, ed) => sum + ed.sets.fold<double>(
            0, (s, set_) => s + (set_.weight ?? 0) * (set_.reps ?? 0)));
    final exerciseCount = detail.exercises
        .where((ed) => !_deletedExerciseIds.contains(ed.workoutExerciseId))
        .length;

    return PopScope(
      canPop: !_isEditing || !_hasEditChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cancelEditing();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          if (!_isEditing) ...[
            TextButton(
              onPressed: _startEditing,
              child: Text(
                context.l10n.edit,
                style: TextStyle(
                  color: c.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: () => _showWorkoutActions(
                context, c, detail, duration, totalSets, totalVolume,
              ),
              icon: Icon(Icons.more_horiz, color: c.textPrimary, size: 24),
            ),
          ] else ...[
            TextButton(
              onPressed: () => _saveEdits(),
              child: Text(
                context.l10n.save,
                style: TextStyle(
                  color: c.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _cancelEditing,
              child: Text(
                context.l10n.cancel,
                style: TextStyle(color: c.textMuted),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: _isEditing
          ? Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: FloatingActionButton(
                onPressed: _addExercise,
                backgroundColor: c.accent,
                foregroundColor: Colors.black,
                elevation: 4,
                child: const Icon(Icons.add),
              ),
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: IronRepSpacing.screenPadding,
              children: [
          if (_isEditing) ...[
            _GradientNameField(
              controller: _nameController,
              colors: c,
              hintText: 'Workout Name',
            ),
            const SizedBox(height: 4),
          ] else ...[
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [c.accentGradientStart, c.accentGradientEnd],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                w.name ?? 'Workout',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            '${w.startedAt.day}.${w.startedAt.month}.${w.startedAt.year} · $duration',
            style: TextStyle(color: c.textSecondary),
          ),
          if (!_isEditing && totalSets > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _StatChip(
                  icon: Icons.fitness_center,
                  label: '$exerciseCount ${context.l10n.exercises}',
                  colors: c,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.repeat,
                  label: '$totalSets ${context.l10n.sets}',
                  colors: c,
                ),
                const SizedBox(width: 8),
                _StatChip(
                  icon: Icons.monitor_weight_outlined,
                  label: '${totalVolume.round()} kg',
                  colors: c,
                ),
              ],
            ),
          ],
          const SizedBox(height: IronRepSpacing.xl),

          // Existing exercises
          ...detail.exercises
              .where((ed) => !_deletedExerciseIds.contains(ed.workoutExerciseId))
              .map((ed) => _buildExerciseCard(c, ed)),

          // New exercises
          ..._newExercises.map((ne) => _buildNewExerciseCard(c, ne)),

          if (detail.skippedExerciseNames.isNotEmpty && !_isEditing) ...[
            const SizedBox(height: IronRepSpacing.sm),
            Text(
              context.l10n.skippedCapital,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...detail.skippedExerciseNames.map((name) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.skip_next_rounded,
                          color: c.textMuted, size: 16),
                      const SizedBox(width: 8),
                      Text(name,
                          style: TextStyle(color: c.textMuted, fontSize: 14)),
                    ],
                  ),
                )),
          ],

          if (_isEditing)
            const SizedBox(height: 80),
        ],
      ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildExerciseCard(AppColors c, _ExerciseDetail ed) {
    final visibleSets = ed.sets
        .where((s) => !_deletedSetIds.contains(s.id))
        .toList();
    final newSetsForExercise = _newSets
        .where((ns) =>
            ns.workoutExerciseId == ed.workoutExerciseId &&
            ns.newExerciseId == null)
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: IronRepSpacing.md),
      child: _isEditing
          ? IronCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          ed.exerciseName,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_outline,
                            color: c.error, size: 20),
                        onPressed: () {
                          setState(() {
                            _deletedExerciseIds.add(ed.workoutExerciseId);
                          });
                        },
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...visibleSets.map((s) => _buildEditableSetRow(c, s)),
                  ...newSetsForExercise.map((ns) => _buildNewSetRow(c, ns)),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: TextButton.icon(
                      onPressed: () =>
                          _addSetToExercise(ed.workoutExerciseId),
                      icon: const Icon(Icons.add, size: 16),
                      label: Text(context.l10n.addSet),
                      style: TextButton.styleFrom(
                        foregroundColor: c.accent,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : IronCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ed.exerciseName,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  if (visibleSets.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ...visibleSets.map((s) => _buildReadOnlySetRow(c, s)),
                  ] else ...[
                    const SizedBox(height: 8),
                    Text(
                      'Noch keine Sets',
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildNewExerciseCard(AppColors c, _NewExercise ne) {
    final newSetsForExercise =
        _newSets.where((ns) => ns.newExerciseId == ne.id).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: IronRepSpacing.md),
      child: IronCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ne.exerciseName,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: c.error, size: 20),
                  onPressed: () {
                    setState(() {
                      _newSets.removeWhere((ns) => ns.newExerciseId == ne.id);
                      _newExercises.remove(ne);
                    });
                  },
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...newSetsForExercise.map((ns) => _buildNewSetRow(c, ns)),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: TextButton.icon(
                onPressed: () => _addSetToNewExercise(ne.id),
                icon: const Icon(Icons.add, size: 16),
                label: Text(context.l10n.addSet),
                style: TextButton.styleFrom(
                  foregroundColor: c.accent,
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlySetRow(AppColors c, WorkoutSet s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('${s.setNumber}',
                style: TextStyle(color: c.textMuted)),
          ),
          Text(
            '${s.weight?.toStringAsFixed(1) ?? '-'} kg × ${s.reps ?? '-'}',
            style: TextStyle(
              color: s.isCompleted ? c.textPrimary : c.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (s.isCompleted)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(Icons.check, color: c.success, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildEditableSetRow(AppColors c, WorkoutSet s) {
    final edited = _editedSets[s.id];
    final weight = edited?.weight ?? s.weight;
    final reps = edited?.reps ?? s.reps;
    final isCompleted = edited?.isCompleted ?? s.isCompleted;

    return Dismissible(
      key: ValueKey('set_${s.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: c.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete_outline, color: c.error, size: 20),
      ),
      onDismissed: (_) {
        setState(() => _deletedSetIds.add(s.id));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Text(
                '${s.setNumber}',
                style: TextStyle(
                  color: c.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: TextEditingController(
                    text: weight?.toStringAsFixed(1) ?? ''),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: '0.0',
                  hintStyle: TextStyle(color: c.textMuted),
                  suffixText: 'kg',
                  suffixStyle: TextStyle(color: c.textMuted, fontSize: 12),
                ),
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (v) {
                  _editedSets[s.id] = (_editedSets[s.id] ?? _EditedSet())
                      .copyWith(weight: double.tryParse(v));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('×',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            SizedBox(
              width: 56,
              child: TextField(
                controller:
                    TextEditingController(text: reps?.toString() ?? ''),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(color: c.textMuted),
                ),
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (v) {
                  _editedSets[s.id] = (_editedSets[s.id] ?? _EditedSet())
                      .copyWith(reps: int.tryParse(v));
                },
              ),
            ),
            const SizedBox(width: 8),
            TapScale(
              onTap: () {
                setState(() {
                  _editedSets[s.id] = (_editedSets[s.id] ?? _EditedSet())
                      .copyWith(isCompleted: !isCompleted);
                });
              },
              child: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? c.success.withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  color: isCompleted ? c.success : c.textMuted,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewSetRow(AppColors c, _NewSet ns) {
    return Dismissible(
      key: ValueKey('new_set_${ns.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: c.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete_outline, color: c.error, size: 20),
      ),
      onDismissed: (_) {
        setState(() => _newSets.remove(ns));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.accent.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: c.accent, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: '0.0',
                  hintStyle: TextStyle(color: c.textMuted),
                  suffixText: 'kg',
                  suffixStyle: TextStyle(color: c.textMuted, fontSize: 12),
                ),
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (v) => ns.weight = double.tryParse(v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('×',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  )),
            ),
            SizedBox(
              width: 56,
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  border: InputBorder.none,
                  hintText: '0',
                  hintStyle: TextStyle(color: c.textMuted),
                ),
                style: TextStyle(
                  color: c.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                onChanged: (v) => ns.reps = int.tryParse(v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final c = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(context.l10n.deleteWorkoutConfirm,
            style: TextStyle(color: c.textPrimary)),
        content: Text(
            context.l10n.deleteWorkoutMessage,
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete, style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref
          .read(databaseProvider)
          .workoutDao
          .cancelWorkout(widget.workoutId);
      if (context.mounted) context.pop();
    }
  }
}

// --- Data classes ---

class _EditedSet {
  final double? weight;
  final int? reps;
  final bool? isCompleted;

  _EditedSet({this.weight, this.reps, this.isCompleted});

  _EditedSet copyWith({double? weight, int? reps, bool? isCompleted}) {
    return _EditedSet(
      weight: weight ?? this.weight,
      reps: reps ?? this.reps,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

class _NewSet {
  final int id;
  final int? workoutExerciseId;
  final int? newExerciseId;
  double? weight;
  int? reps;

  _NewSet({
    required this.id,
    this.workoutExerciseId,
    this.newExerciseId,
  });
}

class _NewExercise {
  final int id;
  final int exerciseId;
  final String exerciseName;

  _NewExercise({
    required this.id,
    required this.exerciseId,
    required this.exerciseName,
  });
}

class _WorkoutDetail {
  final Workout workout;
  final List<_ExerciseDetail> exercises;
  final List<String> skippedExerciseNames;
  _WorkoutDetail(this.workout, this.exercises,
      [this.skippedExerciseNames = const []]);
}

class _ExerciseDetail {
  final int workoutExerciseId;
  final int exerciseId;
  final String exerciseName;
  final List<WorkoutSet> sets;
  _ExerciseDetail(
      this.workoutExerciseId, this.exerciseId, this.exerciseName, this.sets);
}

Future<_WorkoutDetail> _loadWorkoutDetail(
    AppDatabase db, int workoutId) async {
  final workout = await (db.select(db.workouts)
        ..where((t) => t.id.equals(workoutId)))
      .getSingle();
  final wes = await db.workoutDao.getWorkoutExercises(workoutId);
  final exercises = <_ExerciseDetail>[];

  for (final we in wes) {
    final ex = await (db.select(db.exercises)
          ..where((t) => t.id.equals(we.exerciseId)))
        .getSingle();
    final sets = await db.workoutDao.getSetsForWorkoutExercise(we.id);
    exercises.add(_ExerciseDetail(we.id, ex.id, ex.name, sets));
  }

  final skippedNames = <String>[];
  if (workout.planId != null) {
    final planExercises = await db.planDao.getPlanExercises(workout.planId!);
    final workoutExerciseIds = wes.map((we) => we.exerciseId).toSet();
    for (final pe in planExercises) {
      if (!workoutExerciseIds.contains(pe.exerciseId)) {
        final ex = await (db.select(db.exercises)
              ..where((t) => t.id.equals(pe.exerciseId)))
            .getSingle();
        skippedNames.add(ex.name);
      }
    }
  }

  return _WorkoutDetail(workout, exercises, skippedNames);
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppColors colors;

  const _StatChip({
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

class _GradientNameField extends StatefulWidget {
  final TextEditingController controller;
  final AppColors colors;
  final String hintText;

  const _GradientNameField({
    required this.controller,
    required this.colors,
    this.hintText = 'Name',
  });

  @override
  State<_GradientNameField> createState() => _GradientNameFieldState();
}

class _GradientNameFieldState extends State<_GradientNameField> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Focus(
          onFocusChange: (focused) => setState(() => _hasFocus = focused),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [c.accentGradientStart, c.accentGradientEnd],
            ).createShader(bounds),
            blendMode: BlendMode.srcIn,
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: c.textMuted.withValues(alpha: 0.4),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 2,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            color: _hasFocus ? c.accent : c.border.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }
}
