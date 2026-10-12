import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';

void main() {
  MealEntity _makeMeal({double? lastUsedGrams, bool favourite = false}) {
    return MealEntity(
      code: 'test-1',
      name: 'Test Food',
      url: null,
      mealQuantity: '100',
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: null,
      servingSize: null,
      nutriments: MealNutrimentsEntity.empty(),
      source: MealSourceEntity.custom,
      lastUsedGrams: lastUsedGrams,
      favourite: favourite,
    );
  }

  group('MealEntity new fields', () {
    test('lastUsedGrams is carried through', () {
      final meal = _makeMeal(lastUsedGrams: 200.0);
      expect(meal.lastUsedGrams, 200.0);
    });

    test('lastUsedGrams defaults to null', () {
      final meal = _makeMeal();
      expect(meal.lastUsedGrams, isNull);
    });

    test('favourite defaults to false', () {
      final meal = _makeMeal();
      expect(meal.favourite, isFalse);
    });

    test('copyWithFavourite returns new instance with toggled value', () {
      final meal = _makeMeal(favourite: false);
      final toggled = meal.copyWithFavourite(true);

      expect(toggled.favourite, isTrue);
      expect(toggled.code, equals(meal.code));
      expect(toggled.name, equals(meal.name));
    });

    test('MealEntity.empty() has null lastUsedGrams and false favourite', () {
      final empty = MealEntity.empty();
      expect(empty.lastUsedGrams, isNull);
      expect(empty.favourite, isFalse);
    });
  });
}
