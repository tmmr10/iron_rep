import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'database/app_database.dart';
import 'database/seed/exercise_seed_data.dart';
import 'services/ad_service.dart';
import 'services/timer_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase.instance;
  await ExerciseSeedData.seed(db);

  await TimerService.initialize();
  await AdService.initialize();

  runApp(const ProviderScope(child: IronRepApp()));
}
