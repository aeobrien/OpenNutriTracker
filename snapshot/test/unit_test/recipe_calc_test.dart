import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/recipe_calc.dart';

void main() {
  group('RecipeCalc', () {
    test('single ingredient total', () {
      final ingredients = [
        const RecipeIngredient(
          kcalPer100g: 200,
          proteinPer100g: 10,
          carbsPer100g: 30,
          fatPer100g: 5,
          grams: 250,
        ),
      ];
      final total = RecipeCalc.calculateTotal(ingredients);
      expect(total.kcal, 500); // 200 * 2.5
      expect(total.protein, 25); // 10 * 2.5
      expect(total.carbs, 75); // 30 * 2.5
      expect(total.fat, 12.5); // 5 * 2.5
    });

    test('multiple ingredients summed', () {
      final ingredients = [
        const RecipeIngredient(
          kcalPer100g: 100,
          proteinPer100g: 5,
          carbsPer100g: 20,
          fatPer100g: 2,
          grams: 200,
        ),
        const RecipeIngredient(
          kcalPer100g: 300,
          proteinPer100g: 20,
          carbsPer100g: 10,
          fatPer100g: 15,
          grams: 100,
        ),
      ];
      final total = RecipeCalc.calculateTotal(ingredients);
      // Ingredient 1: 200, 10, 40, 4
      // Ingredient 2: 300, 20, 10, 15
      expect(total.kcal, 500);
      expect(total.protein, 30);
      expect(total.carbs, 50);
      expect(total.fat, 19);
    });

    test('per serving divides correctly', () {
      final ingredients = [
        const RecipeIngredient(
          kcalPer100g: 200,
          proteinPer100g: 10,
          carbsPer100g: 30,
          fatPer100g: 5,
          grams: 400,
        ),
      ];
      final perServing = RecipeCalc.calculatePerServing(ingredients, 4);
      expect(perServing.kcal, 200); // 800 / 4
      expect(perServing.protein, 10); // 40 / 4
      expect(perServing.carbs, 30); // 120 / 4
      expect(perServing.fat, 5); // 20 / 4
    });

    test('fractional servings', () {
      final ingredients = [
        const RecipeIngredient(
          kcalPer100g: 100,
          proteinPer100g: 10,
          carbsPer100g: 20,
          fatPer100g: 5,
          grams: 100,
        ),
      ];
      final perServing = RecipeCalc.calculatePerServing(ingredients, 0.5);
      expect(perServing.kcal, 200); // 100 / 0.5
    });

    test('empty ingredient list', () {
      final total = RecipeCalc.calculateTotal([]);
      expect(total.kcal, 0);
      expect(total.protein, 0);
      expect(total.carbs, 0);
      expect(total.fat, 0);
    });

    test('zero servings returns total (no division by zero)', () {
      final ingredients = [
        const RecipeIngredient(
          kcalPer100g: 100,
          proteinPer100g: 10,
          carbsPer100g: 20,
          fatPer100g: 5,
          grams: 100,
        ),
      ];
      final result = RecipeCalc.calculatePerServing(ingredients, 0);
      expect(result.kcal, 100); // returns total when servings <= 0
    });
  });
}
