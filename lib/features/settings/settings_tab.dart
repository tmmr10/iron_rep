import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/settings_providers.dart';
import '../../providers/database_provider.dart';
import '../../providers/plan_providers.dart';
import '../../models/enums.dart';
import '../../shared/design_system.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Einstellungen')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            _SectionHeader('Einstellungen'),
            _SettingsTile(
              icon: Icons.person_outline,
              title: 'Name',
              trailing: Text(
                settings.userName ?? 'Nicht gesetzt',
                style: TextStyle(
                  color: settings.userName != null ? c.accent : c.textMuted,
                ),
              ),
              onTap: () => _showNameEditor(context, ref, settings.userName),
            ),
            _SettingsTile(
              icon: Icons.straighten,
              title: 'Gewichtseinheit',
              trailing: Text(
                settings.weightUnit.label,
                style: TextStyle(color: c.accent),
              ),
              onTap: () => _showUnitPicker(context, ref, settings.weightUnit),
            ),
            _SettingsTile(
              icon: Icons.timer,
              title: 'Standard-Pausenzeit',
              trailing: Text(
                '${settings.defaultRestSeconds}s',
                style: TextStyle(color: c.accent),
              ),
              onTap: () =>
                  _showRestTimePicker(context, ref, settings.defaultRestSeconds),
            ),
            const SizedBox(height: IronRepSpacing.xl),
            _SectionHeader('Darstellung'),
            _SettingsTile(
              icon: Icons.palette_outlined,
              title: 'Design',
              trailing: Text(
                _themeModeLabel(settings.themeMode),
                style: TextStyle(color: c.accent),
              ),
              onTap: () => _showThemePicker(context, ref, settings.themeMode),
            ),
            const SizedBox(height: IronRepSpacing.xl),
            _SectionHeader('Pläne & Übungen'),
            _SettingsTile(
              icon: Icons.list_alt,
              title: 'Pläne verwalten',
              trailing: Icon(Icons.chevron_right,
                  color: c.textMuted, size: 20),
              onTap: () => _showManagePlans(context, ref),
            ),
            _SettingsTile(
              icon: Icons.fitness_center,
              title: 'Übungen verwalten',
              trailing: Icon(Icons.chevron_right,
                  color: c.textMuted, size: 20),
              onTap: () => context.push('/exercises'),
            ),
            const SizedBox(height: IronRepSpacing.xl),
            _SectionHeader('Pro'),
            _SettingsTile(
              icon: Icons.block,
              title: 'Werbung entfernen',
              trailing: settings.adsRemoved
                  ? Icon(Icons.check, color: c.success)
                  : Text('€2.99',
                      style: TextStyle(color: c.accent)),
              onTap: settings.adsRemoved
                  ? null
                  : () => context.push('/remove-ads'),
            ),
            const SizedBox(height: IronRepSpacing.xl),
            _SectionHeader('Über'),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'Version',
              trailing: Text('1.0.0',
                  style: TextStyle(color: c.textSecondary)),
            ),
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dunkel';
      case ThemeMode.light:
        return 'Hell';
      case ThemeMode.system:
        return 'System';
    }
  }

  void _showThemePicker(
      BuildContext context, WidgetRef ref, ThemeMode current) {
    final c = AppColors.of(context);
    final options = [
      (ThemeMode.dark, 'Dunkel', 'dark'),
      (ThemeMode.light, 'Hell', 'light'),
      (ThemeMode.system, 'System', 'system'),
    ];
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      builder: (_) => SafeArea(
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
                final db = ref.read(databaseProvider);
                await db.settingsDao.setValue('theme_mode', opt.$3);
                ref.invalidate(settingsProvider);
                if (context.mounted) Navigator.pop(context);
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
      backgroundColor: c.card,
      builder: (_) => SafeArea(
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
                final db = ref.read(databaseProvider);
                await db.settingsDao.setValue('weight_unit', u.name);
                ref.invalidate(settingsProvider);
                if (context.mounted) Navigator.pop(context);
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
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Pläne verwalten',
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
                        Navigator.pop(context);
                        context.push('/plan-editor', extra: plan.id);
                      },
                    )) ??
                [],
            ListTile(
              leading: Icon(Icons.add, color: c.accent),
              title: Text('Neuen Plan erstellen',
                  style: TextStyle(color: c.accent)),
              onTap: () {
                Navigator.pop(context);
                context.push('/plan-editor');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNameEditor(
      BuildContext context, WidgetRef ref, String? currentName) {
    final c = AppColors.of(context);
    final controller = TextEditingController(text: currentName ?? '');
    showModalBottomSheet(
      context: context,
      backgroundColor: c.card,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Name',
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                )),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              style: TextStyle(color: c.textPrimary),
              decoration: InputDecoration(
                hintText: 'Dein Name',
                hintStyle: TextStyle(color: c.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: c.accent),
                ),
              ),
              onSubmitted: (value) async {
                final trimmed = value.trim();
                final db = ref.read(databaseProvider);
                await db.settingsDao.setValue(
                    'user_name', trimmed.isEmpty ? '' : trimmed);
                ref.invalidate(settingsProvider);
                if (context.mounted) Navigator.pop(context);
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
                if (context.mounted) Navigator.pop(context);
              },
              child: Text('Speichern',
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
      backgroundColor: c.card,
      builder: (_) => SafeArea(
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
                final db = ref.read(databaseProvider);
                await db.settingsDao
                    .setValue('default_rest_seconds', '$secs');
                ref.invalidate(settingsProvider);
                if (context.mounted) Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: c.textMuted,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: c.textSecondary, size: 22),
      title: Text(title, style: TextStyle(color: c.textPrimary)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
