import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'database/app_database.dart';
import 'database/seed/exercise_seed_data.dart';
import 'database/seed/plan_seed_data.dart';
// WorkoutHistorySeed removed — users start with a clean slate
import 'shared/design_system.dart';
import 'services/ad_service.dart';
import 'services/timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Prevent Google Fonts from downloading over network (crashes on real devices)
  IronRepTheme.init();

  await initializeDateFormatting('de_DE');
  await initializeDateFormatting('en_US');

  // Detect system language for seed data
  final systemLocale = PlatformDispatcher.instance.locale.languageCode;

  try {
    final db = AppDatabase.instance;
    await ExerciseSeedData.seed(db, locale: systemLocale);
    await ExerciseSeedData.seedMissing(db, locale: systemLocale);
    await PlanSeedData.seed(db);
  } catch (_) {}

  try {
    await AdService.initialize();
  } catch (e) {
    debugPrint('AdService init failed: $e');
  }

  try {
    await TimerService.initialize();
  } catch (_) {}

  runApp(const ProviderScope(child: IronRepApp()));
}
