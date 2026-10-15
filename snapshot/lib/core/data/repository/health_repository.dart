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
    final todayKey = _todayDateString();
    await _dailyStatsDao.updateActiveCalories(todayKey, calories);
    _log.fine('Cached active calories: $calories for $todayKey');
    return calories;
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
