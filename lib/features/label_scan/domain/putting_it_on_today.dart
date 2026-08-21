/// Getting the packet you have just entered onto today, without going looking
/// for it.
library;

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/calc/meal_slot_calc.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

/// What came of asking to put a just-saved packet on today.
///
/// Three outcomes, and the caller says something different for each. A packet
/// that cannot be put on the day yet is not a failure — the food is safely in
/// the list either way — so this carries the reason rather than throwing.
class PutOnToday {
  /// The food, ready for the portion screen. Null when it could not be found.
  final MealEntity? food;

  /// The meal the clock says it is. Whoever lands on the portion screen can
  /// change it; this is only where the screen opens.
  final IntakeTypeEntity meal;

  /// Why there is no food, in a sentence a person can read. Null on success.
  final String? why;

  const PutOnToday._(this.food, this.meal, this.why);

  bool get found => food != null;
}

/// Find the packet somebody has just saved, so it can go on today.
///
/// The food went onto the queue rather than straight to the Mac Mini, so the
/// queue is emptied first. That is not an optimisation: until the Mini has the
/// food it has no id, and the app identifies every food by an id the house
/// gives it. Putting it on the day before then would make a row that looks
/// right and is joined to nothing.
///
/// A barcode is used to find it again when there is one, because a barcode is
/// an exact answer and a name is not — two packets of the same yoghurt differ
/// by their barcode and by nothing else somebody typed.
class PuttingItOnToday {
  static final _log = Logger('PuttingItOnToday');

  /// Said when the Mac Mini could not be reached. It deliberately says where
  /// the food *is* — safe, in the list — because the thing somebody fears at
  /// this moment is that the packet they just typed in has gone.
  static const cannotReach =
      "Saved. It can't go on your day until the Mac Mini is back, "
      'but the food itself is safe in the household list.';

  /// Said when the house came back but does not have this food yet. Rare, and
  /// it is the queue still catching up rather than anything lost.
  static const notThereYet =
      "Saved. It hasn't reached the household list yet — "
      'search for it in a moment and it will be there.';

  final Outbox _outbox;
  final FoodFinder _finder;

  PuttingItOnToday(this._outbox, this._finder);

  Future<PutOnToday> find(FoodDraft saved, {DateTime? now}) async {
    final meal = _mealFor(now ?? DateTime.now());
    final drained = await _outbox.drain();
    if (drained.unreachable) {
      _log.info('[PACKET] ${saved.name} stays in the list — no Mac Mini');
      return PutOnToday._(null, meal, cannotReach);
    }
    final barcode = saved.barcode;
    final found = barcode != null && barcode.trim().isNotEmpty
        ? await _finder.withBarcode(barcode)
        : await _firstNamed(saved.name);
    if (found == null) {
      _log.info('[PACKET] ${saved.name} is not back from the house yet');
      return PutOnToday._(null, meal, notThereYet);
    }
    _log.info('[PACKET] ${saved.name} is ready to go on today as $meal');
    return PutOnToday._(found, meal, null);
  }

  /// The house's own food of this name, or null. Exact on the name rather than
  /// the search's looser match: this is asking "is the thing I just saved
  /// back?", not "what else might I have meant?".
  Future<MealEntity?> _firstNamed(String name) async {
    final wanted = name.trim().toLowerCase();
    for (final food in await _finder.matching(name)) {
      if ((food.name ?? '').trim().toLowerCase() == wanted) return food;
    }
    return null;
  }

  static IntakeTypeEntity _mealFor(DateTime at) {
    switch (MealSlotCalc.suggestSlot(at)) {
      case 'breakfast':
        return IntakeTypeEntity.breakfast;
      case 'lunch':
        return IntakeTypeEntity.lunch;
      case 'dinner':
        return IntakeTypeEntity.dinner;
      default:
        return IntakeTypeEntity.snack;
    }
  }
}
