import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health_data_source.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';

class HealthRepository {
  final HealthDataSource _healthDataSource;
  final DailyStatsDao _dailyStatsDao;
  final _log = Logger('HealthRepository');

  HealthRepository(this._healthDataSource, this._dailyStatsDao);

  Future<bool> requestPermission() =>
      _healthDataSource.requestPermission();

  Future<bool> hasPermission() =>
      _healthDataSource.hasPermission();

  Future<double> fetchAndCacheActiveCalories() async {
    final calories = await _healthDataSource.getActiveCaloriesToday();
    await cacheActiveCalories(calories);
    return calories;
  }

  /// Put a figure already read from the watch onto today's row.
  ///
  /// Split out from [fetchAndCacheActiveCalories] because of what happens on a
  /// day nothing has been logged on: that day has no row of its own until
  /// something creates one, and the write below then lands on no rows at all
  /// and is silently lost. Creating the row here is not an option — a row
  /// cannot exist without the day's calorie target, and this layer has no
  /// business deciding what that is. So the caller creates the day out of the
  /// target it already holds and asks for the figure to be written again.
  Future<void> cacheActiveCalories(double calories) async {
    final todayKey = _todayDateString();
    await _dailyStatsDao.updateActiveCalories(todayKey, calories);
    _log.fine('Cached active calories: $calories for $todayKey');
  }

  Future<(double calories, DateTime? updatedAt)> getCachedActiveCalories() async {
    final todayKey = _todayDateString();
    return _dailyStatsDao.getActiveCalories(todayKey);
  }

  String _todayDateString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
