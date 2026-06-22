import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/recipes/data/dto/mealie/mealie_nutrition_dto.dart';
import 'package:opennutritracker/features/recipes/data/dto/mealie/mealie_recipe_dto.dart';
import 'package:opennutritracker/features/recipes/data/mealie_recipe_mapper.dart';

void main() {
  final ts = DateTime(2026, 1, 1);

  MealieRecipeDto dto({
    double servings = 2,
    MealieNutritionDto? nutrition,
    List<MealieIngredientDto> ingredients = const [],
  }) =>
      MealieRecipeDto(
        id: '1',
        name: 'Carbonara',
        slug: 'carbonara',
        recipeServings: servings,
        nutrition: nutrition,
        ingredients: ingredients,
      );

  group('MealieRecipeMapper', () {
    test('per-serving (default) passes nutrition straight through', () {
      final r = MealieRecipeMapper.toRecipeEntity(
        dto(
          nutrition: const MealieNutritionDto(
            calories: '500',
            proteinContent: '25',
            carbohydrateContent: '40',
            fatContent: '20',
          ),
        ),
        timestamp: ts,
      );
      expect(r.id, 'carbonara');
      expect(r.name, 'Carbonara');
      expect(r.servings, 2);
      expect(r.kcalPerServing, 500);
      expect(r.proteinPerServing, 25);
      expect(r.carbsPerServing, 40);
      expect(r.fatPerServing, 20);
    });

    test('whole-recipe mode divides nutrition by servings', () {
      final r = MealieRecipeMapper.toRecipeEntity(
        dto(
          servings: 4,
          nutrition: const MealieNutritionDto(
            calories: '800',
            proteinContent: '40',
            carbohydrateContent: '80',
            fatContent: '40',
          ),
        ),
        nutritionIsPerServing: false,
        timestamp: ts,
      );
      expect(r.kcalPerServing, 200);
      expect(r.proteinPerServing, 10);
      expect(r.carbsPerServing, 20);
      expect(r.fatPerServing, 10);
    });

    test('null nutrition yields zeros, never throws', () {
      final r = MealieRecipeMapper.toRecipeEntity(dto(nutrition: null), timestamp: ts);
      expect(r.kcalPerServing, 0);
      expect(r.proteinPerServing, 0);
      expect(r.carbsPerServing, 0);
      expect(r.fatPerServing, 0);
    });

    test('zero servings clamps to 1 (no divide-by-zero)', () {
      final r = MealieRecipeMapper.toRecipeEntity(
        dto(servings: 0, nutrition: const MealieNutritionDto(calories: '300')),
        nutritionIsPerServing: false,
        timestamp: ts,
      );
      expect(r.servings, 1);
      expect(r.kcalPerServing, 300);
    });

    test('tolerant string parsing (decimals, trailing units, empty, null)', () {
      final r = MealieRecipeMapper.toRecipeEntity(
        dto(
          nutrition: const MealieNutritionDto(
            calories: '250.5',
            proteinContent: '12 g',
            carbohydrateContent: '',
            fatContent: null,
          ),
        ),
        timestamp: ts,
      );
      expect(r.kcalPerServing, 250.5);
      expect(r.proteinPerServing, 12);
      expect(r.carbsPerServing, 0);
      expect(r.fatPerServing, 0);
    });

    test('ingredients are mapped for display only (no per-ingredient macros)', () {
      final r = MealieRecipeMapper.toRecipeEntity(
        dto(ingredients: const [
          MealieIngredientDto(display: '200 g spaghetti'),
          MealieIngredientDto(foodName: 'egg', quantity: 2),
        ]),
        timestamp: ts,
      );
      expect(r.ingredients.length, 2);
      expect(r.ingredients[0].name, '200 g spaghetti');
      expect(r.ingredients[0].grams, 0);
      expect(r.ingredients[0].kcalPer100, 0);
      expect(r.ingredients[1].name, '2 egg');
      expect(r.ingredients[1].sortOrder, 1);
    });
  });
}
