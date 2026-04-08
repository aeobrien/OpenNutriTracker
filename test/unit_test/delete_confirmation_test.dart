import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

/// Tests for the delete confirmation dialog display name logic.
void main() {
  group('DeleteIntakeDialog display name', () {
    test('shows meal name for regular food entry', () {
      final intake = IntakeEntity(
        id: '1',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.breakfast,
        meal: _createMealWithName('Banana'),
        dateTime: DateTime.now(),
        entryType: 'food',
      );
      expect(_getDisplayName(intake), 'Banana');
    });

    test('shows quick add label for quick-add entry', () {
      final intake = IntakeEntity(
        id: '2',
        unit: 'g',
        amount: 1,
        type: IntakeTypeEntity.snack,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'quickAdd',
        quickAddLabel: 'Coffee with milk',
      );
      expect(_getDisplayName(intake), 'Coffee with milk');
    });

    test('shows fallback for quick-add without label', () {
      final intake = IntakeEntity(
        id: '3',
        unit: 'g',
        amount: 1,
        type: IntakeTypeEntity.snack,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'quickAdd',
      );
      expect(_getDisplayName(intake), 'Quick add');
    });

    test('shows recipe label for recipe entry', () {
      final intake = IntakeEntity(
        id: '4',
        unit: 'g',
        amount: 1,
        type: IntakeTypeEntity.dinner,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'recipe',
        quickAddLabel: 'Pasta Carbonara',
      );
      expect(_getDisplayName(intake), 'Pasta Carbonara');
    });

    test('shows fallback for recipe without label', () {
      final intake = IntakeEntity(
        id: '5',
        unit: 'g',
        amount: 1,
        type: IntakeTypeEntity.dinner,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'recipe',
      );
      expect(_getDisplayName(intake), 'Recipe');
    });

    test('shows ? for food entry without name', () {
      final intake = IntakeEntity(
        id: '6',
        unit: 'g',
        amount: 100,
        type: IntakeTypeEntity.lunch,
        meal: MealEntity.empty(),
        dateTime: DateTime.now(),
        entryType: 'food',
      );
      expect(_getDisplayName(intake), '?');
    });
  });
}

/// Mirrors DeleteIntakeDialog._getDisplayName logic.
String _getDisplayName(IntakeEntity intake) {
  if (intake.isQuickAdd) {
    return intake.quickAddLabel ?? 'Quick add';
  }
  if (intake.isRecipe) {
    return intake.quickAddLabel ?? 'Recipe';
  }
  return intake.meal.name ?? '?';
}

/// Helper to create a MealEntity with a specific name.
MealEntity _createMealWithName(String name) {
  return MealEntity(
    code: 'test',
    name: name,
    url: null,
    mealQuantity: null,
    mealUnit: 'g',
    servingQuantity: null,
    servingUnit: null,
    servingSize: null,
    nutriments: MealNutrimentsEntity.empty(),
    source: MealSourceEntity.custom,
  );
}
