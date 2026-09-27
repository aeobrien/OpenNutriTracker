import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

class GetHealthUsecase {
  final HealthRepository _healthRepository;
  final ConfigRepository _configRepository;

  GetHealthUsecase(this._healthRepository, this._configRepository);

  Future<double> getActiveCalories() =>
      _healthRepository.fetchAndCacheActiveCalories();

  Future<double> getEarnedCalories() async {
    final activeCalories = await getActiveCalories();
    final multiplier = await _configRepository.getExerciseMultiplier();
    return CalorieGoalCalc.getEarnedCalories(activeCalories,
        exerciseMultiplier: multiplier);
  }

  Future<bool> requestPermission() =>
      _healthRepository.requestPermission();

  Future<bool> hasPermission() =>
      _healthRepository.hasPermission();
}
