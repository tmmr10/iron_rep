import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../providers/settings_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/plan_providers.dart';
import '../../models/enums.dart';
import '../../services/backup_service.dart';
import '../../shared/design_system.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/tap_scale.dart';
import '../../l10n/l10n_helper.dart';
import '../../utils/screenshot_tour.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.navMore)),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            SectionHeader(title: context.l10n.settings),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  iconColor: c.textSecondary,
                  title: context.l10n.name,
                  trailing: Text(
                    settings.userName ?? context.l10n.notSet,
                    style: TextStyle(
                      color: settings.userName != null ? c.accent : c.textMuted,
                    ),
                  ),
                  onTap: () => _showNameEditor(context, ref, settings.userName),
                ),
                _SettingsTile(
                  icon: Icons.straighten,
                  iconColor: c.textSecondary,
                  title: context.l10n.weightUnit,
                  trailing: Text(
                    settings.weightUnit.label,
                    style: TextStyle(color: c.accent),
                  ),
                  onTap: () => _showUnitPicker(context, ref, settings.weightUnit),
                ),
                _SettingsTile(
                  icon: Icons.timer,
                  iconColor: c.textSecondary,
                  title: context.l10n.defaultRestTime,
                  trailing: Text(
                    '${settings.defaultRestSeconds}s',
                    style: TextStyle(color: c.accent),
                  ),
                  onTap: () =>
                      _showRestTimePicker(context, ref, settings.defaultRestSeconds),
                ),
              ],
            ),
            const SizedBox(height: IronRepSpacing.xl),
            SectionHeader(title: context.l10n.appearance),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.palette_outlined,
                  iconColor: c.textSecondary,
                  title: context.l10n.design,
                  trailing: Text(
                    _themeModeLabel(context, settings.themeMode),
                    style: TextStyle(color: c.accent),
                  ),
                  onTap: () => _showThemePicker(context, ref, settings.themeMode),
                ),
                _SettingsTile(
                  icon: Icons.language,
                  iconColor: c.textSecondary,
                  title: context.l10n.language,
                  trailing: Text(
                    _localeLabel(context, settings.localeOverride),
                    style: TextStyle(color: c.accent),
                  ),
                  onTap: () => _showLocalePicker(context, ref, settings.localeOverride),
                ),
              ],
            ),
            const SizedBox(height: IronRepSpacing.xl),
            SectionHeader(title: context.l10n.plansAndExercises),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.list_alt,
                  iconColor: c.accent,
                  title: context.l10n.managePlans,
                  trailing: Icon(Icons.chevron_right,
                      color: c.textMuted, size: 20),
                  onTap: () => _showManagePlans(context, ref),
                ),
                _SettingsTile(
                  icon: Icons.fitness_center,
                  iconColor: c.accent,
                  title: context.l10n.manageExercises,
                  trailing: Icon(Icons.chevron_right,
                      color: c.textMuted, size: 20),
                  onTap: () => context.push('/exercises'),
                ),
              ],
            ),
            const SizedBox(height: IronRepSpacing.xl),
            SectionHeader(title: context.l10n.backupData),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.upload,
                  iconColor: c.accent,
                  title: context.l10n.backupExport,
                  trailing: Icon(Icons.chevron_right,
                      color: c.textMuted, size: 20),
                  onTap: () => context.push('/backup-export'),
                ),
                _SettingsTile(
                  icon: Icons.download,
                  iconColor: c.accent,
                  title: context.l10n.backupImport,
                  trailing: Icon(Icons.chevron_right,
                      color: c.textMuted, size: 20),
                  onTap: () => _importData(context),
                ),
              ],
            ),

            const SizedBox(height: IronRepSpacing.xl),
            SectionHeader(title: context.l10n.pro),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.block,
                  iconColor: c.accent,
                  title: context.l10n.removeAds,
                  trailing: settings.adsRemoved
                      ? Icon(Icons.check, color: c.success)
                      : Text('€2.99',
                          style: TextStyle(color: c.accent)),
                  onTap: settings.adsRemoved
                      ? null
                      : () => context.push('/remove-ads'),
                ),
              ],
            ),
            const SizedBox(height: IronRepSpacing.xl),
            SectionHeader(title: context.l10n.about),
            _SettingsGroup(
              tiles: [
                _SettingsTile(
                  icon: Icons.info_outline,
                  iconColor: c.textSecondary,
                  title: context.l10n.version,
                  trailing: Text('1.0.0',
                      style: TextStyle(color: c.textSecondary)),
                ),
                _SettingsTile(
                  icon: Icons.code,
                  iconColor: c.textSecondary,
                  title: context.l10n.openSourceLicenses,
                  trailing: Icon(Icons.chevron_right,
                      color: c.textMuted, size: 20),
                  onTap: () => context.push('/licenses'),
                ),
              ],
            ),
            if (kDebugMode) ...[
              const SizedBox(height: IronRepSpacing.xl),
              SectionHeader(title: 'Debug'),
              _SettingsGroup(
                tiles: [
                  _SettingsTile(
                    icon: Icons.camera_alt,
                    iconColor: c.accent,
                    title: 'Screenshot Tour',
                    trailing: Icon(Icons.play_arrow,
                        color: c.accent, size: 20),
                    onTap: () => runScreenshotTour(context, ref),
                  ),
                ],
              ),
            ],
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.error('$e'))),
      ),
    );
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return context.l10n.dark;
      case ThemeMode.light:
        return context.l10n.light;
      case ThemeMode.system:
        return context.l10n.system;
    }
  }

  String _localeLabel(BuildContext context, String? localeOverride) {
    switch (localeOverride) {
      case 'de':
        return context.l10n.languageGerman;
      case 'en':
        return context.l10n.languageEnglish;
      default:
        return context.l10n.languageSystem;
    }
  }

  void _showLocalePicker(
      BuildContext context, WidgetRef ref, String? current) {
    final c = AppColors.of(context);
    final options = [
      (null, context.l10n.languageSystem, ''),
      ('de', context.l10n.languageGerman, 'de'),
      ('en', context.l10n.languageEnglish, 'en'),
    ];
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: c.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return ListTile(
              title: Text(opt.$2,
                  style: TextStyle(color: c.textPrimary)),
              trailing: opt.$1 == current
                  ? Icon(Icons.check, color: c.accent)
                  : null,
              onTap: () async {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                await Future.delayed(const Duration(milliseconds: 300));
                final db = ref.read(databaseProvider);
                await db.settingsDao.setValue('locale', opt.$3);
                ref.invalidate(settingsProvider);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showThemePicker(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    final c = AppColors.of(context);
    final options = [
      (ThemeMode.dark, context.l10n.dark, 'dark'),
      (ThemeMode.light, context.l10n.light, 'light'),
      (ThemeMode.system, context.l10n.system, 'system'),
    ];
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: c.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            return ListTile(
              title: Text(opt.$2,
                  style: TextStyle(color: c.textPrimary)),
              trailing: opt.$1 == current
                  ? Icon(Icons.check, color: c.accent)
                  : null,
              onTap: () async {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                await Future.delayed(const Duration(milliseconds: 300));
                final db = ref.read(databaseProvider);
                await db.settingsDao.setValue('theme_mode', opt.$3);
                ref.invalidate(settingsProvider);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showUnitPicker(
      BuildContext context, WidgetRef ref, WeightUnit current) {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: c.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: WeightUnit.values.map((u) {
            return ListTile(
              title: Text(u.label,
                  style: TextStyle(color: c.textPrimary)),
              trailing: u == current
                  ? Icon(Icons.check, color: c.accent)
                  : null,
              onTap: () async {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                await Future.delayed(const Duration(milliseconds: 300));
                final db = ref.read(databaseProvider);
                await db.settingsDao.setValue('weight_unit', u.name);
                ref.invalidate(settingsProvider);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showManagePlans(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final plans = ref.read(allPlansProvider);
    final router = GoRouter.of(context);
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: c.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(context.l10n.managePlans,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  )),
            ),
            ...plans.valueOrNull?.map((plan) => ListTile(
                      title: Text(plan.name,
                          style: TextStyle(color: c.textPrimary)),
                      trailing: Icon(Icons.edit_outlined,
                          color: c.textMuted, size: 20),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        router.push('/plan-editor', extra: plan.id);
                      },
                    )) ??
                [],
            ListTile(
              leading: Icon(Icons.add, color: c.accent),
              title: Text(context.l10n.createNewPlan,
                  style: TextStyle(color: c.accent)),
              onTap: () {
                Navigator.pop(sheetContext);
                router.push('/plan-editor');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportData(BuildContext context, WidgetRef ref) async {
    final c = AppColors.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    // Get share position for iPad popover
    final box = context.findRenderObject() as RenderBox?;
    final shareOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : const Rect.fromLTWH(0, 0, 100, 100);

    // Show loading overlay
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: c.accent),
                const SizedBox(height: 20),
                Text(
                  context.l10n.backupExportProgress,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final db = ref.read(databaseProvider);
      final file = await BackupService.exportToFile(db);
      if (context.mounted) navigator.pop();
      await Share.shareXFiles(
        [XFile(file.path)],
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      if (context.mounted) {
        navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.error('$e'))),
        );
      }
    }
  }

  void _importData(BuildContext context) async {
    final c = AppColors.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);

    // Show loading overlay while file picker opens
    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(40),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: c.accent),
                const SizedBox(height: 20),
                Text(
                  context.l10n.backupImport,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    const channel = MethodChannel('com.tmmr.iron_rep/backup');
    try {
      final path = await channel.invokeMethod<String>('pickBackupFile');
      if (context.mounted) navigator.pop();
      if (path != null && context.mounted) {
        context.push('/backup-import', extra: path);
      }
    } catch (e) {
      if (context.mounted) {
        navigator.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.error('$e'))),
        );
      }
    }
  }

  void _showNameEditor(
      BuildContext context, WidgetRef ref, String? currentName) {
    final c = AppColors.of(context);
    final controller = TextEditingController(text: currentName ?? '');
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: c.surface,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.l10n.name,
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                )),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: c.textPrimary, fontSize: 16),
              decoration: InputDecoration(
                labelText: context.l10n.name,
                hintText: context.l10n.yourNameHint,
              ),
              onSubmitted: (value) async {
                final trimmed = value.trim();
                final db = ref.read(databaseProvider);
                await db.settingsDao.setValue(
                    'user_name', trimmed.isEmpty ? '' : trimmed);
                ref.invalidate(settingsProvider);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () async {
                final trimmed = controller.text.trim();
                final db = ref.read(databaseProvider);
                await db.settingsDao.setValue(
                    'user_name', trimmed.isEmpty ? '' : trimmed);
                ref.invalidate(settingsProvider);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              child: Text(context.l10n.save,
                  style: TextStyle(color: c.accent, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRestTimePicker(
      BuildContext context, WidgetRef ref, int current) {
    final c = AppColors.of(context);
    final options = [30, 60, 90, 120, 180];
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: c.surface,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((secs) {
            return ListTile(
              title: Text('${secs}s',
                  style: TextStyle(color: c.textPrimary)),
              trailing: secs == current
                  ? Icon(Icons.check, color: c.accent)
                  : null,
              onTap: () async {
                Navigator.of(sheetContext, rootNavigator: true).pop();
                await Future.delayed(const Duration(milliseconds: 300));
                final db = ref.read(databaseProvider);
                await db.settingsDao
                    .setValue('default_rest_seconds', '$secs');
                ref.invalidate(settingsProvider);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<_SettingsTile> tiles;

  const _SettingsGroup({required this.tiles});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: c.border.withValues(alpha: 0.3)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < tiles.length; i++) ...[
            tiles[i],
            if (i < tiles.length - 1)
              Divider(
                height: 1,
                thickness: 1,
                indent: 52,
                color: c.border.withValues(alpha: 0.2),
              ),
          ],
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    this.iconColor,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return TapScale(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? c.textSecondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: c.textPrimary, fontSize: 16),
              ),
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
