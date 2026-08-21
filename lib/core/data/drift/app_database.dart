import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/label_capture_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/outbox_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/own_row_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/recipe_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/user_activity_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/user_profile_dao.dart';
import 'package:opennutritracker/core/data/drift/tables/config.dart';
import 'package:opennutritracker/core/data/drift/tables/daily_stats.dart';
import 'package:opennutritracker/core/data/drift/tables/food_items.dart';
import 'package:opennutritracker/core/data/drift/tables/label_captures.dart';
import 'package:opennutritracker/core/data/drift/tables/log_entries.dart';
import 'package:opennutritracker/core/data/drift/tables/outbox_items.dart';
import 'package:opennutritracker/core/data/drift/tables/own_rows.dart';
import 'package:opennutritracker/core/data/drift/tables/recipe_ingredients.dart';
import 'package:opennutritracker/core/data/drift/tables/recipes.dart';
import 'package:opennutritracker/core/data/drift/tables/user_activities.dart';
import 'package:opennutritracker/core/data/drift/tables/user_profile.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';
import 'package:sqlite3/sqlite3.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [FoodItems, LogEntries, DailyStats, Config, UserProfile, UserActivities, Recipes, RecipeIngredients, OutboxItems, LabelCaptures, OwnRows],
  daos: [FoodItemDao, LogEntryDao, DailyStatsDao, ConfigDao, UserProfileDao, UserActivityDao, RecipeDao, OutboxDao, LabelCaptureDao, OwnRowDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 10;

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
          // Provenance for externally-synced (Mantel) intake entries. A UNIQUE
          // index makes a re-pull idempotent; NULLs (local entries) are exempt.
          await customStatement(
            'CREATE UNIQUE INDEX IF NOT EXISTS idx_log_entries_external_id ON log_entries(external_id)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_outbox_items_queued_at ON outbox_items(queued_at)',
          );
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await customStatement(
              'ALTER TABLE food_items ADD COLUMN favourite INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (from < 3) {
            await customStatement(
              'ALTER TABLE daily_stats ADD COLUMN active_calories_burned REAL NOT NULL DEFAULT 0.0',
            );
            await customStatement(
              'ALTER TABLE daily_stats ADD COLUMN active_calories_updated_at INTEGER',
            );
          }
          if (from < 4) {
            // Recreate log_entries to make food_item_id nullable + add entry_type, quick_add_label
            await customStatement('''
              CREATE TABLE log_entries_new (
                id TEXT NOT NULL PRIMARY KEY,
                timestamp INTEGER NOT NULL,
                meal_slot TEXT NOT NULL,
                food_item_id TEXT REFERENCES food_items(id),
                amount REAL NOT NULL,
                unit TEXT NOT NULL,
                snapshot_kcal REAL NOT NULL DEFAULT 0.0,
                snapshot_protein REAL NOT NULL DEFAULT 0.0,
                snapshot_carbs REAL NOT NULL DEFAULT 0.0,
                snapshot_fat REAL NOT NULL DEFAULT 0.0,
                entry_type TEXT NOT NULL DEFAULT 'food',
                quick_add_label TEXT
              )
            ''');
            await customStatement('''
              INSERT INTO log_entries_new (id, timestamp, meal_slot, food_item_id, amount, unit, snapshot_kcal, snapshot_protein, snapshot_carbs, snapshot_fat, entry_type)
              SELECT id, timestamp, meal_slot, food_item_id, amount, unit, snapshot_kcal, snapshot_protein, snapshot_carbs, snapshot_fat, 'food'
              FROM log_entries
            ''');
            await customStatement('DROP TABLE log_entries');
            await customStatement('ALTER TABLE log_entries_new RENAME TO log_entries');
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_log_entries_timestamp ON log_entries(timestamp)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_log_entries_meal_slot ON log_entries(meal_slot)',
            );
          }
          if (from < 5) {
            await customStatement('''
              CREATE TABLE IF NOT EXISTS recipes (
                id TEXT NOT NULL PRIMARY KEY,
                name TEXT NOT NULL,
                servings REAL NOT NULL DEFAULT 1.0,
                created_at INTEGER NOT NULL,
                updated_at INTEGER NOT NULL,
                last_used_at INTEGER,
                favourite INTEGER NOT NULL DEFAULT 0,
                kcal_per_serving REAL NOT NULL DEFAULT 0.0,
                protein_per_serving REAL NOT NULL DEFAULT 0.0,
                carbs_per_serving REAL NOT NULL DEFAULT 0.0,
                fat_per_serving REAL NOT NULL DEFAULT 0.0
              )
            ''');
            await customStatement('''
              CREATE TABLE IF NOT EXISTS recipe_ingredients (
                id TEXT NOT NULL PRIMARY KEY,
                recipe_id TEXT NOT NULL REFERENCES recipes(id),
                food_item_id TEXT REFERENCES food_items(id),
                name TEXT NOT NULL,
                grams REAL NOT NULL,
                kcal_per100 REAL NOT NULL DEFAULT 0.0,
                protein_per100 REAL NOT NULL DEFAULT 0.0,
                carbs_per100 REAL NOT NULL DEFAULT 0.0,
                fat_per100 REAL NOT NULL DEFAULT 0.0,
                sort_order INTEGER NOT NULL DEFAULT 0
              )
            ''');
            await customStatement(
              'ALTER TABLE log_entries ADD COLUMN recipe_id TEXT',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_recipe_ingredients_recipe_id ON recipe_ingredients(recipe_id)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_log_entries_recipe_id ON log_entries(recipe_id)',
            );
          }
          if (from < 6) {
            // Mantel meal-sync provenance. Add the column, then a UNIQUE index
            // so a retried pull can't double-log an intake. SQLite allows the
            // many NULLs that pre-existing local entries carry.
            await customStatement(
              'ALTER TABLE log_entries ADD COLUMN external_id TEXT',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_log_entries_external_id ON log_entries(external_id)',
            );
          }
          if (from < 7) {
            // The one outbound queue. Purely additive — nothing already in the
            // database changes shape, so an upgrade cannot disturb a diary.
            await customStatement('''
              CREATE TABLE IF NOT EXISTS outbox_items (
                client_id TEXT NOT NULL PRIMARY KEY,
                path TEXT NOT NULL,
                body TEXT NOT NULL,
                owner_id INTEGER NOT NULL,
                author_id INTEGER NOT NULL,
                logged_at INTEGER NOT NULL,
                queued_at INTEGER NOT NULL,
                attempts INTEGER NOT NULL DEFAULT 0,
                last_error TEXT
              )
            ''');
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_outbox_items_queued_at ON outbox_items(queued_at)',
            );
          }
          if (from < 8) {
            // Photographs taken so far for a packet whose capture was
            // interrupted. Additive, like the queue above.
            await customStatement('''
              CREATE TABLE IF NOT EXISTS label_captures (
                capture_id TEXT NOT NULL,
                shot TEXT NOT NULL,
                path TEXT NOT NULL,
                taken_at INTEGER NOT NULL,
                PRIMARY KEY (capture_id, shot)
              )
            ''');
          }
          if (from < 9) {
            // What was actually said, for rows that came from a spoken
            // capture. Additive: every existing row carries NULL, which is
            // exactly what "nobody spoke this one" means.
            await customStatement(
              'ALTER TABLE log_entries ADD COLUMN said TEXT',
            );
          }
          if (from < 10) {
            // What this phone itself did, and which rows on the day came of it.
            // Both additive. Every row already in the diary gets 0 — "this
            // phone has no record of doing it" — which is the honest answer for
            // anything logged before the phone started keeping the record, and
            // the safe one: it withholds Undo rather than offering it wrongly.
            await customStatement('''
              CREATE TABLE IF NOT EXISTS own_rows (
                client_id TEXT NOT NULL PRIMARY KEY,
                minted_at INTEGER NOT NULL
              )
            ''');
            await customStatement(
              'ALTER TABLE log_entries ADD COLUMN this_phone_did_it '
              'INTEGER NOT NULL DEFAULT 0',
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
