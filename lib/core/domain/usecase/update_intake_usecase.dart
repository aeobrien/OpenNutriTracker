import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';

class UpdateIntakeUsecase {
  final IntakeRepository _intakeRepository;

  /// The household half. Optional so the app runs unchanged where the house has
  /// never been set up, and so a test can leave it out.
  final FoodLedger? _household;

  UpdateIntakeUsecase(this._intakeRepository, [this._household]);

  /// Correct something already logged — here, and on the kitchen computer.
  ///
  /// [moveTo] moves the row to the other person's day. It travels with the
  /// amount rather than in a call of its own: they are noticed at the same
  /// moment and a move that landed without the corrected figure would leave
  /// both people's totals wrong with nothing to say so.
  ///
  /// The figures sent are worked out from the row as it is *after* the change,
  /// so the kitchen computer is told what the number now is rather than being
  /// asked to redo the phone's arithmetic.
  Future<IntakeEntity?> updateIntake(
      String intakeId, Map<String, dynamic> intakeFields,
      {int? moveTo}) async {
    final updated =
        await _intakeRepository.updateIntake(intakeId, intakeFields);
    if (updated != null) {
      await _household?.amend(
        updated.id,
        moveTo: moveTo,
        quantity: updated.amount,
        kcal: updated.totalKcal,
        protein: updated.totalProteinsGram,
        fat: updated.totalFatsGram,
        carbs: updated.totalCarbsGram,
      );
    }
    return updated;
  }
}
