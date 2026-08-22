/// What is planned for today, and what this phone has already answered.
library;

import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

/// How an answer to a planned meal ended up.
///
/// Three outcomes rather than two, because "your answer is recorded and the
/// other person's is not" is a real thing that can happen and is not the same
/// as either success or failure. A screen that could only say yes or no would
/// have to pick one of them and be wrong half the time.
enum PlanAnswer {
  /// Everything that was asked for is on the queue.
  queued,

  /// Nothing was recorded. The meal comes back onto the day, because a
  /// decision nothing recorded is worse than asking again.
  notRecorded,

  /// The tapper's own answer is on the queue; the other person's is not. The
  /// meal stays off this day — it was answered — but somebody has to be told
  /// that it did not reach the other person.
  onlyMine,
}

/// The planned meals Home should draw as ghost cards, and the answers to them.
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
  final HouseholdRepository? _household;

  /// Meals answered here whose answer has not reached the Mac Mini yet.
  final _answered = <int>{};

  /// What to draw, in the order the household planned it.
  List<PlannedItem> items = const [];

  /// The other person in the house, once we know who that is.
  ///
  /// Null while nobody has said whose phone this is, while the Mac Mini has
  /// never been reachable, or in a household that is not two people. Answering
  /// for somebody the phone cannot name is not offered at all — see
  /// [theOther].
  HouseholdPerson? theOther;

  /// Whose phone this is, once the house has said. Null for exactly the same
  /// reasons [theOther] is.
  ///
  /// Read here rather than asked for again where it is needed: this is already
  /// the one place on Home that asks the house who anybody is, and a second
  /// asker would be a second answer that could disagree with this one.
  int? whoseThisIs;

  PlannedToday(this._logger, [this._household]);

  /// Take a fresh read of the day, dropping anything already answered here.
  void takeFrom(DayView day) {
    items = [
      for (final p in day.planned)
        if (!_answered.contains(p.planId)) p,
    ];
  }

  /// Work out who the other person is, if there is one.
  ///
  /// Deliberately quiet: not being able to name them is not a failure worth
  /// showing anybody. The second answer is simply not offered, and the card
  /// behaves exactly as it did before it existed.
  Future<void> findTheOtherPerson() async {
    final household = _household;
    if (household == null) return;
    try {
      final owner = await household.storedOwner();
      if (owner == null) return;
      whoseThisIs = owner;
      final everyone = await household.people();
      final others = everyone.where((p) => p.id != owner).toList();
      theOther = others.length == 1 ? others.first : null;
    } catch (e) {
      _log.info('[PLAN] cannot name the other person yet: $e');
    }
  }

  /// Record what they did about a planned meal, and take it off the day now.
  ///
  /// The card goes before the Mac Mini has heard. That is not optimism about
  /// the network — the answer is on the queue, which is where every other write
  /// on this phone waits too. What would be dishonest is the opposite: leaving
  /// a meal looking undecided when the person has decided.
  ///
  /// The answer says what actually got recorded — see [PlanAnswer]. On the one
  /// failure that matters, a local write that somehow did not happen, the meal
  /// comes back, because a decision nothing recorded is worse than asking
  /// again.
  ///
  /// [slot] is which meal of the day the confirmed row belongs to. It comes
  /// from the strip the ghost card was drawn in, because that is the only thing
  /// that knows — see [HouseholdLogger.decidePlan].
  ///
  /// [alsoForTheOther] answers for both people at once. It sends a second,
  /// separate decision owned by the other person and authored by the person
  /// holding the phone. Their portion is **not** sent: the household already
  /// recorded how much of this meal is theirs, and the Mac Mini reads it when
  /// the decision arrives. A portion guessed here would put a made-up calorie
  /// figure on somebody else's day, which is the one thing this system is
  /// careful never to do.
  Future<PlanAnswer> decide(
    PlannedItem item, {
    required bool ate,
    required String slot,
    bool alsoForTheOther = false,
  }) async {
    final other = alsoForTheOther ? theOther : null;
    _answered.add(item.planId);
    items = [
      for (final p in items)
        if (p.planId != item.planId) p,
    ];
    try {
      await _logger.decidePlan(planId: item.planId, ate: ate, slot: slot);
    } catch (e) {
      _log.warning('[PLAN] could not queue the answer for ${item.planId}: $e');
      _answered.remove(item.planId);
      return PlanAnswer.notRecorded;
    }
    if (other != null) {
      try {
        // Their day, this phone's author. Queued second, so if the queue can
        // only take one it is the tapper's own answer that survives — theirs
        // is the one they can be told about, and this phone is not where the
        // other person is looking.
        await _logger.decidePlan(
            planId: item.planId, ate: ate, slot: slot, owner: other.id);
      } catch (e) {
        // The person's own answer is already recorded, so the meal stays off
        // their day. Saying "and it did not reach them" is the honest outcome
        // and it belongs on the screen, not here.
        _log.warning(
            '[PLAN] answered for this phone but not for ${other.name}: $e');
        return PlanAnswer.onlyMine;
      }
    }
    return PlanAnswer.queued;
  }
}
