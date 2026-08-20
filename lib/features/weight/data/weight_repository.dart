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
  /// **Each typing carries its own name, not the day's.** This read the other
  /// way round until 20 August and the comment here claimed the opposite of
  /// what the code did: it sent every typed weight as `typed-<day>`, saying
  /// that made a second one "a correction to that day". It made it the
  /// reverse. A client id names a *message*, and the house stores a message it
  /// has already seen exactly once — so the second number was not a correction
  /// arriving, it was a duplicate being dropped, and the queue counted it as
  /// delivered. Aidan typed 114.8 over 115.0, the app told him it had saved,
  /// and the house went on holding 115.0.
  ///
  /// Standing on the scales twice in a day and typing what they say is two
  /// separate acts, so it is two messages. Which of them counts for the day is
  /// the house's decision and it already makes it — the later typed reading
  /// wins, and the earlier one stays on the record rather than being erased.
  /// Retries are still safe: the id is fixed when the item is queued, so
  /// re-sending the same queued item re-sends the same id.
  ///
  /// Apple Health is the opposite case and keeps its day name: importing the
  /// same day twice is the same reading arriving twice, not a correction.
  Future<void> typed(DateTime day, num kg) async {
    await _logger.logWeight(day: ExerciseSync.dayKey(day), kg: kg);
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
