import 'dart:convert';

class LlmRecipeResult {
  final String recipeName;
  final double servings;
  final List<LlmIngredientResult> ingredients;
  final String? error;

  LlmRecipeResult({
    required this.recipeName,
    required this.servings,
    required this.ingredients,
    this.error,
  });

  bool get hasError => error != null;

  static LlmRecipeResult parse(String rawText) {
    try {
      // Strip markdown fences if present
      var text = rawText.trim();
      if (text.startsWith('```')) {
        final firstNewline = text.indexOf('\n');
        text = text.substring(firstNewline + 1);
        if (text.endsWith('```')) {
          text = text.substring(0, text.length - 3).trim();
        }
      }

      final json = jsonDecode(text) as Map<String, dynamic>;
      final recipeName = json['recipeName'] as String? ?? 'Untitled Recipe';
      final servings = (json['servings'] as num?)?.toDouble() ?? 4.0;
      final ingredientsJson = json['ingredients'] as List<dynamic>? ?? [];

      final ingredients = ingredientsJson
          .map((i) => LlmIngredientResult(
                name: i['name'] as String? ?? '',
                originalText: i['originalText'] as String? ?? '',
                grams: (i['grams'] as num?)?.toDouble() ?? 0,
                confidence: i['confidence'] as String? ?? 'low',
              ))
          .toList();

      return LlmRecipeResult(
        recipeName: recipeName,
        servings: servings,
        ingredients: ingredients,
      );
    } catch (e) {
      return LlmRecipeResult(
        recipeName: 'Untitled Recipe',
        servings: 4.0,
        ingredients: [],
        error: 'Failed to parse LLM response: $e',
      );
    }
  }
}

class LlmIngredientResult {
  final String name;
  final String originalText;
  final double grams;
  final String confidence;

  LlmIngredientResult({
    required this.name,
    required this.originalText,
    required this.grams,
    required this.confidence,
  });
}
