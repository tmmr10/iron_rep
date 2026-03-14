import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/user_settings_table.dart';

part 'settings_dao.g.dart';

@DriftAccessor(tables: [UserSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase>
    with _$SettingsDaoMixin {
  SettingsDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(userSettings)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) async {
    await into(userSettings).insertOnConflictUpdate(
      UserSettingsCompanion.insert(key: key, value: value),
    );
  }

  Stream<String?> watchValue(String key) {
    return (select(userSettings)..where((t) => t.key.equals(key)))
        .watchSingleOrNull()
        .map((row) => row?.value);
  }

  Future<Map<String, String>> getAll() async {
    final rows = await select(userSettings).get();
    return {for (final r in rows) r.key: r.value};
  }
}
