import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/settings_providers.dart';
import '../../providers/database_provider.dart';
import '../../models/enums.dart';
import '../../shared/design_system.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: settingsAsync.when(
        data: (settings) => ListView(
          padding: IronRepSpacing.screenPadding,
          children: [
            _SectionHeader('Preferences'),
            _SettingsTile(
              icon: Icons.straighten,
              title: 'Weight Unit',
              trailing: Text(
                settings.weightUnit.label,
                style: const TextStyle(color: IronRepColors.accent),
              ),
              onTap: () => _showUnitPicker(context, ref, settings.weightUnit),
            ),
            _SettingsTile(
              icon: Icons.timer,
              title: 'Default Rest Timer',
              trailing: Text(
                '${settings.defaultRestSeconds}s',
                style: const TextStyle(color: IronRepColors.accent),
              ),
              onTap: () =>
                  _showRestTimePicker(context, ref, settings.defaultRestSeconds),
            ),
            const SizedBox(height: IronRepSpacing.xl),
            _SectionHeader('Pro'),
            _SettingsTile(
              icon: Icons.block,
              title: 'Remove Ads',
              trailing: settings.adsRemoved
                  ? const Icon(Icons.check, color: IronRepColors.success)
                  : const Text('€2.99',
                      style: TextStyle(color: IronRepColors.accent)),
              onTap: settings.adsRemoved
                  ? null
                  : () => context.push('/remove-ads'),
            ),
            const SizedBox(height: IronRepSpacing.xl),
            _SectionHeader('About'),
            _SettingsTile(
              icon: Icons.info_outline,
              title: 'Version',
              trailing: const Text('1.0.0',
                  style: TextStyle(color: IronRepColors.textSecondary)),
            ),
          ],
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  void _showUnitPicker(
      BuildContext context, WidgetRef ref, WeightUnit current) {
    showModalBottomSheet(
      context: context,
      backgroundColor: IronRepColors.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: WeightUnit.values.map((u) {
            return ListTile(
              title: Text(u.label,
                  style:
                      const TextStyle(color: IronRepColors.textPrimary)),
              trailing: u == current
                  ? const Icon(Icons.check, color: IronRepColors.accent)
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

  void _showRestTimePicker(
      BuildContext context, WidgetRef ref, int current) {
    final options = [30, 60, 90, 120, 180];
    showModalBottomSheet(
      context: context,
      backgroundColor: IronRepColors.card,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((secs) {
            return ListTile(
              title: Text('${secs}s',
                  style:
                      const TextStyle(color: IronRepColors.textPrimary)),
              trailing: secs == current
                  ? const Icon(Icons.check, color: IronRepColors.accent)
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: IronRepColors.textMuted,
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: Icon(icon, color: IronRepColors.textSecondary, size: 22),
      title: Text(title,
          style: const TextStyle(color: IronRepColors.textPrimary)),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
