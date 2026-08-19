import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

/// Getting one day, for the person whose phone this is.
class DayRepository {
  final HouseholdApi _api;
  final HouseholdRepository _household;

  DayRepository(this._api, this._household);

  /// The day for whoever holds this phone. Throws [HouseholdUnreachable] when
  /// the Mini cannot be reached — the screen says so plainly rather than
  /// showing an empty day, which would read as "you have eaten nothing".
  Future<DayView> today(String day) async {
    final owner = await _household.storedOwner();
    if (owner == null) {
      throw StateError('nobody has said whose phone this is');
    }
    return forPerson(owner, day);
  }

  Future<DayView> forPerson(int personId, String day) async =>
      DayView.fromJson(await _api.day(personId, day));
}
