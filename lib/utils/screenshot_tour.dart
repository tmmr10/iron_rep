import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../database/app_database.dart';
import '../providers/database_provider.dart';

/// Global flag to hide ads during screenshot tour.
final screenshotModeProvider = StateProvider<bool>((ref) => false);

/// Runs a screenshot tour through the app's main screens.
Future<void> runScreenshotTour(BuildContext context, WidgetRef ref) async {
  print('>>> SCREENSHOT_TOUR_START');

  // Hide ads during tour
  ref.read(screenshotModeProvider.notifier).state = true;

  final router = GoRouter.of(context);

  // Write marker files to Documents dir so the capture script can detect them
  final docsDir = await getApplicationDocumentsDirectory();
  final markerDir = Directory('${docsDir.path}/screenshot_markers');
  if (markerDir.existsSync()) markerDir.deleteSync(recursive: true);
  markerDir.createSync();

  Future<void> writeMarker(String name) async {
    File('${markerDir.path}/$name').writeAsStringSync('ready');
    print('>>> SCREENSHOT_READY:$name');
  }

  // Find exercise with most history data for the progress screen
  final db = ref.read(databaseProvider);
  final exercises = await db.exerciseDao.getAll();
  // Use incline_dumbbell_press (Schrägbankdrücken) — has clear progression in seed data
  final progressExercise = exercises.firstWhere(
    (e) => e.nameKey == 'incline_dumbbell_press',
    orElse: () => exercises.first,
  );

  // Simple wait helper — endOfFrame doesn't work without flutter attach
  Future<void> settle(int ms) => Future<void>.delayed(Duration(milliseconds: ms));

  // --- 01: Workout Tab (home screen with stats + plans) ---
  router.go('/workout');
  await settle(4000);
  await writeMarker('01_workout');
  await settle(1000);

  // --- 02: History Tab (calendar with workouts) ---
  router.go('/history');
  await settle(3000);
  await writeMarker('02_history');
  await settle(1000);

  // --- 03: Progress Tab (charts + muscle distribution) ---
  router.go('/progress');
  await settle(3000);
  await writeMarker('03_progress');
  await settle(1000);

  // --- 04: Exercises Library ---
  router.push('/exercises');
  await settle(3000);
  await writeMarker('04_exercises');
  await settle(1000);

  // Pop back from exercises overlay
  router.pop();
  await settle(1000);

  // --- 05: Exercise Progress (exercise with good data) ---
  router.push('/exercise-progress/${progressExercise.id}');
  await settle(3000);
  await writeMarker('05_exercise_progress');
  await settle(1000);

  // Pop back
  router.pop();
  await settle(1000);

  // --- 06: Plan Editor (edit first plan) ---
  router.push('/plan-editor', extra: 1);
  await settle(3000);
  await writeMarker('06_plan_editor');
  await settle(1000);

  // Pop back
  router.pop();
  await settle(500);

  // Return to workout tab
  router.go('/workout');
  await Future<void>.delayed(const Duration(milliseconds: 500));

  // Restore ads
  ref.read(screenshotModeProvider.notifier).state = false;

  // Signal done
  await writeMarker('DONE');
  print('>>> SCREENSHOT_TOUR_DONE');
}
