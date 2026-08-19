import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/week/domain/week_view.dart';

/// Getting a week, for the person whose phone this is.
///
/// A read and nothing else. Nothing on this path writes, so there is no queue
/// behind it and no offline story beyond "could not ask" — which the screen
/// says in words rather than showing an empty week.
class WeekRepository {
  final HouseholdApi _api;
  final HouseholdRepository _household;

  WeekRepository(this._api, this._household);

  /// [start] names the Monday. Leaving it off means the week today is in,
  /// decided by the kitchen computer rather than by this phone's clock — the
  /// two handsets and the panel have to agree about where a week starts.
  Future<WeekView> mine({String? start}) async {
    final owner = await _household.storedOwner();
    if (owner == null) {
      throw StateError('nobody has said whose phone this is');
    }
    return forPerson(owner, start: start);
  }

  Future<WeekView> forPerson(int personId, {String? start}) async =>
      WeekView.fromJson(await _api.week(personId, start: start));
}
