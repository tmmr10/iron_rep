import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../database/app_database.dart';
import '../../providers/database_provider.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/iron_card.dart';
import '../../shared/widgets/tap_scale.dart';
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
          title: Text('Änderungen verwerfen?',
              style: TextStyle(color: c.textPrimary)),
          content: Text('Deine Änderungen gehen verloren.',
              style: TextStyle(color: c.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Weiter bearbeiten'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Verwerfen', style: TextStyle(color: c.error)),
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
        appBar: AppBar(title: const Text('Workout Details')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final detail = _detail!;

    final w = detail.workout;
    final duration = w.durationSeconds != null
        ? '${w.durationSeconds! ~/ 60}m ${w.durationSeconds! % 60}s'
        : '--';

    return PopScope(
      canPop: !_isEditing || !_hasEditChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await _cancelEditing();
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Workout Details'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: Icon(Icons.more_horiz, color: c.textSecondary),
              onPressed: () => _showOptions(context, c),
            )
          else
            TextButton(
              onPressed: _cancelEditing,
              child: const Text('Abbrechen'),
            ),
        ],
      ),
      floatingActionButton: _isEditing
          ? Padding(
              padding: const EdgeInsets.only(bottom: 72),
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
          if (_isEditing)
            _GradientNameField(
              controller: _nameController,
              colors: c,
              hintText: 'Workout Name',
            )
          else
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
          Text(
            '${w.startedAt.day}.${w.startedAt.month}.${w.startedAt.year} · $duration',
            style: TextStyle(color: c.textSecondary),
          ),
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
              'Übersprungen',
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
          if (_isEditing)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: TapScale(
                  onTap: () => _saveEdits(),
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
                    child: Text(
                      'Änderungen speichern',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
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
      child: IronCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _isEditing
                        ? null
                        : () => context
                            .push('/exercise-detail/${ed.exerciseId}'),
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            ed.exerciseName,
                            style: TextStyle(
                              color: c.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        if (!_isEditing) ...[
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right,
                              color: c.textMuted, size: 18),
                        ],
                      ],
                    ),
                  ),
                ),
                if (_isEditing)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: c.error, size: 20),
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
            ...visibleSets.map((s) => _isEditing
                ? _buildEditableSetRow(c, s)
                : _buildReadOnlySetRow(c, s)),
            ...newSetsForExercise
                .map((ns) => _buildNewSetRow(c, ns)),
            if (_isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: TextButton.icon(
                  onPressed: () =>
                      _addSetToExercise(ed.workoutExerciseId),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Set hinzufügen'),
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
                label: const Text('Set hinzufügen'),
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
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: c.error.withValues(alpha: 0.2),
        child: Icon(Icons.delete, color: c.error),
      ),
      onDismissed: (_) {
        setState(() => _deletedSetIds.add(s.id));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text('${s.setNumber}',
                  style: TextStyle(color: c.textMuted)),
            ),
            SizedBox(
              width: 80,
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  suffixText: 'kg',
                  suffixStyle:
                      TextStyle(color: c.textMuted, fontSize: 12),
                ),
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                onChanged: (v) {
                  _editedSets[s.id] = (_editedSets[s.id] ?? _EditedSet())
                      .copyWith(weight: double.tryParse(v));
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('×', style: TextStyle(color: c.textMuted)),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                controller:
                    TextEditingController(text: reps?.toString() ?? ''),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                onChanged: (v) {
                  _editedSets[s.id] = (_editedSets[s.id] ?? _EditedSet())
                      .copyWith(reps: int.tryParse(v));
                },
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                setState(() {
                  _editedSets[s.id] = (_editedSets[s.id] ?? _EditedSet())
                      .copyWith(isCompleted: !isCompleted);
                });
              },
              child: Icon(
                isCompleted
                    ? Icons.check_circle
                    : Icons.check_circle_outline,
                color: isCompleted ? c.success : c.textMuted,
                size: 22,
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
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: c.error.withValues(alpha: 0.2),
        child: Icon(Icons.delete, color: c.error),
      ),
      onDismissed: (_) {
        setState(() => _newSets.remove(ns));
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Icon(Icons.add, color: c.accent, size: 14),
            ),
            SizedBox(
              width: 80,
              child: TextField(
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                ],
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: '0.0',
                  suffixText: 'kg',
                  suffixStyle:
                      TextStyle(color: c.textMuted, fontSize: 12),
                ),
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                onChanged: (v) => ns.weight = double.tryParse(v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('×', style: TextStyle(color: c.textMuted)),
            ),
            SizedBox(
              width: 60,
              child: TextField(
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  hintText: '0',
                ),
                style: TextStyle(color: c.textPrimary, fontSize: 14),
                onChanged: (v) => ns.reps = int.tryParse(v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, AppColors c) {
    showModalBottomSheet(
      context: context,
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
                    _startEditing();
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
                    child: Text(
                      'Bearbeiten',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                    child: Text(
                      'Workout löschen',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.error,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
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

  Future<void> _confirmDelete(BuildContext context) async {
    final c = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: c.surface,
        title: Text('Workout löschen?',
            style: TextStyle(color: c.textPrimary)),
        content: Text(
            'Das Workout und alle zugehörigen Daten werden unwiderruflich gelöscht.',
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Löschen', style: TextStyle(color: c.error)),
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
