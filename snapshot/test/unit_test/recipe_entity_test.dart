import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';

void main() {
  group('RecipeEntity', () {
    test('copyWith preserves all fields when none provided', () {
      final entity = RecipeEntity(
        id: 'r1',
        name: 'Pasta',
        servings: 4.0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
        favourite: true,
        kcalPerServing: 500,
        proteinPerServing: 20,
        carbsPerServing: 60,
        fatPerServing: 15,
      );

      final copy = entity.copyWith();
      expect(copy, equals(entity));
    });

    test('copyWith overrides specified fields', () {
      final entity = RecipeEntity(
        id: 'r1',
        name: 'Pasta',
        servings: 4.0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 2),
      );

      final copy = entity.copyWith(name: 'Rice', servings: 2.0);
      expect(copy.name, 'Rice');
      expect(copy.servings, 2.0);
      expect(copy.id, 'r1');
    });

    test('empty ingredients list by default', () {
      final entity = RecipeEntity(
        id: 'r1',
        name: 'Empty',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(entity.ingredients, isEmpty);
    });
  });

  group('RecipeIngredientEntity', () {
    test('toRecipeIngredient creates correct RecipeIngredient', () {
      const entity = RecipeIngredientEntity(
        id: 'i1',
        recipeId: 'r1',
        name: 'Flour',
        grams: 200,
        kcalPer100: 364,
        proteinPer100: 10,
        carbsPer100: 76,
        fatPer100: 1,
      );

      final ri = entity.toRecipeIngredient();
      expect(ri.kcalPer100g, 364);
      expect(ri.proteinPer100g, 10);
      expect(ri.carbsPer100g, 76);
      expect(ri.fatPer100g, 1);
      expect(ri.grams, 200);
    });

    test('copyWith overrides grams', () {
      const entity = RecipeIngredientEntity(
        id: 'i1',
        recipeId: 'r1',
        name: 'Flour',
        grams: 200,
        kcalPer100: 364,
      );

      final copy = entity.copyWith(grams: 300);
      expect(copy.grams, 300);
      expect(copy.name, 'Flour');
      expect(copy.kcalPer100, 364);
    });

    test('default values are zero', () {
      const entity = RecipeIngredientEntity(
        id: 'i1',
        recipeId: 'r1',
        name: 'Water',
        grams: 100,
      );

      expect(entity.kcalPer100, 0);
      expect(entity.proteinPer100, 0);
      expect(entity.carbsPer100, 0);
      expect(entity.fatPer100, 0);
      expect(entity.sortOrder, 0);
    });
  });
}
