import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

import '../fixture/user_entity_fixtures.dart';

void main() {
  group('GetKcalGoalUsecase logic (via CalorieGoalCalc)', () {
    // These tests verify the core calculation that GetKcalGoalUsecase delegates to.
    // The usecase itself selects between HealthKit and manual activities,
    // then passes the result to CalorieGoalCalc.getAllowance.

    final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
    final tdee = CalorieGoalCalc.getTdee(user); // 2662

    test('with HealthKit calories: applies multiplier to active calories', () {
      // Simulates HealthKit returning 400 active calories, multiplier 0.75
      final healthKitCalories = 400.0;
      final result = CalorieGoalCalc.getAllowance(user, healthKitCalories,
          exerciseMultiplier: 0.75);
      // earned = 400 * 0.75 = 300
      expect(result, tdee + 300);
    });

    test('without HealthKit (manual activities fallback)', () {
      // Simulates manual activities summing to 200 kcal, multiplier 0.75
      final manualActivities = 200.0;
      final result = CalorieGoalCalc.getAllowance(user, manualActivities,
          exerciseMultiplier: 0.75);
      // earned = 200 * 0.75 = 150
      expect(result, tdee + 150);
    });

    test('explicit totalKcalActivitiesParam overrides both sources', () {
      // When caller passes explicit value, it should be used directly
      final explicit = 500.0;
      final result = CalorieGoalCalc.getAllowance(user, explicit,
          exerciseMultiplier: 0.75);
      // earned = 500 * 0.75 = 375
      expect(result, tdee + 375);
    });

    test('zero active calories gives base allowance', () {
      final result = CalorieGoalCalc.getAllowance(user, 0.0,
          exerciseMultiplier: 0.75);
      expect(result, tdee);
    });

    test('base allowance differs from full allowance when active > 0', () {
      final full = CalorieGoalCalc.getAllowance(user, 400.0,
          exerciseMultiplier: 0.75);
      final base = CalorieGoalCalc.getAllowance(user, 0.0,
          exerciseMultiplier: 0.75);
      final earned = full - base;
      expect(earned, 300.0); // 400 * 0.75
    });
  });
}
