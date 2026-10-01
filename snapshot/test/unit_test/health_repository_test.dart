import 'package:drift/drift.dart' show Value;
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

    test('updateActiveCalories persists when no tracked day row exists yet',
        () async {
      // No upsert beforehand: user has opened the app but logged nothing.
      await dao.updateActiveCalories('2026-03-15', 275.0);

      final (calories, updatedAt) = await dao.getActiveCalories('2026-03-15');
      expect(calories, 275.0);
      expect(updatedAt, isNotNull);
    });

    test('placeholder row from cache write keeps active calories after a '
        'tracked day is later created', () async {
      // Cache HealthKit value before any food is logged.
      await dao.updateActiveCalories('2026-03-15', 275.0);

      // User logs food later — addNewTrackedDay upserts goals but must not
      // clobber the cached active calories.
      await dao.upsert(DailyStatsCompanion(
        date: const Value('2026-03-15'),
        calorieGoal: const Value(2000),
        caloriesTracked: const Value(0),
      ));

      final row = await dao.getByDate(DateTime(2026, 3, 15));
      expect(row, isNotNull);
      expect(row!.calorieGoal, 2000);
      expect(row.activeCaloriesBurned, 275.0);
    });
  });
}
