// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_stats_dao.dart';

// ignore_for_file: type=lint
mixin _$DailyStatsDaoMixin on DatabaseAccessor<AppDatabase> {
  $DailyStatsTable get dailyStats => attachedDatabase.dailyStats;
  DailyStatsDaoManager get managers => DailyStatsDaoManager(this);
}

class DailyStatsDaoManager {
  final _$DailyStatsDaoMixin _db;
  DailyStatsDaoManager(this._db);
  $$DailyStatsTableTableManager get dailyStats =>
      $$DailyStatsTableTableManager(_db.attachedDatabase, _db.dailyStats);
}
