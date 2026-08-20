import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';

class DeleteIntakeUsecase {
  final IntakeRepository _intakeRepository;

  /// The household half. Optional so the app runs unchanged where the house has
  /// never been set up, and so a test can leave it out.
  final FoodLedger? _household;

  DeleteIntakeUsecase(this._intakeRepository, [this._household]);

  /// Take something back off the day — here, and on the Mac Mini.
  ///
  /// Both, in one place, because there are two screens that delete a row and
  /// there will be more. A row removed here but left counting there is the
  /// worst kind of wrong: two machines disagree about somebody's day and
  /// neither says so.
  ///
  /// The household end is soft — the row stays and stops counting — and if the
  /// row came from confirming a planned meal, the meal goes back to waiting for
  /// an answer rather than disappearing from the day in both directions.
  Future<void> deleteIntake(IntakeEntity intakeEntity) async {
    await _intakeRepository.deleteIntake(intakeEntity);
    await _household?.retire(intakeEntity.householdName);
  }
}
