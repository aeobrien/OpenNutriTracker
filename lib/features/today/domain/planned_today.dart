/// What is planned for today, and what this phone has already answered.
library;

import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

/// The planned meals Home should draw as ghost cards, and the two answers.
///
/// Held apart from the screen so the rule that matters here can be tested
/// without building one: **a meal answered on this phone does not come back.**
/// The answer goes on the queue, and until the queue drains the Mac Mini still
/// calls the meal planned — so the next read of the day returns it. Showing it
/// again would be asking somebody to confirm their dinner twice, which is the
/// surest way to teach them to stop answering.
class PlannedToday {
  static final _log = Logger('PlannedToday');

  final HouseholdLogger _logger;

  /// Meals answered here whose answer has not reached the Mac Mini yet.
  final _answered = <int>{};

  /// What to draw, in the order the household planned it.
  List<PlannedItem> items = const [];

  PlannedToday(this._logger);

  /// Take a fresh read of the day, dropping anything already answered here.
  void takeFrom(DayView day) {
    items = [
      for (final p in day.planned)
        if (!_answered.contains(p.planId)) p,
    ];
  }

  /// Record what they did about a planned meal, and take it off the day now.
  ///
  /// The card goes before the Mac Mini has heard. That is not optimism about
  /// the network — the answer is on the queue, which is where every other write
  /// on this phone waits too. What would be dishonest is the opposite: leaving
  /// a meal looking undecided when the person has decided.
  ///
  /// Returns true when the answer is safely on the queue. On the one failure
  /// that matters — a local write that somehow did not happen — the meal comes
  /// back, because a decision nothing recorded is worse than asking again.
  Future<bool> decide(PlannedItem item, {required bool ate}) async {
    _answered.add(item.planId);
    items = [
      for (final p in items)
        if (p.planId != item.planId) p,
    ];
    try {
      await _logger.decidePlan(planId: item.planId, ate: ate);
      return true;
    } catch (e) {
      _log.warning('[PLAN] could not queue the answer for ${item.planId}: $e');
      _answered.remove(item.planId);
      return false;
    }
  }
}
