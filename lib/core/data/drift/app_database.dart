import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/user_activity_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/user_profile_dao.dart';
import 'package:opennutritracker/core/data/drift/tables/config.dart';
import 'package:opennutritracker/core/data/drift/tables/daily_stats.dart';
import 'package:opennutritracker/core/data/drift/tables/food_items.dart';
import 'package:opennutritracker/core/data/drift/tables/log_entries.dart';
import 'package:opennutritracker/core/data/drift/tables/user_activities.dart';
import 'package:opennutritracker/core/data/drift/tables/user_profile.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [FoodItems, LogEntries, DailyStats, Config, UserProfile, UserActivities],
  daos: [FoodItemDao, LogEntryDao, DailyStatsDao, ConfigDao, UserProfileDao, UserActivityDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          // Create FTS5 virtual table for food item search
          await customStatement(
            'CREATE VIRTUAL TABLE IF NOT EXISTS food_items_fts USING fts5(name, brand, content=food_items, content_rowid=rowid)',
          );
          // Create triggers to keep FTS in sync
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS food_items_ai AFTER INSERT ON food_items BEGIN
              INSERT INTO food_items_fts(rowid, name, brand) VALUES (new.rowid, new.name, new.brand);
            END
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS food_items_ad AFTER DELETE ON food_items BEGIN
              INSERT INTO food_items_fts(food_items_fts, rowid, name, brand) VALUES('delete', old.rowid, old.name, old.brand);
            END
          ''');
          await customStatement('''
            CREATE TRIGGER IF NOT EXISTS food_items_au AFTER UPDATE ON food_items BEGIN
              INSERT INTO food_items_fts(food_items_fts, rowid, name, brand) VALUES('delete', old.rowid, old.name, old.brand);
              INSERT INTO food_items_fts(rowid, name, brand) VALUES (new.rowid, new.name, new.brand);
            END
          ''');
          // Create indexes for common queries
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_log_entries_timestamp ON log_entries(timestamp)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_log_entries_meal_slot ON log_entries(meal_slot)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_food_items_barcode ON food_items(barcode)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_user_activities_date ON user_activities(date)',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await customStatement(
              'ALTER TABLE food_items ADD COLUMN favourite INTEGER NOT NULL DEFAULT 0',
            );
          }
        },
      );

  static AppDatabase create() {
    return AppDatabase(LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'foodtracker.db'));

      // Work around a sqlite3 bug on older iOS versions
      if (Platform.isIOS || Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }

      return NativeDatabase.createInBackground(file);
    }));
  }

  /// For testing only
  static AppDatabase createInMemory() {
    return AppDatabase(NativeDatabase.memory());
  }
}
