import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';

class UpdateIntakeUsecase {
  final IntakeRepository _intakeRepository;

  /// The household half. Optional so the app runs unchanged where the house has
  /// never been set up, and so a test can leave it out.
  final FoodLedger? _household;

  UpdateIntakeUsecase(this._intakeRepository, [this._household]);

  /// Correct something already logged — here, and on the Mac Mini.
  ///
  /// [moveTo] moves the row to the other person's day. It travels with the
  /// correction rather than in a call of its own: they are noticed at the same
  /// moment and a move that landed without the corrected figure would leave
  /// both people's totals wrong with nothing to say so.
  ///
  /// A move also takes the row off this phone. This phone's diary is one
  /// person's day, so a row that now counts against somebody else cannot stay
  /// on it — it would go on adding to a total it is no longer part of, and the
  /// two machines would disagree about the day with nothing to say so. It is
  /// not deleted anywhere: the household row is still there, on the other
  /// person's day.
  ///
  /// [nowItIs] replaces the food behind the row — "I logged the wrong thing",
  /// as opposed to the wrong amount of the right thing. It happens first, so
  /// an amount corrected in the same breath is worked out against the new
  /// food rather than the one being replaced.
  ///
  /// The figures sent are worked out from the row as it is *after* the change,
  /// so the Mac Mini is told what the number now is rather than being
  /// asked to redo the phone's arithmetic.
  Future<IntakeEntity?> updateIntake(
      String intakeId, Map<String, dynamic> intakeFields,
      {int? moveTo, MealEntity? nowItIs}) async {
    final swapped = nowItIs == null
        ? null
        : await _intakeRepository.changeTheFood(intakeId, nowItIs);
    // A swap that was asked for and refused stops the whole correction here.
    // The refusal cases are a row that is not there and a row with no food
    // behind it; carrying on would tell the house this row is now called
    // something it is not, on the strength of a change that never happened
    // here.
    if (nowItIs != null && swapped == null) return null;
    final corrected =
        await _intakeRepository.updateIntake(intakeId, intakeFields);
    // A move on its own corrects nothing in this phone's own figures, so the
    // repository has nothing to hand back — but it is still the whole of the
    // correction as far as the household is concerned. Read the row back
    // rather than treating that as "no such row".
    final row = corrected ??
        swapped ??
        await _intakeRepository.getIntakeById(intakeId);
    if (row == null) return null;

    await _household?.amend(
      // The name the house knows this row by, which is not this phone's own
      // id when the row came from the house. See IntakeEntity.householdName.
      row.householdName,
      moveTo: moveTo,
      // A row with a food behind it has no label of its own — the house knows
      // it by the food's name. That only needs saying when the food changed;
      // any other correction leaves the house's own name alone, which may be
      // what somebody there typed.
      label: nowItIs?.name ?? row.quickAddLabel,
      // The house holds a link to its own food list for rows it made itself.
      // After a swap that link is a claim about this row that is no longer
      // true, and the phone cannot name a replacement — it has no idea what
      // the house calls its foods. So it says the only true thing it can:
      // this is not that food any more.
      unlinkFood: nowItIs != null,
      unit: nowItIs?.mealUnit,
      quantity: row.amount,
      kcal: row.totalKcal,
      protein: row.totalProteinsGram,
      fat: row.totalFatsGram,
      carbs: row.totalCarbsGram,
      // Only when it was actually corrected. The house falls back to the
      // clock for a row nobody gave a slot, so sending this phone's idea of
      // the slot on every correction would quietly pin rows that were never
      // meant to be pinned.
      slot: intakeFields['slot'] as String?,
    );

    if (moveTo != null) {
      // Straight to the repository and not through DeleteIntakeUsecase: that
      // one also retires the household row, which is the opposite of what a
      // move means.
      await _intakeRepository.deleteIntake(row);
      return null;
    }
    return corrected ?? swapped;
  }
}
