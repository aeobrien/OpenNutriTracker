import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/recipes.dart';
import 'package:opennutritracker/core/data/drift/tables/recipe_ingredients.dart';
import 'package:opennutritracker/core/utils/calc/recipe_calc.dart' as calc;

part 'recipe_dao.g.dart';

@DriftAccessor(tables: [Recipes, RecipeIngredients])
class RecipeDao extends DatabaseAccessor<AppDatabase>
    with _$RecipeDaoMixin {
  RecipeDao(super.db);

  Future<void> insertRecipe(RecipesCompanion entry) async {
    await into(recipes).insert(entry);
  }

  Future<void> updateRecipe(String id, RecipesCompanion entry) async {
    await (update(recipes)..where((t) => t.id.equals(id))).write(entry);
  }

  Future<void> deleteRecipe(String id) async {
    await deleteIngredientsByRecipeId(id);
    await (delete(recipes)..where((t) => t.id.equals(id))).go();
  }

  Future<Recipe?> getById(String id) async {
    return (select(recipes)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<Recipe>> getAll() async {
    return (select(recipes)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<List<Recipe>> getFavourites() async {
    return (select(recipes)
          ..where((t) => t.favourite.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)]))
        .get();
  }

  Future<List<Recipe>> getRecentlyUsed({int limit = 20}) async {
    return (select(recipes)
          ..where((t) => t.lastUsedAt.isNotNull())
          ..orderBy([(t) => OrderingTerm.desc(t.lastUsedAt)])
          ..limit(limit))
        .get();
  }

  Future<List<Recipe>> searchByName(String query) async {
    final pattern = '%${query.toLowerCase()}%';
    return (select(recipes)
          ..where((t) => t.name.lower().like(pattern))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  Future<void> toggleFavourite(String id, bool value) async {
    await (update(recipes)..where((t) => t.id.equals(id))).write(
      RecipesCompanion(favourite: Value(value)),
    );
  }

  Future<void> updateLastUsed(String id, int timestamp) async {
    await (update(recipes)..where((t) => t.id.equals(id))).write(
      RecipesCompanion(lastUsedAt: Value(timestamp)),
    );
  }

  // Ingredients

  Future<void> insertIngredient(RecipeIngredientsCompanion entry) async {
    await into(recipeIngredients).insert(entry);
  }

  Future<void> deleteIngredientsByRecipeId(String recipeId) async {
    await (delete(recipeIngredients)
          ..where((t) => t.recipeId.equals(recipeId)))
        .go();
  }

  Future<List<RecipeIngredient>> getIngredientsByRecipeId(
      String recipeId) async {
    return (select(recipeIngredients)
          ..where((t) => t.recipeId.equals(recipeId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<void> replaceIngredients(
      String recipeId, List<RecipeIngredientsCompanion> ingredients) async {
    await transaction(() async {
      await deleteIngredientsByRecipeId(recipeId);
      for (final ingredient in ingredients) {
        await into(recipeIngredients).insert(ingredient);
      }
    });
  }

  Future<void> recomputeNutrition(String recipeId) async {
    final recipe = await getById(recipeId);
    if (recipe == null) return;

    final ingredients = await getIngredientsByRecipeId(recipeId);
    final calcIngredients = ingredients
        .map((i) => calc.RecipeIngredient(
              kcalPer100g: i.kcalPer100,
              proteinPer100g: i.proteinPer100,
              carbsPer100g: i.carbsPer100,
              fatPer100g: i.fatPer100,
              grams: i.grams,
            ))
        .toList();

    final perServing =
        calc.RecipeCalc.calculatePerServing(calcIngredients, recipe.servings);

    await (update(recipes)..where((t) => t.id.equals(recipeId))).write(
      RecipesCompanion(
        kcalPerServing: Value(perServing.kcal),
        proteinPerServing: Value(perServing.protein),
        carbsPerServing: Value(perServing.carbs),
        fatPerServing: Value(perServing.fat),
      ),
    );
  }
}
