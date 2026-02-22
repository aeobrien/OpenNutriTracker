import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';

void main() {
  group('DailyStatsDao active calories', () {
    late AppDatabase db;
    late DailyStatsDao dao;

    setUp(() {
      db = AppDatabase.createInMemory();
      dao = DailyStatsDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('updateActiveCalories writes and reads back', () async {
      // Create a daily_stats row first
      await dao.upsert(DailyStatsCompanion.insert(
        date: '2026-02-22',
        calorieGoal: 2000,
      ));

      await dao.updateActiveCalories('2026-02-22', 350.5);
      final (calories, updatedAt) = await dao.getActiveCalories('2026-02-22');

      expect(calories, 350.5);
      expect(updatedAt, isNotNull);
    });

    test('getActiveCalories returns 0 for missing date', () async {
      final (calories, updatedAt) = await dao.getActiveCalories('2099-01-01');

      expect(calories, 0.0);
      expect(updatedAt, isNull);
    });

    test('updateActiveCalories overwrites previous value', () async {
      await dao.upsert(DailyStatsCompanion.insert(
        date: '2026-02-22',
        calorieGoal: 2000,
      ));

      await dao.updateActiveCalories('2026-02-22', 100.0);
      await dao.updateActiveCalories('2026-02-22', 450.0);
      final (calories, _) = await dao.getActiveCalories('2026-02-22');

      expect(calories, 450.0);
    });

    test('active calories default to 0 on new row', () async {
      await dao.upsert(DailyStatsCompanion.insert(
        date: '2026-02-22',
        calorieGoal: 2000,
      ));

      final row = await dao.getByDate(DateTime(2026, 2, 22));
      expect(row, isNotNull);
      expect(row!.activeCaloriesBurned, 0.0);
      expect(row.activeCaloriesUpdatedAt, isNull);
    });
  });
}
