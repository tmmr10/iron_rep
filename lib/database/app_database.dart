import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/exercises_table.dart';
import 'tables/exercise_equipment_table.dart';
import 'tables/training_plans_table.dart';
import 'tables/plan_exercises_table.dart';
import 'tables/workouts_table.dart';
import 'tables/workout_exercises_table.dart';
import 'tables/sets_table.dart';
import 'tables/personal_records_table.dart';
import 'seed/exercise_seed_data.dart';
import 'tables/user_settings_table.dart';
import 'daos/exercise_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/plan_dao.dart';
import 'daos/stats_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    ExerciseEquipment,
    TrainingPlans,
    PlanExercises,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    PersonalRecords,
    UserSettings,
  ],
  daos: [ExerciseDao, WorkoutDao, PlanDao, StatsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(trainingPlans);
            await m.createTable(planExercises);
            await m.addColumn(workouts, workouts.planId);
          }
          if (from < 3) {
            // Translate exercise names to German
            for (final entry in ExerciseSeedData.nameTranslations.entries) {
              await customStatement(
                'UPDATE exercises SET name = ? WHERE name = ?',
                [entry.value, entry.key],
              );
            }
            // Translate plan names to German
            await customStatement(
              'UPDATE training_plans SET name = ? WHERE name = ?',
              ['Oberkörper', 'Upper Body'],
            );
            await customStatement(
              'UPDATE training_plans SET name = ? WHERE name = ?',
              ['Unterkörper', 'Lower Body'],
            );
            await customStatement(
              'UPDATE training_plans SET name = ? WHERE name = ?',
              ['Ganzkörper', 'Full Body'],
            );
          }
          if (from < 4) {
            await m.addColumn(exercises, exercises.trackWeight);
            // Set trackWeight=false for bodyweight & cardio exercises
            await customStatement(
              "UPDATE exercises SET track_weight = 0 WHERE name_key IN ('push_ups', 'pull_ups', 'plank', 'hanging_leg_raise', 'ab_rollout', 'nordic_curl', 'glute_bridge', 'treadmill_run', 'rowing_machine', 'stationary_bike', 'elliptical')",
            );
            // Set trackWeight=false for custom exercises containing "Rückenstrecker" or "Rückstrecker"
            await customStatement(
              "UPDATE exercises SET track_weight = 0 WHERE name LIKE '%ückenstreck%' OR name LIKE '%ückstreck%'",
            );
            // Replace Kabelzug-Crunch with Crunches am Halbball
            await customStatement(
              "UPDATE exercises SET name = 'Crunches am Halbball', name_key = 'bosu_crunch', instructions = 'Rücken auf dem Halbball (Bosu Ball), Bauchmuskeln anspannen und Oberkörper aufrollen.', track_weight = 0 WHERE name_key = 'cable_crunch'",
            );
            // Update equipment for the replaced exercise
            await customStatement(
              "UPDATE exercise_equipment SET equipment_type = 'bodyweight' WHERE exercise_id = (SELECT id FROM exercises WHERE name_key = 'bosu_crunch')",
            );
          }
          if (from < 5) {
            // Langhantel Curls → Bizeps Maschine
            await customStatement(
              "UPDATE exercises SET name = 'Bizeps Maschine', name_key = 'bicep_machine' WHERE name_key = 'barbell_curl'",
            );
            await customStatement(
              "UPDATE exercise_equipment SET equipment_type = 'machine' WHERE exercise_id = (SELECT id FROM exercises WHERE name_key = 'bicep_machine')",
            );
            // Langhantel-Rudern → Rudern Stange
            await customStatement(
              "UPDATE exercises SET name = 'Rudern Stange' WHERE name_key = 'barbell_row'",
            );
            // Kabelrudern sitzend → Rudern Dreieck
            await customStatement(
              "UPDATE exercises SET name = 'Rudern Dreieck' WHERE name_key = 'seated_cable_row'",
            );
            // Maschinen-Brustpresse → Brustpresse
            await customStatement(
              "UPDATE exercises SET name = 'Brustpresse' WHERE name_key = 'machine_chest_press'",
            );
            // Reverse Flys → Reverse Fly (singular)
            await customStatement(
              "UPDATE exercises SET name = 'Reverse Fly' WHERE name_key = 'reverse_fly'",
            );
          }
          if (from < 7) {
            // Rückenstrecker: alle Gewichte löschen (hat kein Gewicht)
            await customStatement('''
              UPDATE workout_sets SET weight = NULL
              WHERE workout_exercise_id IN (
                SELECT we.id FROM workout_exercises we
                JOIN exercises e ON we.exercise_id = e.id
                WHERE e.name LIKE '%ückenstreck%' OR e.name LIKE '%ückstreck%'
              )
            ''');
            // Rückenstrecker: Personal Records löschen
            await customStatement('''
              DELETE FROM personal_records
              WHERE exercise_id IN (
                SELECT id FROM exercises
                WHERE name LIKE '%ückenstreck%' OR name LIKE '%ückstreck%'
              )
            ''');
            // Bizeps Maschine: alte Langhantel-Curls Daten löschen (Gewicht < 20kg = alte Barbell-Daten)
            await customStatement('''
              UPDATE workout_sets SET weight = NULL
              WHERE weight < 20 AND weight IS NOT NULL AND workout_exercise_id IN (
                SELECT we.id FROM workout_exercises we
                JOIN exercises e ON we.exercise_id = e.id
                WHERE e.name_key = 'bicep_machine'
              )
            ''');
            // Bizeps Maschine: Personal Records neu berechnen lassen
            await customStatement('''
              DELETE FROM personal_records
              WHERE exercise_id IN (
                SELECT id FROM exercises WHERE name_key = 'bicep_machine'
              )
            ''');
          }
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'iron_rep.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
