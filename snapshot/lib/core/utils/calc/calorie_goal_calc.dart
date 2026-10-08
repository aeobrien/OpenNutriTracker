import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
import 'package:opennutritracker/core/utils/calc/tdee_calc.dart';

class CalorieGoalCalc {
  static const double loseWeightKcalAdjustment = -500;
  static const double maintainWeightKcalAdjustment = 0;
  static const double gainWeightKcalAdjustment = 500;

  static const double defaultExerciseMultiplier = 0.75;

  static double getDailyKcalLeft(
          double totalKcalGoal, double totalKcalIntake) =>
      totalKcalGoal - totalKcalIntake;

  static double getTdee(UserEntity userEntity) =>
      TDEECalc.getTDEEKcalIOM2005(userEntity);

  /// Returns activeCalories scaled by the exercise multiplier.
  static double getEarnedCalories(double activeCalories,
          {double exerciseMultiplier = defaultExerciseMultiplier}) =>
      activeCalories * exerciseMultiplier;

  /// Full daily allowance: TDEE + goal adjustment + user adjustment + earned calories.
  static double getAllowance(UserEntity userEntity, double activeCalories,
          {double? kcalUserAdjustment,
          double exerciseMultiplier = defaultExerciseMultiplier}) =>
      getTdee(userEntity) +
      getKcalGoalAdjustment(userEntity.goal) +
      (kcalUserAdjustment ?? 0) +
      getEarnedCalories(activeCalories,
          exerciseMultiplier: exerciseMultiplier);

  /// Remaining calories: allowance - intake.
  static double getRemaining(double allowance, double intake) =>
      allowance - intake;

  /// @deprecated Use [getAllowance] instead. Kept for backward compatibility.
  static double getTotalKcalGoal(
          UserEntity userEntity, double totalKcalActivities,
          {double? kcalUserAdjustment}) =>
      getAllowance(userEntity, totalKcalActivities,
          kcalUserAdjustment: kcalUserAdjustment, exerciseMultiplier: 1.0);

  static double getKcalGoalAdjustment(UserWeightGoalEntity goal) {
    double kcalAdjustment;
    if (goal == UserWeightGoalEntity.loseWeight) {
      kcalAdjustment = loseWeightKcalAdjustment;
    } else if (goal == UserWeightGoalEntity.gainWeight) {
      kcalAdjustment = gainWeightKcalAdjustment;
    } else {
      kcalAdjustment = maintainWeightKcalAdjustment;
    }
    return kcalAdjustment;
  }
}
