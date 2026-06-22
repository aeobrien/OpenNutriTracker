import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/features/recipes/data/dto/mealie/mealie_parse.dart';
import 'package:opennutritracker/features/recipes/data/dto/mealie/mealie_recipe_dto.dart';

/// Maps a Mealie recipe into FoodTracker's [RecipeEntity].
class MealieRecipeMapper {
  const MealieRecipeMapper._();

  /// Converts a Mealie recipe to a [RecipeEntity].
  ///
  /// Mealie stores ONE nutrition block per recipe and does no per-serving maths.
  /// By convention (recipe scrapers fill it from schema.org NutritionInformation)
  /// the block is PER SERVING, so [nutritionIsPerServing] defaults to true. When
  /// a recipe's numbers describe the whole recipe, pass false to divide them by
  /// the serving count.
  ///
  /// Only kcal/protein/carbs/fat are mapped — [RecipeEntity] has no fields for
  /// fibre/sugar/sodium. Ingredients are mapped for display only: Mealie does not
  /// expose per-ingredient macros, so their per-100g values are 0 and the recipe's
  /// nutrition comes from the recipe-level block, NOT from summing ingredients.
  ///
  /// NOTE on persistence: `RecipeRepository.createRecipe` recomputes per-serving
  /// nutrition from ingredient macros, which would zero out a Mealie-imported
  /// recipe. Persisting these needs a path that keeps the recipe-level nutrition
  /// (e.g. a `createRecipeWithNutrition` variant). See the integration guide.
  static RecipeEntity toRecipeEntity(
    MealieRecipeDto dto, {
    bool nutritionIsPerServing = true,
    DateTime? timestamp,
  }) {
    final ts = timestamp ?? DateTime.now();
    final servings = dto.recipeServings > 0 ? dto.recipeServings : 1.0;
    final nutrition = dto.nutrition;

    double perServing(String? raw) {
      final total = mealieToDouble(raw) ?? 0;
      if (total <= 0) return 0;
      return nutritionIsPerServing ? total : total / servings;
    }

    final ingredients = <RecipeIngredientEntity>[];
    for (var i = 0; i < dto.ingredients.length; i++) {
      final ing = dto.ingredients[i];
      ingredients.add(RecipeIngredientEntity(
        id: '',
        recipeId: dto.slug,
        name: ing.label,
        grams: 0, // Mealie quantity is in the ingredient's own unit, not grams.
        sortOrder: i,
      ));
    }

    return RecipeEntity(
      id: dto.slug,
      name: dto.name,
      servings: servings,
      createdAt: ts,
      updatedAt: ts,
      kcalPerServing: perServing(nutrition?.calories),
      proteinPerServing: perServing(nutrition?.proteinContent),
      carbsPerServing: perServing(nutrition?.carbohydrateContent),
      fatPerServing: perServing(nutrition?.fatContent),
      ingredients: ingredients,
    );
  }
}
