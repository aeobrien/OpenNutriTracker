import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';

class RecomputeDayUsecase {
  final LogEntryDao _logEntryDao;
  final DailyStatsDao _dailyStatsDao;
  final _log = Logger('RecomputeDayUsecase');

  RecomputeDayUsecase(this._logEntryDao, this._dailyStatsDao);

  /// Re-sums all log entry snapshots for [day] and overwrites the tracked
  /// values in DailyStats. Goal values are preserved.
  Future<void> recomputeDay(DateTime day) async {
    _log.fine('Recomputing daily stats for $day');

    final entries = await _logEntryDao.getByDate(day);

    double totalKcal = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalProtein = 0;

    for (final entry in entries) {
      totalKcal += entry.logEntry.snapshotKcal;
      totalCarbs += entry.logEntry.snapshotCarbs;
      totalFat += entry.logEntry.snapshotFat;
      totalProtein += entry.logEntry.snapshotProtein;
    }

    final existing = await _dailyStatsDao.getByDate(day);
    if (existing == null) {
      _log.fine('No DailyStat row for $day, skipping recompute');
      return;
    }

    final dateKey =
        '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

    await _dailyStatsDao.upsert(DailyStatsCompanion(
      date: Value(dateKey),
      calorieGoal: Value(existing.calorieGoal),
      caloriesTracked: Value(totalKcal),
      carbsGoal: Value(existing.carbsGoal),
      carbsTracked: Value(totalCarbs),
      fatGoal: Value(existing.fatGoal),
      fatTracked: Value(totalFat),
      proteinGoal: Value(existing.proteinGoal),
      proteinTracked: Value(totalProtein),
    ));

    _log.fine(
        'Recomputed $day: kcal=$totalKcal, carbs=$totalCarbs, fat=$totalFat, protein=$totalProtein');
  }
}
