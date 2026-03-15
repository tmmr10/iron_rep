import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'database/app_database.dart';
import 'database/seed/exercise_seed_data.dart';
import 'database/seed/plan_seed_data.dart';
import 'database/seed/workout_history_seed.dart';
import 'services/ad_service.dart';
import 'services/timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('de_DE');

  final db = AppDatabase.instance;
  await ExerciseSeedData.seed(db);
  await ExerciseSeedData.seedMissing(db);
  await PlanSeedData.seed(db);
  await WorkoutHistorySeed.seed(db);

  await TimerService.initialize();
  await AdService.initialize();

  runApp(const ProviderScope(child: IronRepApp()));
}
