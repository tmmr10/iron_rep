import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../../l10n/enum_labels.dart';
import '../../l10n/l10n_helper.dart';
import '../../models/exercise.dart';
import '../../providers/database_provider.dart';
import '../../providers/exercise_providers.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/muscle_group_chip.dart';
import '../../shared/widgets/tap_scale.dart';
import 'edit_exercise_sheet.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  final int exerciseId;

  const ExerciseDetailScreen({super.key, required this.exerciseId});

  Future<void> _pickImage(BuildContext context, WidgetRef ref) async {
    final c = AppColors.of(context);
    final l = context.l10n;
    final exercise =
        ref.read(exerciseWithEquipmentProvider(exerciseId)).valueOrNull;
    final hasCustomImage = exercise?.imagePath != null;

    final source = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
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
                    onTap: () => Navigator.pop(ctx, 'camera'),
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
                          Icon(Icons.camera_alt, color: c.accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l.cameraPhoto,
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
                    onTap: () => Navigator.pop(ctx, 'gallery'),
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
                          Icon(Icons.photo_library, color: c.accent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            l.galleryPhoto,
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
                  if (hasCustomImage) ...[
                    const SizedBox(height: 8),
                    TapScale(
                      onTap: () => Navigator.pop(ctx, 'remove'),
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
                            Icon(Icons.delete_outline, color: c.error, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              l.removePhoto,
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
                ],
              ),
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final db = ref.read(databaseProvider);

    if (source == 'remove') {
      final exercise =
          ref.read(exerciseWithEquipmentProvider(exerciseId)).valueOrNull;
      if (exercise?.imagePath != null) {
        final file = File(exercise!.imagePath!);
        if (await file.exists()) await file.delete();
      }
      await db.exerciseDao.updateExerciseImage(exerciseId, null);
      ref.invalidate(exerciseWithEquipmentProvider(exerciseId));
      return;
    }

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source == 'camera' ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 800,
      imageQuality: 85,
    );

    if (picked == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    final imageDir = Directory(p.join(appDir.path, 'exercise_images'));
    if (!await imageDir.exists()) await imageDir.create(recursive: true);

    final destPath = p.join(imageDir.path, '$exerciseId.jpg');
    final destFile = File(destPath);
    // Evict old cached image before overwriting
    if (await destFile.exists()) {
      FileImage(destFile).evict();
    }
    await File(picked.path).copy(destPath);

    await db.exerciseDao.updateExerciseImage(exerciseId, destPath);
    ref.invalidate(exerciseWithEquipmentProvider(exerciseId));
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppColors c) async {
    final l = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: c.surface,
        title: Text(l.deleteExerciseConfirm,
            style: TextStyle(color: c.textPrimary)),
        content: Text(
            l.deleteExerciseMessage,
            style: TextStyle(color: c.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.delete, style: TextStyle(color: c.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final db = ref.read(databaseProvider);
      await db.exerciseDao.softDeleteExercise(exerciseId);
      ref.invalidate(allExercisesProvider);
      ref.invalidate(filteredExercisesProvider);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final l = context.l10n;
    final exerciseAsync = ref.watch(exerciseWithEquipmentProvider(exerciseId));

    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
        actions: [
          exerciseAsync.whenOrNull(
                data: (exercise) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      child: Text(l.edit,
                          style: TextStyle(color: c.accent, fontWeight: FontWeight.w600)),
                      onPressed: () async {
                        final saved = await showModalBottomSheet<bool>(
                          context: context,
                          isScrollControlled: true,
                          isDismissible: false,
                          enableDrag: false,
                          backgroundColor: Colors.transparent,
                          builder: (_) => DraggableScrollableSheet(
                            initialChildSize: 0.85,
                            minChildSize: 0.5,
                            maxChildSize: 0.95,
                            builder: (ctx, scrollController) => Container(
                              decoration: BoxDecoration(
                                color: c.surface,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(20)),
                              ),
                              child: EditExerciseSheet(
                                exercise: exercise,
                                scrollController: scrollController,
                              ),
                            ),
                          ),
                        );
                        if (saved == true) {
                          ref.invalidate(
                              exerciseWithEquipmentProvider(exerciseId));
                        }
                      },
                    ),
                    TextButton(
                      onPressed: () => _confirmDelete(context, ref, c),
                      child: Text(l.delete,
                          style: TextStyle(color: c.error, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: exerciseAsync.when(
        data: (exercise) => ListView(
          padding: IronRepSpacing.screenPadding,
          children: [
            GestureDetector(
              onTap: () => _pickImage(context, ref),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: c.elevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: c.border.withValues(alpha: 0.3),
                  ),
                ),
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildExerciseImage(exercise, c, l),
                  ),
                ),
              ),
            ),

            // Name
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: [c.accentGradientStart, c.accentGradientEnd],
              ).createShader(bounds),
              blendMode: BlendMode.srcIn,
              child: Text(
                exercise.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tags
            Row(
              children: [
                MuscleGroupChip(
                    muscleGroup: exercise.muscleGroup, isSelected: true),
              ],
            ),

            // Instructions
            if (exercise.instructions != null) ...[
              const SizedBox(height: 24),
              Text(
                l.instructions,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                exercise.instructions!,
                style: TextStyle(
                  color: c.textPrimary,
                  height: 1.5,
                  fontSize: 15,
                ),
              ),
            ],

            // Equipment
            if (exercise.equipment.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                l.equipment,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: exercise.equipment
                    .map((e) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: c.elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            e.localizedLabel(context),
                            style: TextStyle(
                                color: c.textPrimary, fontSize: 13),
                          ),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () =>
                  context.push('/exercise-progress/$exerciseId'),
              icon: const Icon(Icons.show_chart),
              label: Text(l.progressButton),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.accent,
                side: BorderSide(color: c.accent),
              ),
            ),
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l.error('$e'))),
      ),
    );
  }

  Widget _buildExerciseImage(ExerciseWithEquipment exercise, AppColors c, AppLocalizations l) {
    // Priority 1: Custom image from file system
    if (exercise.imagePath != null) {
      return Image.file(
        File(exercise.imagePath!),
        width: 160,
        height: 160,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(c, l),
      );
    }

    // Priority 2: Asset image
    return Image.asset(
      'assets/exercises/${exercise.nameKey}.jpg',
      width: 160,
      height: 160,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(c, l),
    );
  }

  Widget _buildPlaceholder(AppColors c, AppLocalizations l) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_a_photo,
              color: c.textMuted.withValues(alpha: 0.4), size: 36),
          const SizedBox(height: 8),
          Text(
            l.addPhoto,
            style: TextStyle(
              color: c.textMuted.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
