import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

void main() {
  group('IntakeEntity quick-add', () {
    test('isQuickAdd returns true for quickAdd entryType', () {
      final intake = IntakeEntity(
        id: 'qa-1',
        unit: 'serving',
        amount: 1.0,
        type: IntakeTypeEntity.snack,
        meal: MealEntity.empty(),
        dateTime: DateTime(2026, 2, 23),
        entryType: 'quickAdd',
      );

      expect(intake.isQuickAdd, isTrue);
    });

    test('isQuickAdd returns false for food entryType', () {
      final intake = IntakeEntity(
        id: 'food-1',
        unit: 'g',
        amount: 100.0,
        type: IntakeTypeEntity.lunch,
        meal: MealEntity.empty(),
        dateTime: DateTime(2026, 2, 23),
      );

      expect(intake.isQuickAdd, isFalse);
    });

    test('isQuickAdd returns false for default entryType', () {
      final intake = IntakeEntity(
        id: 'food-2',
        unit: 'g',
        amount: 50.0,
        type: IntakeTypeEntity.breakfast,
        meal: MealEntity.empty(),
        dateTime: DateTime(2026, 2, 23),
      );

      expect(intake.entryType, 'food');
      expect(intake.isQuickAdd, isFalse);
    });

    test('quick-add totalKcal returns snapshot value directly', () {
      final intake = IntakeEntity(
        id: 'qa-2',
        unit: 'serving',
        amount: 1.0,
        type: IntakeTypeEntity.lunch,
        meal: MealEntity.empty(),
        dateTime: DateTime(2026, 2, 23),
        entryType: 'quickAdd',
        snapshotKcal: 350,
        snapshotProtein: 20,
        snapshotCarbs: 40,
        snapshotFat: 10,
      );

      expect(intake.totalKcal, 350);
      expect(intake.totalProteinsGram, 20);
      expect(intake.totalCarbsGram, 40);
      expect(intake.totalFatsGram, 10);
    });

    test('food entry totalKcal computes from meal nutriments', () {
      final intake = IntakeEntity(
        id: 'food-3',
        unit: 'g',
        amount: 200.0,
        type: IntakeTypeEntity.dinner,
        meal: MealEntity(
          code: 'test-food',
          name: 'Test Food',
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: const MealNutrimentsEntity(
            energyKcal100: 150,
            proteins100: 10,
            carbohydrates100: 20,
            fat100: 5,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null,
          ),
          source: MealSourceEntity.custom,
        ),
        dateTime: DateTime(2026, 2, 23),
        snapshotKcal: 300,
        snapshotProtein: 20,
        snapshotCarbs: 40,
        snapshotFat: 10,
      );

      // Food entry should compute from nutriments, not snapshot
      // 200g * (150/100) = 300 kcal
      expect(intake.totalKcal, 300);
      // 200g * (10/100) = 20g protein
      expect(intake.totalProteinsGram, 20);
      // 200g * (20/100) = 40g carbs
      expect(intake.totalCarbsGram, 40);
      // 200g * (5/100) = 10g fat
      expect(intake.totalFatsGram, 10);
    });

    test('quick-add with zero macros returns zero for macros', () {
      final intake = IntakeEntity(
        id: 'qa-3',
        unit: 'serving',
        amount: 1.0,
        type: IntakeTypeEntity.snack,
        meal: MealEntity.empty(),
        dateTime: DateTime(2026, 2, 23),
        entryType: 'quickAdd',
        snapshotKcal: 200,
      );

      expect(intake.totalKcal, 200);
      expect(intake.totalProteinsGram, 0);
      expect(intake.totalCarbsGram, 0);
      expect(intake.totalFatsGram, 0);
    });

    test('quick-add quickAddLabel is preserved', () {
      final intake = IntakeEntity(
        id: 'qa-4',
        unit: 'serving',
        amount: 1.0,
        type: IntakeTypeEntity.breakfast,
        meal: MealEntity.empty(),
        dateTime: DateTime(2026, 2, 23),
        entryType: 'quickAdd',
        quickAddLabel: 'Coffee and toast',
        snapshotKcal: 250,
      );

      expect(intake.quickAddLabel, 'Coffee and toast');
      expect(intake.isQuickAdd, isTrue);
    });

    test('quick-add quickAddLabel defaults to null', () {
      final intake = IntakeEntity(
        id: 'qa-5',
        unit: 'serving',
        amount: 1.0,
        type: IntakeTypeEntity.snack,
        meal: MealEntity.empty(),
        dateTime: DateTime(2026, 2, 23),
        entryType: 'quickAdd',
        snapshotKcal: 100,
      );

      expect(intake.quickAddLabel, isNull);
    });
  });
}
