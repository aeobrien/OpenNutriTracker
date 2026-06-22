import 'package:opennutritracker/features/recipes/data/dto/mealie/mealie_nutrition_dto.dart';
import 'package:opennutritracker/features/recipes/data/dto/mealie/mealie_parse.dart';

/// A single ingredient line from a Mealie recipe.
///
/// Mealie ingredients carry display text and a quantity in their own unit, but
/// NO per-ingredient nutrition. They are useful for showing the user what's in a
/// recipe; the recipe's macros come from the recipe-level [MealieNutritionDto].
class MealieIngredientDto {
  final double? quantity;
  final String? unitName;
  final String? foodName;
  final String? note;
  final String? display;
  final String? originalText;

  const MealieIngredientDto({
    this.quantity,
    this.unitName,
    this.foodName,
    this.note,
    this.display,
    this.originalText,
  });

  factory MealieIngredientDto.fromJson(Map<String, dynamic> json) {
    final unit = json['unit'];
    final food = json['food'];
    return MealieIngredientDto(
      quantity: mealieToDouble(json['quantity']),
      unitName: unit is Map ? unit['name'] as String? : null,
      foodName: food is Map ? food['name'] as String? : null,
      note: json['note'] as String?,
      display: json['display'] as String?,
      originalText: json['originalText'] as String?,
    );
  }

  /// The best human-readable label for this ingredient, preferring Mealie's own
  /// computed `display` string and falling back to assembling one.
  String get label {
    final d = display?.trim();
    if (d != null && d.isNotEmpty) return d;

    final parts = <String>[
      if (quantity != null && quantity! > 0) _formatQuantity(quantity!),
      if (unitName != null && unitName!.trim().isNotEmpty) unitName!.trim(),
      if (foodName != null && foodName!.trim().isNotEmpty)
        foodName!.trim()
      else if (note != null && note!.trim().isNotEmpty)
        note!.trim(),
    ];
    final assembled = parts.join(' ').trim();
    if (assembled.isNotEmpty) return assembled;

    final n = note?.trim();
    if (n != null && n.isNotEmpty) return n;
    return originalText?.trim() ?? '';
  }

  static String _formatQuantity(double q) {
    return q == q.roundToDouble() ? q.toInt().toString() : q.toString();
  }
}

/// A recipe summary as returned by the list endpoint (`GET /api/recipes`).
class MealieRecipeSummaryDto {
  final String id;
  final String name;
  final String slug;
  final double recipeServings;

  const MealieRecipeSummaryDto({
    required this.id,
    required this.name,
    required this.slug,
    this.recipeServings = 0,
  });

  factory MealieRecipeSummaryDto.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
    final name = (json['name'] as String?)?.trim();
    return MealieRecipeSummaryDto(
      id: json['id']?.toString() ?? '',
      name: (name != null && name.isNotEmpty) ? name : slug,
      slug: slug,
      recipeServings: mealieToDouble(json['recipeServings']) ?? 0,
    );
  }
}

/// A full recipe as returned by the detail endpoint (`GET /api/recipes/{slug}`),
/// including the ingredient list and nutrition block.
class MealieRecipeDto {
  final String id;
  final String name;
  final String slug;
  final double recipeServings;
  final MealieNutritionDto? nutrition;
  final List<MealieIngredientDto> ingredients;

  const MealieRecipeDto({
    required this.id,
    required this.name,
    required this.slug,
    this.recipeServings = 0,
    this.nutrition,
    this.ingredients = const [],
  });

  factory MealieRecipeDto.fromJson(Map<String, dynamic> json) {
    final slug = json['slug']?.toString() ?? '';
    final name = (json['name'] as String?)?.trim();
    final rawIngredients = (json['recipeIngredient'] as List?) ?? const [];
    final nutritionJson = json['nutrition'];
    return MealieRecipeDto(
      id: json['id']?.toString() ?? '',
      name: (name != null && name.isNotEmpty) ? name : (slug.isNotEmpty ? slug : 'Untitled recipe'),
      slug: slug,
      recipeServings: mealieToDouble(json['recipeServings']) ?? 0,
      nutrition: nutritionJson is Map<String, dynamic>
          ? MealieNutritionDto.fromJson(nutritionJson)
          : null,
      ingredients: rawIngredients
          .whereType<Map<String, dynamic>>()
          .map(MealieIngredientDto.fromJson)
          .toList(),
    );
  }
}

/// One page of recipe summaries from Mealie's paginated list endpoint.
class MealieRecipePage {
  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  final List<MealieRecipeSummaryDto> items;

  const MealieRecipePage({
    required this.page,
    required this.perPage,
    required this.total,
    required this.totalPages,
    required this.items,
  });

  factory MealieRecipePage.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['items'] as List?) ?? const [];
    return MealieRecipePage(
      page: (json['page'] as num?)?.toInt() ?? 1,
      perPage: (json['perPage'] as num?)?.toInt() ?? rawItems.length,
      total: (json['total'] as num?)?.toInt() ?? rawItems.length,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 1,
      items: rawItems
          .whereType<Map<String, dynamic>>()
          .map(MealieRecipeSummaryDto.fromJson)
          .toList(),
    );
  }
}
