import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/exercises_table.dart';
import 'tables/exercise_equipment_table.dart';
import 'tables/workouts_table.dart';
import 'tables/workout_exercises_table.dart';
import 'tables/sets_table.dart';
import 'tables/personal_records_table.dart';
import 'tables/user_settings_table.dart';
import 'daos/exercise_dao.dart';
import 'daos/workout_dao.dart';
import 'daos/stats_dao.dart';
import 'daos/settings_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Exercises,
    ExerciseEquipment,
    Workouts,
    WorkoutExercises,
    WorkoutSets,
    PersonalRecords,
    UserSettings,
  ],
  daos: [ExerciseDao, WorkoutDao, StatsDao, SettingsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
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
