import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';

/// Where a day's active calories come from, when they come from the watch.
///
/// An interface rather than the Health plugin directly, for one reason: the
/// interesting cases are "the watch had a figure" and "the watch had nothing",
/// and neither can be arranged on a real HealthKit in a test.
abstract class ActiveCaloriesSource {
  /// The active calories the watch recorded for [day], or null when there is
  /// nothing to be had — permission refused, no watch worn, no samples. Null
  /// and zero are deliberately different: zero is a real reading.
  Future<double?> activeCaloriesFor(String day);
}

/// The real one, over HealthKit.
class HealthActiveCalories implements ActiveCaloriesSource {
  final HealthRepository _health;
  final DateTime Function() _now;

  HealthActiveCalories(this._health, {DateTime Function()? now})
      : _now = now ?? DateTime.now;

  @override
  Future<double?> activeCaloriesFor(String day) async {
    // HealthKit is only asked for today; older days are already on the ledger.
    final today = _now();
    final key = '${today.year.toString().padLeft(4, '0')}-'
        '${today.month.toString().padLeft(2, '0')}-'
        '${today.day.toString().padLeft(2, '0')}';
    if (day != key) return null;
    if (!await _health.hasPermission()) return null;
    return _health.fetchAndCacheActiveCalories();
  }
}

/// Exercise reaching a person's day, by either of the two routes.
///
/// The watch is the usual one: it is read and put on the day without anybody
/// doing anything. The typed route is for when it did not — a swim, a phone
/// left on the side, a watch out of battery — and it has to be a real route
/// rather than a fallback that quietly writes the same thing, because a figure
/// somebody typed and a figure a watch measured are not the same claim and the
/// day has to be able to say which it was.
///
/// Both routes go on the day of the person **this phone belongs to**. Not the
/// person the server happened to hear from last: the server's most recent
/// caller is whoever picked up their phone most recently, which has nothing to
/// do with whose exercise this is.
class ExerciseSync {
  final HouseholdRepository _repository;
  final HouseholdLogger _logger;
  final ActiveCaloriesSource _source;
  final _log = Logger('ExerciseSync');

  ExerciseSync(this._repository, this._logger, this._source);

  /// The watch's figure for [day], put on the owner's day.
  ///
  /// Returns null when the watch had nothing — the caller can then offer to
  /// type it in, which is exactly what the day screen does.
  ///
  /// Safe to call as often as you like: the id is worked out from the person
  /// and the day, so a second sync of the same day replaces nothing and creates
  /// nothing. That is what stops a day's exercise multiplying every time the
  /// app is opened.
  Future<String?> syncFromHealth({required String day}) async {
    final owner = await _repository.storedOwner();
    if (owner == null) {
      throw StateError(
          'nobody has said whose phone this is, so there is no day to sync');
    }
    final kcal = await _source.activeCaloriesFor(day);
    if (kcal == null) {
      _log.info('[EXERCISE] nothing from the watch for $day');
      return null;
    }
    return _logger.logExercise(
      day: day,
      source: 'health',
      kcal: kcal,
      clientId: healthClientId(owner, day),
    );
  }

  /// The same day's exercise, typed in because the watch did not have it.
  Future<String> typeIn({
    required String day,
    required num kcal,
    num? minutes,
    String? note,
  }) =>
      _logger.logExercise(
        day: day,
        source: 'typed',
        kcal: kcal,
        minutes: minutes,
        note: note,
      );

  /// One id per person per day for the watch's figure — the whole reason a
  /// repeated sync cannot double a day up.
  static String healthClientId(int personId, String day) =>
      'health-$personId-$day';
}
