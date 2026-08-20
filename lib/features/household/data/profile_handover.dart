import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/domain/remembered_profile.dart';

/// Moves the app's setup answers between this phone and the kitchen computer.
///
/// One direction each way, and they are not symmetrical:
///
///  * [bringBack] runs the moment somebody says whose phone this is. If the
///    household already knows them, setup never appears.
///  * [remember] runs when setup finishes, so the next reinstall does not ask.
///
/// Everything here fails quietly by design. A kitchen computer that is asleep
/// must mean "ask the questions" and never "refuse to start" — the app has to
/// work away from the house, and the six questions are a mild annoyance where
/// a phone that will not open is not.
class ProfileHandover {
  final HouseholdApi _api;
  final UserRepository _users;

  ProfileHandover(this._api, this._users);

  /// True when this phone now has a profile it did not have before.
  ///
  /// It never overwrites one already here. Somebody who has just answered the
  /// questions on this phone has said something more current than whatever the
  /// household last heard, and quietly replacing it would undo their answers.
  Future<bool> bringBack(int personId) async {
    try {
      if (await _users.hasUserData()) return false;
      final user = RememberedProfile.from(await _api.profileFor(personId));
      if (user == null) return false;
      await _users.updateUserData(user);
      return true;
    } catch (_) {
      // Unreachable, half-stored, or a word this app does not know: all three
      // mean the same thing to the caller — ask the questions.
      return false;
    }
  }

  Future<void> remember(int personId, UserEntity user) async {
    try {
      await _api.rememberProfile(personId, RememberedProfile.of(user));
    } catch (_) {
      // Setup has already finished on this phone. Failing to tell the house
      // costs one more round of questions after the next reinstall, and is not
      // worth an error in front of somebody who has just finished answering.
    }
  }
}
