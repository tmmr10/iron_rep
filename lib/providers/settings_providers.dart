import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import 'database_provider.dart';

class AppSettings {
  final WeightUnit weightUnit;
  final int defaultRestSeconds;
  final bool adsRemoved;
  final ThemeMode themeMode;
  final String? userName;

  const AppSettings({
    this.weightUnit = WeightUnit.kg,
    this.defaultRestSeconds = 90,
    this.adsRemoved = false,
    this.themeMode = ThemeMode.dark,
    this.userName,
  });
}

final settingsProvider = FutureProvider<AppSettings>((ref) async {
  final db = ref.watch(databaseProvider);
  final dao = db.settingsDao;

  final unit = await dao.getValue('weight_unit');
  final rest = await dao.getValue('default_rest_seconds');
  final ads = await dao.getValue('ads_removed');
  final theme = await dao.getValue('theme_mode');
  final name = await dao.getValue('user_name');

  return AppSettings(
    weightUnit: unit == 'lbs' ? WeightUnit.lbs : WeightUnit.kg,
    defaultRestSeconds: int.tryParse(rest ?? '') ?? 90,
    adsRemoved: ads == 'true',
    themeMode: _parseThemeMode(theme),
    userName: (name != null && name.isNotEmpty) ? name : null,
  );
});

ThemeMode _parseThemeMode(String? value) {
  switch (value) {
    case 'light':
      return ThemeMode.light;
    case 'system':
      return ThemeMode.system;
    default:
      return ThemeMode.dark;
  }
}

final weightUnitProvider = FutureProvider<WeightUnit>((ref) async {
  final settings = await ref.watch(settingsProvider.future);
  return settings.weightUnit;
});

final themeModeProvider = Provider<ThemeMode>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.valueOrNull?.themeMode ?? ThemeMode.dark;
});

final userNameProvider = Provider<String?>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.valueOrNull?.userName;
});

/// Whether settings have finished loading from the database.
final settingsLoadedProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider);
  return settings.hasValue;
});
