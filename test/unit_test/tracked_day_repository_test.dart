import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';

void main() {
  group('TrackedDayRepository', () {
    late AppDatabase db;
    late DailyStatsDao dao;
    late TrackedDayRepository repo;

    setUp(() {
      db = AppDatabase.createInMemory();
      dao = DailyStatsDao(db);
      repo = TrackedDayRepository(dao);
    });

    tearDown(() async {
      await db.close();
    });

    group('deleteDayIfEmpty', () {
      test('deletes day when all tracked values are zero', () async {
        final day = DateTime(2026, 4, 9);
        await repo.addNewTrackedDay(day, 2000, 250, 70, 150);
        expect(await repo.hasTrackedDay(day), isTrue);

        await repo.deleteDayIfEmpty(day);
        expect(await repo.hasTrackedDay(day), isFalse);
      });

      test('does not delete day when calories are tracked', () async {
        final day = DateTime(2026, 4, 9);
        await repo.addNewTrackedDay(day, 2000, 250, 70, 150);
        await repo.addDayTrackedCalories(day, 500);

        await repo.deleteDayIfEmpty(day);
        expect(await repo.hasTrackedDay(day), isTrue);
      });

      test('does not delete day when only macros are tracked', () async {
        final day = DateTime(2026, 4, 9);
        await repo.addNewTrackedDay(day, 2000, 250, 70, 150);
        await dao.addTrackedValues(day, protein: 25);

        await repo.deleteDayIfEmpty(day);
        expect(await repo.hasTrackedDay(day), isTrue);
      });

      test('deletes day after values are removed back to zero', () async {
        final day = DateTime(2026, 4, 9);
        await repo.addNewTrackedDay(day, 2000, 250, 70, 150);
        await repo.addDayTrackedCalories(day, 300);
        await repo.addDayMacrosTracked(day,
            carbsTracked: 40, fatTracked: 10, proteinTracked: 25);

        // Remove the same amounts
        await repo.removeDayTrackedCalories(day, 300);
        await repo.removeDayMacrosTracked(day,
            carbsTracked: 40, fatTracked: 10, proteinTracked: 25);

        await repo.deleteDayIfEmpty(day);
        expect(await repo.hasTrackedDay(day), isFalse);
      });

      test('handles floating-point drift from repeated add/subtract', () async {
        final day = DateTime(2026, 4, 9);
        await repo.addNewTrackedDay(day, 2000, 250, 70, 150);

        // Simulate multiple adds/removes that may cause floating-point drift
        for (int i = 0; i < 10; i++) {
          await repo.addDayTrackedCalories(day, 33.33);
        }
        for (int i = 0; i < 10; i++) {
          await repo.removeDayTrackedCalories(day, 33.33);
        }

        // Even with potential drift, the day should be considered empty
        await repo.deleteDayIfEmpty(day);
        expect(await repo.hasTrackedDay(day), isFalse);
      });

      test('no-ops when day does not exist', () async {
        final day = DateTime(2026, 4, 9);
        // Should not throw
        await repo.deleteDayIfEmpty(day);
        expect(await repo.hasTrackedDay(day), isFalse);
      });
    });
  });
}
