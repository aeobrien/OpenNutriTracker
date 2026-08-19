import 'package:collection/collection.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';

/// The one place the day's calorie target is decided.
///
/// It is one place on purpose. Until 19 August it was not: the app worked a
/// target out from height, weight, activity and goal and drew it on the Home
/// ring, while the household kept a second target that Aidan could type into
/// Settings. He typed 2400, and Home carried on showing the figure the app had
/// calculated during setup. Two numbers, two screens, and nothing to tell him
/// which one counted.
///
/// Now the household's target, when there is one, is the base of the day's
/// allowance, and the app's own calculation is the suggestion it starts from.
/// Exercise is still added on top of whichever base is in force — turning the
/// typed target into a flat ceiling would have quietly stopped a hard walk
/// moving the ring, and that is a thing he watches.
class GetKcalGoalUsecase {
  final UserRepository _userRepository;
  final ConfigRepository _configRepository;
  final UserActivityRepository _userActivityRepository;
  final HealthRepository _healthRepository;
  final HouseholdRepository _householdRepository;

  GetKcalGoalUsecase(this._userRepository, this._configRepository,
      this._userActivityRepository, this._healthRepository,
      this._householdRepository);

  /// The target the household holds for whoever owns this phone, or null when
  /// nobody has set one.
  ///
  /// Read from the local copy rather than the server. The ring is drawn every
  /// time the Home screen is built, and a screen that cannot draw its main
  /// number while the Mini is slow would be a worse fault than the one this
  /// method exists to fix.
  Future<double?> _householdTarget() async {
    final owner = await _householdRepository.storedOwner();
    if (owner == null) return null;
    final settings = await _householdRepository.cachedSettings(owner);
    final target = settings.dailyTargetKcal;
    if (target == null || target <= 0) return null;
    return target.toDouble();
  }

  Future<double> getKcalGoal(
      {UserEntity? userEntity,
      double? totalKcalActivitiesParam,
      double? kcalUserAdjustment}) async {
    final user = userEntity ?? await _userRepository.getUserData();
    final config = await _configRepository.getConfig();

    double totalKcalActivities;
    if (totalKcalActivitiesParam != null) {
      totalKcalActivities = totalKcalActivitiesParam;
    } else {
      // Prefer HealthKit if permission granted
      final hasHealthPermission = await _healthRepository.hasPermission();
      if (hasHealthPermission) {
        totalKcalActivities =
            await _healthRepository.fetchAndCacheActiveCalories();
      } else {
        totalKcalActivities =
            (await _userActivityRepository.getAllUserActivityByDate(DateTime.now()))
                .map((activity) => activity.burnedKcal)
                .toList()
                .sum;
      }
    }

    final exerciseMultiplier =
        config.exerciseMultiplier ?? CalorieGoalCalc.defaultExerciseMultiplier;

    final household = await _householdTarget();
    if (household != null) {
      return CalorieGoalCalc.getAllowanceFrom(household, totalKcalActivities,
          exerciseMultiplier: exerciseMultiplier);
    }

    return CalorieGoalCalc.getAllowance(user, totalKcalActivities,
        kcalUserAdjustment: config.userKcalAdjustment,
        exerciseMultiplier: exerciseMultiplier);
  }
}
