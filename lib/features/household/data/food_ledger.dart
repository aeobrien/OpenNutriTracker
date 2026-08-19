/// Everything the app puts on a day, also going to the household ledger.
library;

import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/household/data/food_shares.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';

/// The household half of adding a food.
///
/// It exists as its own small thing for one reason: the promise is that a meal
/// logged on the phone shows up on the Mac Mini against the right person, and
/// that promise has to be provable. The screen that adds a food cannot be
/// stood up in a test without the phone's whole diary behind it, so the part
/// that matters — who ends up with what — lives here, where a test can drive
/// it against a stand-in for the house and read back what arrived.
class FoodLedger {
  final HouseholdLogger _logger;
  final _log = Logger('FoodLedger');

  FoodLedger(this._logger);

  /// One food, on one day, for one or two people.
  ///
  /// [mine] is the amount the person holding the phone had; [alsoFor] is
  /// anybody else the same food was for, each with their own amount. Every row
  /// is authored by the phone's owner — the person tapping — while the day it
  /// lands on is the row's own person's.
  ///
  /// The queue drains oldest first and stops at the first sign the Mac Mini is
  /// unreachable, so a pair either both land or the second is still waiting
  /// its turn behind the first. Neither is ever dropped, which is the promise
  /// that actually matters.
  Future<void> add({
    required DateTime day,
    required String slot,
    required String label,
    required bool liquid,
    required double mine,
    List<FoodShare> alsoFor = const [],
    /// Which food in the household's own list this was, when it came from
    /// there. This is what lets the kitchen computer put a person's own foods
    /// at the top of their list next time: it counts entries against a food,
    /// and an entry that never says which food it was cannot be counted.
    int? foodId,
    num? kcalPerUnit,
    num? proteinPerUnit,
    num? fatPerUnit,
    num? carbsPerUnit,
  }) async {
    final unit = liquid ? 'ml' : 'g';

    Future<void> send(FoodShare share, {int? owner}) async {
      final row = portionFor(share,
          kcalPerUnit: kcalPerUnit,
          proteinPerUnit: proteinPerUnit,
          fatPerUnit: fatPerUnit,
          carbsPerUnit: carbsPerUnit);
      await _logger.logFood(
        day: ExerciseSync.dayKey(day),
        label: label,
        kcal: row.kcal,
        qty: row.quantity,
        unit: unit,
        protein: row.protein,
        fat: row.fat,
        carbs: row.carbs,
        slot: slot,
        owner: owner,
        foodId: foodId,
      );
    }

    try {
      // Mine goes without an owner on purpose: the queue stamps it with
      // whoever this phone belongs to at this moment, which is the one place
      // that question is ever answered.
      await send(FoodShare(personId: 0, quantity: mine));
      for (final share in alsoFor) {
        await send(share, owner: share.personId);
      }
    } catch (e) {
      // Reachable only before anybody has said whose phone this is, or if the
      // queue's own storage fails. An unreachable house is not an error here —
      // that is exactly what the queue is for — so this stays out of the
      // person's way and goes where it can be found afterwards.
      _log.severe('[HOUSE] added to this phone but not queued for the '
          'household: $e');
    }
  }
}
