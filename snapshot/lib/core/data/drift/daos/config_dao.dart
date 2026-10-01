import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/config.dart';

part 'config_dao.g.dart';

@DriftAccessor(tables: [Config])
class ConfigDao extends DatabaseAccessor<AppDatabase> with _$ConfigDaoMixin {
  ConfigDao(super.db);

  Future<String?> getValue(String key) async {
    final row = await (select(config)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) async {
    await into(config).insertOnConflictUpdate(
      ConfigCompanion(
        key: Value(key),
        value: Value(value),
      ),
    );
  }

  Future<Map<String, String>> getAll() async {
    final rows = await select(config).get();
    return {for (final row in rows) row.key: row.value};
  }

  // Convenience typed accessors
  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final val = await getValue(key);
    return val == 'true' ? true : (val == 'false' ? false : defaultValue);
  }

  Future<double?> getDouble(String key) async {
    final val = await getValue(key);
    return val != null ? double.tryParse(val) : null;
  }

  Future<void> setBool(String key, bool value) async {
    await setValue(key, value.toString());
  }

  Future<void> setDouble(String key, double value) async {
    await setValue(key, value.toString());
  }
}
