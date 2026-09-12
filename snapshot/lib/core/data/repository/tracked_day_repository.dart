import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';

class TrackedDayRepository {
  final DailyStatsDao _dailyStatsDao;
  final _log = Logger('TrackedDayRepository');

  TrackedDayRepository(this._dailyStatsDao);

  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async {
    final row = await _dailyStatsDao.getByDate(day);
    return row != null ? TrackedDayEntity.fromDailyStatRow(row) : null;
  }

  Future<bool> hasTrackedDay(DateTime day) async {
    return await _dailyStatsDao.hasDate(day);
  }

  Future<List<TrackedDayEntity>> getTrackedDayByRange(
      DateTime start, DateTime end) async {
    final rows = await _dailyStatsDao.getInRange(start, end);
    return rows.map((row) => TrackedDayEntity.fromDailyStatRow(row)).toList();
  }

  Future<void> updateDayCalorieGoal(DateTime day, double calorieGoal) async {
    _log.fine('Updating calorie goal for $day to $calorieGoal');
    await _dailyStatsDao.updateGoals(day, calorieGoal: calorieGoal);
  }

  Future<void> increaseDayCalorieGoal(DateTime day, double amount) async {
    await _dailyStatsDao.addToGoals(day, calorieAmount: amount);
  }

  Future<void> reduceDayCalorieGoal(DateTime day, double amount) async {
    await _dailyStatsDao.subtractFromGoals(day, calorieAmount: amount);
  }

  Future<void> addNewTrackedDay(DateTime day, double totalKcalGoal,
      double totalCarbsGoal, double totalFatGoal, double totalProteinGoal) async {
    _log.fine('Adding new tracked day for $day');
    final dateKey =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    await _dailyStatsDao.upsert(DailyStatsCompanion(
      date: Value(dateKey),
      calorieGoal: Value(totalKcalGoal),
      caloriesTracked: const Value(0),
      carbsGoal: Value(totalCarbsGoal),
      carbsTracked: const Value(0),
      fatGoal: Value(totalFatGoal),
      fatTracked: const Value(0),
      proteinGoal: Value(totalProteinGoal),
      proteinTracked: const Value(0),
    ));
  }

  Future<void> addAllTrackedDays(List<TrackedDayDBO> trackedDaysDBO) async {
    for (final td in trackedDaysDBO) {
      final dateKey =
          '${td.day.year}-${td.day.month.toString().padLeft(2, '0')}-${td.day.day.toString().padLeft(2, '0')}';
      await _dailyStatsDao.upsert(DailyStatsCompanion(
        date: Value(dateKey),
        calorieGoal: Value(td.calorieGoal),
        caloriesTracked: Value(td.caloriesTracked),
        carbsGoal: Value(td.carbsGoal),
        carbsTracked: Value(td.carbsTracked),
        fatGoal: Value(td.fatGoal),
        fatTracked: Value(td.fatTracked),
        proteinGoal: Value(td.proteinGoal),
        proteinTracked: Value(td.proteinTracked),
      ));
    }
  }

  Future<void> addDayTrackedCalories(DateTime day, double addCalories) async {
    if (await _dailyStatsDao.hasDate(day)) {
      await _dailyStatsDao.addTrackedValues(day, kcal: addCalories);
    }
  }

  Future<void> removeDayTrackedCalories(
      DateTime day, double addCalories) async {
    if (await _dailyStatsDao.hasDate(day)) {
      await _dailyStatsDao.subtractTrackedValues(day, kcal: addCalories);
    }
  }

  Future<void> updateDayMacroGoal(DateTime day,
      {double? carbGoal, double? fatGoal, double? proteinGoal}) async {
    await _dailyStatsDao.updateGoals(day,
        carbsGoal: carbGoal, fatGoal: fatGoal, proteinGoal: proteinGoal);
  }

  Future<void> increaseDayMacroGoal(DateTime day,
      {double? carbGoal, double? fatGoal, double? proteinGoal}) async {
    await _dailyStatsDao.addToGoals(day,
        carbsAmount: carbGoal, fatAmount: fatGoal, proteinAmount: proteinGoal);
  }

  Future<void> reduceDayMacroGoal(DateTime day,
      {double? carbGoal, double? fatGoal, double? proteinGoal}) async {
    await _dailyStatsDao.subtractFromGoals(day,
        carbsAmount: carbGoal, fatAmount: fatGoal, proteinAmount: proteinGoal);
  }

  Future<void> addDayMacrosTracked(DateTime day,
      {double? carbsTracked,
      double? fatTracked,
      double? proteinTracked}) async {
    await _dailyStatsDao.addTrackedValues(day,
        carbs: carbsTracked, fat: fatTracked, protein: proteinTracked);
  }

  Future<void> removeDayMacrosTracked(DateTime day,
      {double? carbsTracked,
      double? fatTracked,
      double? proteinTracked}) async {
    await _dailyStatsDao.subtractTrackedValues(day,
        carbs: carbsTracked, fat: fatTracked, protein: proteinTracked);
  }

  Future<void> deleteDayIfEmpty(DateTime day) async {
    final row = await _dailyStatsDao.getByDate(day);
    if (row != null && row.caloriesTracked <= 0) {
      _log.fine('Deleting empty tracked day for $day');
      await _dailyStatsDao.deleteByDate(day);
    }
  }

  // Export support: returns all daily stats as TrackedDayDBO-compatible JSON
  Future<List<Map<String, dynamic>>> getAllTrackedDaysJson() async {
    final rows = await _dailyStatsDao.getAll();
    return rows.map((row) {
      final dateParts = row.date.split('-');
      final day = DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]),
          int.parse(dateParts[2]));
      return {
        'day': day.toIso8601String(),
        'calorieGoal': row.calorieGoal,
        'caloriesTracked': row.caloriesTracked,
        'carbsGoal': row.carbsGoal,
        'carbsTracked': row.carbsTracked,
        'fatGoal': row.fatGoal,
        'fatTracked': row.fatTracked,
        'proteinGoal': row.proteinGoal,
        'proteinTracked': row.proteinTracked,
      };
    }).toList();
  }
}
