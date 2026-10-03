import 'package:collection/collection.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

class GetKcalGoalUsecase {
  final UserRepository _userRepository;
  final ConfigRepository _configRepository;
  final UserActivityRepository _userActivityRepository;
  final HealthRepository _healthRepository;

  GetKcalGoalUsecase(this._userRepository, this._configRepository,
      this._userActivityRepository, this._healthRepository);

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
    return CalorieGoalCalc.getAllowance(user, totalKcalActivities,
        kcalUserAdjustment: config.userKcalAdjustment,
        exerciseMultiplier: exerciseMultiplier);
  }
}
