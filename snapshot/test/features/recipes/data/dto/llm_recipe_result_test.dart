import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/recipes/data/dto/llm_recipe_result.dart';

void main() {
  group('LlmRecipeResult.parse', () {
    test('parses valid JSON', () {
      const json = '''
{
  "recipeName": "Banana Bread",
  "servings": 8,
  "ingredients": [
    {"name": "banana", "originalText": "3 ripe bananas", "grams": 300, "confidence": "high"},
    {"name": "flour", "originalText": "2 cups flour", "grams": 240, "confidence": "medium"}
  ]
}
''';
      final result = LlmRecipeResult.parse(json);
      expect(result.hasError, isFalse);
      expect(result.recipeName, 'Banana Bread');
      expect(result.servings, 8);
      expect(result.ingredients.length, 2);
      expect(result.ingredients[0].name, 'banana');
      expect(result.ingredients[0].grams, 300);
      expect(result.ingredients[1].confidence, 'medium');
    });

    test('strips markdown fences', () {
      const json = '''```json
{"recipeName": "Test", "servings": 2, "ingredients": []}
```''';
      final result = LlmRecipeResult.parse(json);
      expect(result.hasError, isFalse);
      expect(result.recipeName, 'Test');
      expect(result.servings, 2);
    });

    test('returns error for invalid JSON', () {
      final result = LlmRecipeResult.parse('not valid json');
      expect(result.hasError, isTrue);
      expect(result.recipeName, 'Untitled Recipe');
      expect(result.ingredients, isEmpty);
    });

    test('handles missing fields with defaults', () {
      final result = LlmRecipeResult.parse('{}');
      expect(result.hasError, isFalse);
      expect(result.recipeName, 'Untitled Recipe');
      expect(result.servings, 4.0);
      expect(result.ingredients, isEmpty);
    });

    test('handles integer servings', () {
      final result = LlmRecipeResult.parse(
          '{"recipeName": "X", "servings": 6, "ingredients": []}');
      expect(result.servings, 6.0);
    });
  });
}
