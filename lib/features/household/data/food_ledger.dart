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

  /// The name the household's row for [intakeId] is known by.
  ///
  /// The person holding the phone gets the intake's own id, unchanged, so the
  /// diary row and the household row are the same name on both machines. A
  /// second person's share gets that name plus who it is for, because two rows
  /// cannot share one id and the second one still has to be nameable later.
  ///
  /// Worked out rather than stored: the phone must be able to say which
  /// household row it means months later, from nothing but the diary row in
  /// front of it.
  static String nameFor(String intakeId, {int? forPerson}) =>
      forPerson == null ? intakeId : '$intakeId-p$forPerson';

  /// Take a logged food back off the day, at the household end.
  ///
  /// Only the row belonging to the person holding the phone. A share logged for
  /// the other person is on *their* day and is theirs to take off — this phone
  /// does not know, from the diary row alone, that there ever was one.
  Future<void> retire(String intakeId) async {
    try {
      await _logger.retireFood(nameFor(intakeId));
    } catch (e) {
      _log.severe('[HOUSE] removed from this phone but not from the '
          'household: $e');
    }
  }

  /// Correct a logged food at the household end — its amount, its figures, and
  /// whose day it counts against.
  ///
  /// One call. See HouseholdLogger.amendFood for why moving is not separate.
  Future<void> amend(
    String intakeId, {
    int? moveTo,
    double? quantity,
    num? kcal,
    num? protein,
    num? fat,
    num? carbs,
  }) async {
    try {
      await _logger.amendFood(
        nameFor(intakeId),
        owner: moveTo,
        qty: quantity,
        kcal: kcal,
        protein: protein,
        fat: fat,
        carbs: carbs,
      );
    } catch (e) {
      _log.severe('[HOUSE] changed on this phone but not in the household: $e');
    }
  }

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
    /// The diary row this is the household half of. Its id becomes the name
    /// the household row carries — see [nameFor].
    required String intakeId,
    required DateTime day,
    required String slot,
    required String label,
    required bool liquid,
    required double mine,
    List<FoodShare> alsoFor = const [],
    /// Which food in the household's own list this was, when it came from
    /// there. This is what lets the Mac Mini put a person's own foods
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
      final name = nameFor(intakeId, forPerson: owner);
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
        clientId: name,
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
