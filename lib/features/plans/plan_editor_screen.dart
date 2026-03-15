import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/enums.dart';
import '../../providers/database_provider.dart';
import '../../providers/exercise_providers.dart';
import '../../providers/plan_providers.dart';
import '../../services/plan_sharing_service.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/tap_scale.dart';
import 'exercise_picker_sheet.dart';

class _PlanExerciseEntry {
  final int exerciseId;
  final String name;
  final String? muscleGroup;
  int targetSets;

  _PlanExerciseEntry({
    required this.exerciseId,
    required this.name,
    this.muscleGroup,
    this.targetSets = 3,
  });
}

class PlanEditorScreen extends ConsumerStatefulWidget {
  final int? planId;

  const PlanEditorScreen({super.key, this.planId});

  @override
  ConsumerState<PlanEditorScreen> createState() => _PlanEditorScreenState();
}

class _PlanEditorScreenState extends ConsumerState<PlanEditorScreen> {
  final _nameController = TextEditingController();
  final List<_PlanExerciseEntry> _exercises = [];
  bool _isLoading = true;
  bool _isSaving = false;

  // Snapshot of original state for change detection
  String _originalName = '';
  List<(int, int)> _originalExercises = []; // (exerciseId, targetSets)

  bool get _hasChanges {
    if (_nameController.text.trim() != _originalName) return true;
    final current = _exercises.map((e) => (e.exerciseId, e.targetSets)).toList();
    if (current.length != _originalExercises.length) return true;
    for (var i = 0; i < current.length; i++) {
      if (current[i] != _originalExercises[i]) return true;
    }
    return false;
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasChanges) return true;
    final c = AppColors.of(context);
    final result = await showDialog<bool>(
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
    return result ?? false;
  }

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    if (widget.planId != null) {
      final db = ref.read(databaseProvider);
      final plan = await db.planDao.getPlan(widget.planId!);
      _nameController.text = plan.name;

      final planExercises = await db.planDao.getPlanExercises(widget.planId!);
      final allExercises = await db.exerciseDao.getAll();

      for (final pe in planExercises) {
        final exercise = allExercises.firstWhere(
          (e) => e.id == pe.exerciseId,
          orElse: () => allExercises.first,
        );
        _exercises.add(_PlanExerciseEntry(
          exerciseId: pe.exerciseId,
          name: exercise.name,
          muscleGroup: exercise.primaryMuscleGroup,
          targetSets: pe.targetSets,
        ));
      }
    }
    _originalName = _nameController.text.trim();
    _originalExercises =
        _exercises.map((e) => (e.exerciseId, e.targetSets)).toList();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isEditing = widget.planId != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && mounted) context.pop();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Plan bearbeiten' : 'Neuer Plan'),
        actions: [
          if (isEditing)
            IconButton(
              icon: Icon(Icons.more_horiz, color: c.textSecondary),
              onPressed: () => _showPlanOptions(context, c),
            ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 72),
              child: FloatingActionButton(
                onPressed: _addExercise,
                backgroundColor: c.accent,
                foregroundColor: Colors.black,
                elevation: 4,
                child: const Icon(Icons.add),
              ),
            ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    children: [
                      // Plan name — gradient inline edit
                      _GradientNameField(
                        controller: _nameController,
                        colors: c,
                      ),
                      const SizedBox(height: 24),
                      // Section header
                      Row(
                        children: [
                          Text(
                            'ÜBUNGEN',
                            style: TextStyle(
                              color: c.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${_exercises.length} Übungen · ${_exercises.fold<int>(0, (s, e) => s + e.targetSets)} Sets',
                            style: TextStyle(
                              color: c.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Exercise list
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _exercises.length,
                        proxyDecorator: (child, index, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (context, child) => Material(
                              color: Colors.transparent,
                              elevation: 4,
                              shadowColor: Colors.black26,
                              borderRadius: BorderRadius.circular(14),
                              child: child,
                            ),
                            child: child,
                          );
                        },
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = _exercises.removeAt(oldIndex);
                            _exercises.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final ex = _exercises[index];
                          return _ExerciseRow(
                            key: ValueKey('${ex.exerciseId}_$index'),
                            entry: ex,
                            index: index + 1,
                            onRemove: () {
                              setState(() => _exercises.removeAt(index));
                            },
                            onTargetSetsChanged: (sets) {
                              setState(() => ex.targetSets = sets);
                            },
                            onReplace: () => _replaceExercise(index),
                          );
                        },
                      ),
                      // Bottom spacing for FAB
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
                // Save button
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: TapScale(
                      onTap: _isSaving ? null : _savePlan,
                      child: Opacity(
                        opacity: _isSaving ? 0.5 : 1.0,
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
                          child: _isSaving
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
                                    Icon(Icons.check_rounded,
                                        color: c.accent, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      isEditing
                                          ? 'Änderungen speichern'
                                          : 'Plan erstellen',
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
    ),
    );
  }

  void _addExercise() {
    final c = AppColors.of(context);
    ref.read(exerciseSearchQueryProvider.notifier).state = '';
    ref.read(exerciseMuscleFilterProvider.notifier).state = null;

    final existingIds = _exercises.map((e) => e.exerciseId).toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ExercisePickerSheet(
          scrollController: scrollController,
          excludeIds: existingIds,
          onSelect: (exerciseId, name) async {
            final db = ref.read(databaseProvider);
            final allEx = await db.exerciseDao.getAll();
            final ex = allEx.firstWhere(
              (e) => e.id == exerciseId,
              orElse: () => allEx.first,
            );
            setState(() {
              _exercises.add(_PlanExerciseEntry(
                exerciseId: exerciseId,
                name: name,
                muscleGroup: ex.primaryMuscleGroup,
              ));
            });
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _replaceExercise(int index) {
    final c = AppColors.of(context);
    ref.read(exerciseSearchQueryProvider.notifier).state = '';
    ref.read(exerciseMuscleFilterProvider.notifier).state = null;

    final excludeIds = _exercises
        .asMap()
        .entries
        .where((e) => e.key != index)
        .map((e) => e.value.exerciseId)
        .toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => ExercisePickerSheet(
          scrollController: scrollController,
          excludeIds: excludeIds,
          onSelect: (exerciseId, name) async {
            final db = ref.read(databaseProvider);
            final allEx = await db.exerciseDao.getAll();
            final ex = allEx.firstWhere(
              (e) => e.id == exerciseId,
              orElse: () => allEx.first,
            );
            setState(() {
              final oldEntry = _exercises[index];
              _exercises[index] = _PlanExerciseEntry(
                exerciseId: exerciseId,
                name: name,
                muscleGroup: ex.primaryMuscleGroup,
                targetSets: oldEntry.targetSets,
              );
            });
            if (context.mounted) Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _savePlan() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte einen Plannamen eingeben')),
      );
      return;
    }
    if (_exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mindestens eine Übung hinzufügen')),
      );
      return;
    }

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);

    if (widget.planId != null) {
      await db.planDao.updatePlan(widget.planId!, name: name);
      await db.planDao.replacePlanExercises(
        widget.planId!,
        _exercises
            .map((e) =>
                (exerciseId: e.exerciseId, targetSets: e.targetSets))
            .toList(),
      );
    } else {
      final planId = await db.planDao.createPlan(name);
      for (var i = 0; i < _exercises.length; i++) {
        await db.planDao.addExerciseToPlan(
          planId,
          _exercises[i].exerciseId,
          i,
          targetSets: _exercises[i].targetSets,
        );
      }
    }

    ref.invalidate(allPlansProvider);
    if (mounted) context.pop();
  }

  void _showPlanOptions(BuildContext context, AppColors c) {
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
                    _sharePlan();
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: c.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: c.accent.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.share_outlined,
                            color: c.accent, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Plan teilen',
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
                const SizedBox(height: 8),
                TapScale(
                  onTap: () {
                    Navigator.pop(context);
                    _deletePlan();
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
                        Icon(Icons.delete_outline,
                            color: c.error, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Plan löschen',
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

  Future<void> _sharePlan() async {
    final db = ref.read(databaseProvider);
    final allExercises = await db.exerciseDao.getAll();

    final shareableExercises = _exercises.map((entry) {
      final exercise = allExercises.firstWhere(
        (e) => e.id == entry.exerciseId,
        orElse: () => allExercises.first,
      );
      return ShareableExercise(
        nameKey: exercise.nameKey,
        targetSets: entry.targetSets,
        isCustom: exercise.isCustom,
        customName: exercise.isCustom ? exercise.name : null,
        muscleGroup: exercise.isCustom ? exercise.primaryMuscleGroup : null,
        category: exercise.isCustom ? exercise.category : null,
      );
    }).toList();

    final encoded = PlanSharingService.encodePlan(
      _nameController.text.trim(),
      shareableExercises,
    );
    final url = PlanSharingService.buildShareUrl(encoded);
    await Share.share(url);
  }

  Future<void> _deletePlan() async {
    final c = AppColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.card,
        title: const Text('Plan löschen?'),
        content: const Text('Das kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Löschen', style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.planDao.deletePlan(widget.planId!);
      ref.invalidate(allPlansProvider);
      if (mounted) context.pop();
    }
  }
}

class _ExerciseRow extends StatelessWidget {
  final _PlanExerciseEntry entry;
  final int index;
  final VoidCallback onRemove;
  final ValueChanged<int> onTargetSetsChanged;
  final VoidCallback onReplace;

  const _ExerciseRow({
    super.key,
    required this.entry,
    required this.index,
    required this.onRemove,
    required this.onTargetSetsChanged,
    required this.onReplace,
  });

  Color _muscleColor() {
    if (entry.muscleGroup == null) return const Color(0xFF888888);
    final mg = MuscleGroup.values.where((m) => m.name == entry.muscleGroup);
    return mg.isNotEmpty ? mg.first.color : const Color(0xFF888888);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final muscleColor = _muscleColor();

    return Dismissible(
      key: ValueKey('dismiss_${entry.exerciseId}_$index'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: c.error.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: c.error, size: 22),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            // Numbered badge (also the drag listener)
            ReorderableDragStartListener(
              index: index - 1,
              child: Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: c.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            // Muscle group dot + exercise name (tappable to replace)
            Expanded(
              child: GestureDetector(
                onTap: onReplace,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: muscleColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          color: c.textPrimary,
                          fontWeight: FontWeight.w500,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Pill-style set counter
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: c.elevated,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (entry.targetSets > 1) {
                        onTargetSetsChanged(entry.targetSets - 1);
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(
                        Icons.chevron_left,
                        color: entry.targetSets > 1
                            ? c.textSecondary
                            : c.border,
                        size: 18,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${entry.targetSets}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onTargetSetsChanged(entry.targetSets + 1),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Icon(Icons.chevron_right,
                          color: c.textSecondary, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientNameField extends StatefulWidget {
  final TextEditingController controller;
  final AppColors colors;

  const _GradientNameField({
    required this.controller,
    required this.colors,
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
                hintText: 'Planname',
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
