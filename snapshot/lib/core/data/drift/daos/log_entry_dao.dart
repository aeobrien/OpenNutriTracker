import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/food_items.dart';
import 'package:opennutritracker/core/data/drift/tables/log_entries.dart';

part 'log_entry_dao.g.dart';

class LogEntryWithFoodItem {
  final LogEntry logEntry;
  final FoodItem? foodItem;

  LogEntryWithFoodItem({required this.logEntry, this.foodItem});
}

@DriftAccessor(tables: [LogEntries, FoodItems])
class LogEntryDao extends DatabaseAccessor<AppDatabase>
    with _$LogEntryDaoMixin {
  LogEntryDao(super.db);

  Future<void> insertEntry(LogEntriesCompanion entry) async {
    await into(logEntries).insert(entry);
  }

  Future<void> deleteById(String id) async {
    await (delete(logEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateEntry(String id, LogEntriesCompanion entry) async {
    await (update(logEntries)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<LogEntryWithFoodItem?> getById(String id) async {
    final query = select(logEntries).join([
      leftOuterJoin(foodItems, foodItems.id.equalsExp(logEntries.foodItemId)),
    ])
      ..where(logEntries.id.equals(id));

    final row = await query.getSingleOrNull();
    if (row == null) return null;

    return LogEntryWithFoodItem(
      logEntry: row.readTable(logEntries),
      foodItem: row.readTableOrNull(foodItems),
    );
  }

  Future<List<LogEntryWithFoodItem>> getByDateAndSlot(
      DateTime date, String slot) async {
    final dayStart =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    final query = select(logEntries).join([
      leftOuterJoin(foodItems, foodItems.id.equalsExp(logEntries.foodItemId)),
    ])
      ..where(logEntries.timestamp.isBetweenValues(dayStart, dayEnd) &
          logEntries.mealSlot.equals(slot));

    final rows = await query.get();
    return rows
        .map((row) => LogEntryWithFoodItem(
              logEntry: row.readTable(logEntries),
              foodItem: row.readTableOrNull(foodItems),
            ))
        .toList();
  }

  Future<List<LogEntryWithFoodItem>> getRecentlyAdded({int limit = 100}) async {
    // First, get the most recent log entry per food_item_id
    final subQuery = selectOnly(logEntries)
      ..addColumns([logEntries.foodItemId, logEntries.timestamp.max()])
      ..groupBy([logEntries.foodItemId]);

    // Use a simpler approach: get all entries ordered by timestamp desc,
    // then deduplicate in Dart
    final query = select(logEntries).join([
      leftOuterJoin(foodItems, foodItems.id.equalsExp(logEntries.foodItemId)),
    ])
      ..orderBy([OrderingTerm.desc(logEntries.timestamp)]);

    final rows = await query.get();
    final seen = <String>{};
    final results = <LogEntryWithFoodItem>[];

    for (final row in rows) {
      final entry = row.readTable(logEntries);
      // Skip quick-add entries — they have no food item to show in "recent"
      if (entry.entryType == 'quickAdd') continue;

      // Recipe entries: deduplicate by recipeId
      if (entry.entryType == 'recipe') {
        final rid = entry.recipeId;
        if (rid != null && seen.add('recipe:$rid')) {
          results.add(LogEntryWithFoodItem(
            logEntry: entry,
            foodItem: row.readTableOrNull(foodItems),
          ));
          if (results.length >= limit) break;
        }
        continue;
      }

      // Food entries: deduplicate by foodItemId
      final fid = entry.foodItemId;
      if (fid != null && seen.add(fid)) {
        results.add(LogEntryWithFoodItem(
          logEntry: entry,
          foodItem: row.readTableOrNull(foodItems),
        ));
        if (results.length >= limit) break;
      }
    }
    return results;
  }

  Future<List<LogEntryWithFoodItem>> getAll() async {
    final query = select(logEntries).join([
      leftOuterJoin(foodItems, foodItems.id.equalsExp(logEntries.foodItemId)),
    ]);

    final rows = await query.get();
    return rows
        .map((row) => LogEntryWithFoodItem(
              logEntry: row.readTable(logEntries),
              foodItem: row.readTableOrNull(foodItems),
            ))
        .toList();
  }

  Future<List<LogEntryWithFoodItem>> getByDate(DateTime date) async {
    final dayStart =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    final query = select(logEntries).join([
      leftOuterJoin(foodItems, foodItems.id.equalsExp(logEntries.foodItemId)),
    ])
      ..where(logEntries.timestamp.isBetweenValues(dayStart, dayEnd));

    final rows = await query.get();
    return rows
        .map((row) => LogEntryWithFoodItem(
              logEntry: row.readTable(logEntries),
              foodItem: row.readTableOrNull(foodItems),
            ))
        .toList();
  }

  Future<List<LogEntry>> getAllRaw() async {
    return select(logEntries).get();
  }
}
