import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/health_data_source.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/weight/domain/weight_history.dart';

/// Weights: the history, and bringing in what Apple Health already knows.
///
/// **Every reading goes through the same queue as everything else, one at a
/// time.** There is no batch call and that is a decision, not an omission.
/// Bringing in a backlog is thirty ordinary weigh-ins sent through the outbox
/// that already carries meals when the Mac Mini is asleep — which already
/// retries, already survives the app being closed, and already refuses to
/// store the same thing twice. A batch would have needed its own version of
/// all three, and the only thing it would have bought is a tidier summary.
class WeightRepository {
  static final _log = Logger('WeightRepository');

  final HouseholdRepository _household;
  final HouseholdLogger _logger;
  final HealthDataSource _health;

  WeightRepository(this._household, this._logger, this._health);

  /// How far back to look when nothing has ever been brought in. A year is
  /// enough to draw a trend anybody cares about and short enough that a first
  /// import is not a thousand queued items.
  static const firstReach = Duration(days: 365);

  Future<WeightHistory> history() async {
    final who = await _household.storedOwner();
    if (who == null) return const WeightHistory();
    return _household.weightHistory(who);
  }

  /// Put a weight somebody typed on their history.
  ///
  /// Named after the day rather than at random, so the same day typed twice is
  /// a correction to that day and not a second weigh-in on it.
  Future<void> typed(DateTime day, num kg) async {
    final key = ExerciseSync.dayKey(day);
    await _logger.logWeight(day: key, kg: kg, clientId: 'typed-$key');
  }

  /// Bring in every weigh-in Apple Health holds that this house has not seen.
  ///
  /// Returns how many readings were queued. It counts what it sent, not what
  /// landed — the queue decides when things land, and saying "brought in 12"
  /// the moment the Mini answers would be a different and slower promise.
  ///
  /// Asks only for what is missing: from the day after the last reading
  /// already on the history, or a year back if there is none. Overlap is
  /// harmless anyway — each reading is named after its day, so sending one
  /// twice stores it once — but there is no reason to queue a year of work
  /// every time somebody taps the button.
  Future<int> bringInFromAppleHealth() async {
    final known = await history();
    final from = known.lastDay == null
        ? DateTime.now().subtract(firstReach)
        : known.lastDay!.add(const Duration(days: 1));
    final found = await _health.weightsSince(from);
    final days = found.keys.toList()..sort();
    for (final day in days) {
      final key = ExerciseSync.dayKey(day);
      await _logger.logWeight(
        day: key,
        kg: found[day]!,
        source: 'health',
        clientId: 'health-$key',
      );
    }
    _log.info('[WEIGHT] queued ${days.length} reading(s) from Apple Health');
    return days.length;
  }
}
