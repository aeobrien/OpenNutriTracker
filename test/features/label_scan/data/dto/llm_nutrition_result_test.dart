import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';

void main() {
  group('LlmNutritionResult.fromJson', () {
    test('parses valid complete JSON', () {
      final json = {
        'name': 'Cheerios',
        'brand': 'General Mills',
        'servingSizeG': 28.0,
        'caloriesPer100g': 357.0,
        'proteinPer100g': 10.7,
        'carbsPer100g': 75.0,
        'fatPer100g': 5.4,
        'fiberPer100g': 10.7,
        'sugarPer100g': 3.6,
        'saturatedFatPer100g': 0.7,
        'servingQuantity': 28.0,
        'servingUnit': 'g',
        'confidence': 'high',
      };

      final result = LlmNutritionResult.fromJson(json);

      expect(result.name, 'Cheerios');
      expect(result.brand, 'General Mills');
      expect(result.caloriesPer100g, 357.0);
      expect(result.proteinPer100g, 10.7);
      expect(result.carbsPer100g, 75.0);
      expect(result.fatPer100g, 5.4);
      expect(result.fiberPer100g, 10.7);
      expect(result.sugarPer100g, 3.6);
      expect(result.saturatedFatPer100g, 0.7);
      expect(result.servingSizeG, 28.0);
      expect(result.servingQuantity, 28.0);
      expect(result.servingUnit, 'g');
      expect(result.confidence, 'high');
      expect(result.hasError, false);
    });

    test('parses JSON with null optional fields', () {
      final json = {
        'name': 'Mystery Food',
        'caloriesPer100g': 200,
        'proteinPer100g': 10,
        'carbsPer100g': 30,
        'fatPer100g': 5,
      };

      final result = LlmNutritionResult.fromJson(json);

      expect(result.name, 'Mystery Food');
      expect(result.brand, isNull);
      expect(result.fiberPer100g, isNull);
      expect(result.sugarPer100g, isNull);
      expect(result.saturatedFatPer100g, isNull);
      expect(result.servingSizeG, isNull);
      expect(result.confidence, 'medium'); // default
      expect(result.hasError, false);
    });

    test('parses error response', () {
      final json = {'error': 'Label is too blurry to read'};

      final result = LlmNutritionResult.fromJson(json);

      expect(result.hasError, true);
      expect(result.error, 'Label is too blurry to read');
      expect(result.caloriesPer100g, 0);
    });

    test('handles integer values', () {
      final json = {
        'caloriesPer100g': 200,
        'proteinPer100g': 10,
        'carbsPer100g': 30,
        'fatPer100g': 5,
      };

      final result = LlmNutritionResult.fromJson(json);

      expect(result.caloriesPer100g, 200.0);
      expect(result.proteinPer100g, 10.0);
    });

    test('parses caloriesPerServing field', () {
      final json = {
        'name': 'Sandwich',
        'caloriesPer100g': 110,
        'caloriesPerServing': 206,
        'proteinPer100g': 8,
        'carbsPer100g': 15,
        'fatPer100g': 3,
        'servingUnit': 'pack',
      };

      final result = LlmNutritionResult.fromJson(json);

      expect(result.caloriesPerServing, 206.0);
      expect(result.servingUnit, 'pack');
    });

    test('caloriesPerServing defaults to null when absent', () {
      final json = {
        'caloriesPer100g': 100,
        'proteinPer100g': 5,
        'carbsPer100g': 20,
        'fatPer100g': 3,
      };

      final result = LlmNutritionResult.fromJson(json);

      expect(result.caloriesPerServing, isNull);
    });
  });

  group('LlmNutritionResult.parse', () {
    test('parses clean JSON string', () {
      const raw = '{"name":"Test","caloriesPer100g":100,"proteinPer100g":5,'
          '"carbsPer100g":20,"fatPer100g":3,"confidence":"high"}';

      final result = LlmNutritionResult.parse(raw);

      expect(result.name, 'Test');
      expect(result.caloriesPer100g, 100.0);
      expect(result.confidence, 'high');
    });

    test('strips markdown code fences', () {
      const raw = '```json\n{"name":"Test","caloriesPer100g":100,'
          '"proteinPer100g":5,"carbsPer100g":20,"fatPer100g":3}\n```';

      final result = LlmNutritionResult.parse(raw);

      expect(result.name, 'Test');
      expect(result.caloriesPer100g, 100.0);
    });

    test('strips plain code fences without json tag', () {
      const raw = '```\n{"name":"Test","caloriesPer100g":100,'
          '"proteinPer100g":5,"carbsPer100g":20,"fatPer100g":3}\n```';

      final result = LlmNutritionResult.parse(raw);

      expect(result.name, 'Test');
    });

    test('throws on malformed JSON', () {
      const raw = 'not json at all';

      expect(() => LlmNutritionResult.parse(raw), throwsFormatException);
    });
  });

  group('toMealEntity', () {
    test('converts to MealEntity with correct fields', () {
      final result = LlmNutritionResult(
        name: 'Oatmeal',
        brand: 'Quaker',
        servingSizeG: 40,
        caloriesPer100g: 375,
        proteinPer100g: 13,
        carbsPer100g: 65,
        fatPer100g: 7,
        fiberPer100g: 10,
        sugarPer100g: 1,
        saturatedFatPer100g: 1.5,
        servingQuantity: 40,
        servingUnit: 'g',
        confidence: 'high',
      );

      final meal = result.toMealEntity();

      expect(meal.name, 'Oatmeal');
      expect(meal.brands, 'Quaker');
      expect(meal.source, MealSourceEntity.llm);
      expect(meal.nutriments.energyKcal100, 375);
      expect(meal.nutriments.proteins100, 13);
      expect(meal.nutriments.carbohydrates100, 65);
      expect(meal.nutriments.fat100, 7);
      expect(meal.nutriments.fiber100, 10);
      expect(meal.nutriments.sugars100, 1);
      expect(meal.nutriments.saturatedFat100, 1.5);
      expect(meal.servingQuantity, 40);
      expect(meal.servingUnit, 'g');
      expect(meal.code, isNotNull);
    });

    test('handles null optional fields gracefully', () {
      final result = LlmNutritionResult(
        caloriesPer100g: 200,
        proteinPer100g: 10,
        carbsPer100g: 30,
        fatPer100g: 5,
      );

      final meal = result.toMealEntity();

      expect(meal.name, isNull);
      expect(meal.brands, isNull);
      expect(meal.source, MealSourceEntity.llm);
      expect(meal.nutriments.energyKcal100, 200);
    });
  });

  group('copyWith', () {
    test('copies with updated fields', () {
      final original = LlmNutritionResult(
        name: 'Test',
        caloriesPer100g: 100,
        proteinPer100g: 5,
        carbsPer100g: 20,
        fatPer100g: 3,
        confidence: 'low',
      );

      final updated = original.copyWith(
        name: 'Updated',
        caloriesPer100g: 200,
        confidence: 'high',
      );

      expect(updated.name, 'Updated');
      expect(updated.caloriesPer100g, 200);
      expect(updated.confidence, 'high');
      // Unchanged fields preserved
      expect(updated.proteinPer100g, 5);
      expect(updated.carbsPer100g, 20);
      expect(updated.fatPer100g, 3);
    });
  });
}
