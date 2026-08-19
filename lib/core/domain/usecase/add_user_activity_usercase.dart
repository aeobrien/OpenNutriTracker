import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';

/// Recording a piece of exercise the person did.
///
/// It writes twice, and that is the whole point. The app has always kept its
/// own record of an activity, and this release added a household ledger that
/// both people and the kitchen panel read. Before 19 August the household got
/// its exercise from a screen of its own, so the app's activity screen and the
/// household's day disagreed about the same walk — Aidan looked for his
/// exercise, found an "activity" section that said nothing about his watch, and
/// reported the app as having no exercise on a day he had burned five hundred
/// calories.
///
/// So there is one route in and it writes to both. The second route is deleted.
class AddUserActivityUsecase {
  final UserActivityRepository _userActivityRepository;
  final ExerciseSync _exerciseSync;
  final _log = Logger('AddUserActivityUsecase');

  AddUserActivityUsecase(this._userActivityRepository, this._exerciseSync);

  Future<void> addUserActivity(UserActivityEntity userActivityEntity) async {
    await _userActivityRepository.addUserActivity(userActivityEntity);
    await _alsoTellTheHousehold(userActivityEntity);
  }

  /// The household half.
  ///
  /// Deliberately cannot fail the local write. The activity is already saved by
  /// the time this runs, and the household write goes into a queue that holds
  /// and retries — so the only things that reach here are the ones the queue
  /// itself could not accept, and losing the person's activity because the
  /// house was not listening would be a worse outcome than a ledger that is
  /// briefly behind. The failure is logged rather than swallowed silently.
  Future<void> _alsoTellTheHousehold(UserActivityEntity activity) async {
    try {
      await _exerciseSync.typeIn(
        day: ExerciseSync.dayKey(activity.date),
        kcal: activity.burnedKcal,
        minutes: activity.duration,
        // The activity's own description, not its translated display name:
        // getName wants a BuildContext, and a ledger row that reads
        // differently depending on the phone's language is a ledger two people
        // cannot compare.
        note: activity.physicalActivityEntity.specificActivity,
        // The activity's own id, so a retried send is the same row rather than
        // a second walk.
        clientId: 'activity-${activity.id}',
      );
    } catch (e) {
      _log.warning('[EXERCISE] activity ${activity.id} saved locally but not '
          'put to the household: $e');
    }
  }
}
