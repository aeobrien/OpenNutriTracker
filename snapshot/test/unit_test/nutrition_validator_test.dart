import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';

void main() {
  group('NutritionValidator', () {
    test('perfect match returns ok', () {
      // P:25*4=100, C:50*4=200, F:10*9=90 => 390
      final result = NutritionValidator.validateConsistency(
        reportedKcal: 390,
        proteinGrams: 25,
        carbsGrams: 50,
        fatGrams: 10,
      );
      expect(result.calculatedKcal, 390);
      expect(result.deviationPct, 0);
      expect(result.status, ValidationStatus.ok);
    });

    test('small deviation (< 15%) returns ok', () {
      // Calculated: 390, reported: 380 => deviation = 2.6%
      final result = NutritionValidator.validateConsistency(
        reportedKcal: 380,
        proteinGrams: 25,
        carbsGrams: 50,
        fatGrams: 10,
      );
      expect(result.status, ValidationStatus.ok);
      expect(result.deviationPct, closeTo(2.63, 0.1));
    });

    test('moderate deviation (15-40%) returns reviewRecommended', () {
      // Calculated: 390, reported: 300 => deviation = 30%
      final result = NutritionValidator.validateConsistency(
        reportedKcal: 300,
        proteinGrams: 25,
        carbsGrams: 50,
        fatGrams: 10,
      );
      expect(result.status, ValidationStatus.reviewRecommended);
    });

    test('large deviation (> 40%) returns likelyError', () {
      // Calculated: 390, reported: 200 => deviation = 95%
      final result = NutritionValidator.validateConsistency(
        reportedKcal: 200,
        proteinGrams: 25,
        carbsGrams: 50,
        fatGrams: 10,
      );
      expect(result.status, ValidationStatus.likelyError);
    });

    test('all zeros returns ok', () {
      final result = NutritionValidator.validateConsistency(
        reportedKcal: 0,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
      );
      expect(result.calculatedKcal, 0);
      expect(result.deviationPct, 0);
      expect(result.status, ValidationStatus.ok);
    });

    test('zero reported but non-zero macros returns likelyError', () {
      final result = NutritionValidator.validateConsistency(
        reportedKcal: 0,
        proteinGrams: 25,
        carbsGrams: 50,
        fatGrams: 10,
      );
      expect(result.deviationPct, 100);
      expect(result.status, ValidationStatus.likelyError);
    });

    test('fibre adjustment reduces calculated kcal', () {
      // Without fibre: P:10*4=40, C:30*4=120, F:5*9=45 => 205
      // With 10g fibre: digestible carbs = 20, fibre at 2kcal/g
      // P:10*4=40, C:20*4=80, fibre:10*2=20, F:5*9=45 => 185
      final result = NutritionValidator.validateConsistency(
        reportedKcal: 185,
        proteinGrams: 10,
        carbsGrams: 30,
        fatGrams: 5,
        fibreGrams: 10,
      );
      expect(result.calculatedKcal, 185);
      expect(result.status, ValidationStatus.ok);
    });

    test('exactly 15% deviation is ok', () {
      // Calculated: 100, reported: 100/1.15 ≈ 86.96 => exactly 15%
      // P:25*4=100, C:0, F:0 => 100
      final result = NutritionValidator.validateConsistency(
        reportedKcal: 100 / 1.15,
        proteinGrams: 25,
        carbsGrams: 0,
        fatGrams: 0,
      );
      expect(result.status, ValidationStatus.ok);
    });
  });
}
