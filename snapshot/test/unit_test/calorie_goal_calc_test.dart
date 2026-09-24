import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

import '../fixture/user_entity_fixtures.dart';

void main() {
  group('Calorie Goal Calc Test', () {
    late UserEntity youngSedentaryMaleWantingToMaintainWeight;
    late UserEntity middleAgedActiveFemaleWantingToLoseWeight;

    setUp(() {
      youngSedentaryMaleWantingToMaintainWeight =
          UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
      middleAgedActiveFemaleWantingToLoseWeight =
          UserEntityFixtures.middleAgedActiveFemaleWantingToLoseWeight;
    });

    test(
        'Total Kcal Goal calculation for a young sedentary male wanting to maintain weight',
        () {
      final user = youngSedentaryMaleWantingToMaintainWeight;

      double resultCalorieGoal = CalorieGoalCalc.getTotalKcalGoal(user, 200.0);

      // TDEE: 2662, Activities: 200, Adjustment: + 0
      // 2662 + 200 + 0 = 2862
      int expectedKcal = 2862;

      expect(resultCalorieGoal.toInt(), expectedKcal);
    });

    test(
        'Total Kcal Goal calculation for a middle aged sedentary female wanting to maintain weight',
        () {
      final user = middleAgedActiveFemaleWantingToLoseWeight;

      double resultCalorieGoal = CalorieGoalCalc.getTotalKcalGoal(user, 550.0);

      // TDEE: 2087, Activities: 550, Adjustment: -500
      // 2087 + 550 - 500 = 2137
      int expectedKcal = 2137;

      expect(resultCalorieGoal.toInt(), expectedKcal);
    });
  });

  group('Allowance and Earned Calories', () {
    late UserEntity user;

    setUp(() {
      user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
    });

    test('getAllowance with default multiplier (0.75)', () {
      // TDEE: 2662, goal adj: 0, exercise: 400 * 0.75 = 300
      final result = CalorieGoalCalc.getAllowance(user, 400.0);
      expect(result.toInt(), 2962);
    });

    test('getAllowance with multiplier 0.5', () {
      // TDEE: 2662, goal adj: 0, exercise: 400 * 0.5 = 200
      final result =
          CalorieGoalCalc.getAllowance(user, 400.0, exerciseMultiplier: 0.5);
      expect(result.toInt(), 2862);
    });

    test('getAllowance with multiplier 1.0 matches getTotalKcalGoal', () {
      final allowance =
          CalorieGoalCalc.getAllowance(user, 400.0, exerciseMultiplier: 1.0);
      final legacy = CalorieGoalCalc.getTotalKcalGoal(user, 400.0);
      expect(allowance, legacy);
    });

    test('getAllowance with multiplier 0 ignores exercise', () {
      final result =
          CalorieGoalCalc.getAllowance(user, 400.0, exerciseMultiplier: 0);
      // TDEE: 2662, goal adj: 0, exercise: 0
      expect(result.toInt(), 2662);
    });

    test('getEarnedCalories with zero exercise', () {
      expect(CalorieGoalCalc.getEarnedCalories(0), 0);
    });

    test('getEarnedCalories with default multiplier', () {
      expect(CalorieGoalCalc.getEarnedCalories(400.0), 300.0);
    });

    test('getRemaining positive', () {
      expect(CalorieGoalCalc.getRemaining(2000, 1500), 500);
    });

    test('getRemaining negative (over target)', () {
      expect(CalorieGoalCalc.getRemaining(2000, 2500), -500);
    });

    test('getEarnedCalories with multiplier 0.0 returns 0', () {
      expect(
          CalorieGoalCalc.getEarnedCalories(500, exerciseMultiplier: 0.0), 0.0);
    });

    test('getEarnedCalories with multiplier 1.0 returns full calories', () {
      expect(
          CalorieGoalCalc.getEarnedCalories(500, exerciseMultiplier: 1.0), 500.0);
    });

    test('getAllowance with active calories 0 gives base only', () {
      final base = CalorieGoalCalc.getAllowance(user, 0.0);
      final tdee = CalorieGoalCalc.getTdee(user);
      expect(base, tdee); // goal adj = 0 for maintain weight
    });

    test('getAllowance with active calories and custom multiplier', () {
      final result =
          CalorieGoalCalc.getAllowance(user, 600.0, exerciseMultiplier: 0.5);
      final tdee = CalorieGoalCalc.getTdee(user);
      // earned = 600 * 0.5 = 300
      expect(result, tdee + 300);
    });
  });
}
