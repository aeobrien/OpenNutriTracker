import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Tests for quick-add visual distinction logic.
/// Validates that isQuickAdd correctly identifies entries that should
/// receive the badge treatment.
void main() {
  group('Quick-add visual distinction', () {
    test('isQuickAdd returns true for quickAdd entry type', () {
      final intake = IntakeEntity(
        id: '1',
        unit: 'g',
        amount: 1,
        type: IntakeTypeEntity.snack,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'quickAdd',
      );
      expect(intake.isQuickAdd, true);
    });

    test('isQuickAdd returns false for food entry type', () {
      final intake = IntakeEntity(
        id: '2',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.breakfast,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'food',
      );
      expect(intake.isQuickAdd, false);
    });

    test('isQuickAdd returns false for recipe entry type', () {
      final intake = IntakeEntity(
        id: '3',
        unit: 'g',
        amount: 1,
        type: IntakeTypeEntity.dinner,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'recipe',
      );
      expect(intake.isQuickAdd, false);
    });

    test('isRecipe returns true for recipe entry type', () {
      final intake = IntakeEntity(
        id: '4',
        unit: 'g',
        amount: 1,
        type: IntakeTypeEntity.dinner,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'recipe',
      );
      expect(intake.isRecipe, true);
    });

    test('default entry type is food', () {
      final intake = IntakeEntity(
        id: '5',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.lunch,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
      );
      expect(intake.entryType, 'food');
      expect(intake.isQuickAdd, false);
      expect(intake.isRecipe, false);
    });
  });
}
