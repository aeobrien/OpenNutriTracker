// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_entry_dao.dart';

// ignore_for_file: type=lint
mixin _$LogEntryDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoodItemsTable get foodItems => attachedDatabase.foodItems;
  $LogEntriesTable get logEntries => attachedDatabase.logEntries;
  LogEntryDaoManager get managers => LogEntryDaoManager(this);
}

class LogEntryDaoManager {
  final _$LogEntryDaoMixin _db;
  LogEntryDaoManager(this._db);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db.attachedDatabase, _db.foodItems);
  $$LogEntriesTableTableManager get logEntries =>
      $$LogEntriesTableTableManager(_db.attachedDatabase, _db.logEntries);
}
