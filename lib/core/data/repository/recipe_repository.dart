import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/recipe_dao.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:uuid/uuid.dart';

class RecipeRepository {
  final RecipeDao _recipeDao;
  final _log = Logger('RecipeRepository');
  static const _uuid = Uuid();

  RecipeRepository(this._recipeDao);

  Future<RecipeEntity> createRecipe({
    required String name,
    required double servings,
    required List<RecipeIngredientEntity> ingredients,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final recipeId = _uuid.v4();
    _log.fine('Creating recipe: $name (id: $recipeId)');

    await _recipeDao.insertRecipe(RecipesCompanion(
      id: Value(recipeId),
      name: Value(name),
      servings: Value(servings),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));

    final ingredientCompanions = <RecipeIngredientsCompanion>[];
    for (var i = 0; i < ingredients.length; i++) {
      final ing = ingredients[i];
      ingredientCompanions.add(RecipeIngredientsCompanion(
        id: Value(ing.id.isEmpty ? _uuid.v4() : ing.id),
        recipeId: Value(recipeId),
        foodItemId: Value(ing.foodItemId),
        name: Value(ing.name),
        grams: Value(ing.grams),
        kcalPer100: Value(ing.kcalPer100),
        proteinPer100: Value(ing.proteinPer100),
        carbsPer100: Value(ing.carbsPer100),
        fatPer100: Value(ing.fatPer100),
        sortOrder: Value(i),
      ));
    }

    await _recipeDao.replaceIngredients(recipeId, ingredientCompanions);
    await _recipeDao.recomputeNutrition(recipeId);

    return (await getRecipeById(recipeId))!;
  }

  /// Creates a recipe with **explicit** per-serving nutrition, WITHOUT recomputing
  /// from ingredients. Use for imported recipes (e.g. from Mealie) whose macros are
  /// supplied at the recipe level and whose ingredients carry no per-100g data —
  /// [createRecipe]'s `recomputeNutrition` would otherwise zero such a recipe out.
  Future<RecipeEntity> createRecipeWithNutrition({
    required String name,
    required double servings,
    required double kcalPerServing,
    required double proteinPerServing,
    required double carbsPerServing,
    required double fatPerServing,
    List<RecipeIngredientEntity> ingredients = const [],
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final recipeId = _uuid.v4();
    _log.fine('Creating recipe with explicit nutrition: $name (id: $recipeId)');

    await _recipeDao.insertRecipe(RecipesCompanion(
      id: Value(recipeId),
      name: Value(name),
      servings: Value(servings),
      createdAt: Value(now),
      updatedAt: Value(now),
      kcalPerServing: Value(kcalPerServing),
      proteinPerServing: Value(proteinPerServing),
      carbsPerServing: Value(carbsPerServing),
      fatPerServing: Value(fatPerServing),
    ));

    final ingredientCompanions = <RecipeIngredientsCompanion>[];
    for (var i = 0; i < ingredients.length; i++) {
      final ing = ingredients[i];
      ingredientCompanions.add(RecipeIngredientsCompanion(
        id: Value(ing.id.isEmpty ? _uuid.v4() : ing.id),
        recipeId: Value(recipeId),
        foodItemId: Value(ing.foodItemId),
        name: Value(ing.name),
        grams: Value(ing.grams),
        kcalPer100: Value(ing.kcalPer100),
        proteinPer100: Value(ing.proteinPer100),
        carbsPer100: Value(ing.carbsPer100),
        fatPer100: Value(ing.fatPer100),
        sortOrder: Value(i),
      ));
    }
    // Deliberately NOT calling recomputeNutrition — it would overwrite the explicit
    // per-serving values above with ingredient-derived totals (zero, for Mealie).
    await _recipeDao.replaceIngredients(recipeId, ingredientCompanions);

    return (await getRecipeById(recipeId))!;
  }

  /// Inserts-or-updates a recipe mirrored one-way from Mealie, keyed on the
  /// recipe's [RecipeEntity.id] (which the Mealie mapper sets to the Mealie slug —
  /// a stable identifier). Used by the one-way sync: Mealie is the source of truth,
  /// FoodTracker holds a read-only mirror. Preserves the explicit per-serving
  /// nutrition (no recompute) and replaces the ingredient list each time.
  Future<RecipeEntity> upsertMirroredRecipe(RecipeEntity recipe) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = await _recipeDao.getById(recipe.id);

    if (existing == null) {
      await _recipeDao.insertRecipe(RecipesCompanion(
        id: Value(recipe.id),
        name: Value(recipe.name),
        servings: Value(recipe.servings),
        createdAt: Value(now),
        updatedAt: Value(now),
        kcalPerServing: Value(recipe.kcalPerServing),
        proteinPerServing: Value(recipe.proteinPerServing),
        carbsPerServing: Value(recipe.carbsPerServing),
        fatPerServing: Value(recipe.fatPerServing),
      ));
    } else {
      await _recipeDao.updateRecipe(
        recipe.id,
        RecipesCompanion(
          name: Value(recipe.name),
          servings: Value(recipe.servings),
          updatedAt: Value(now),
          kcalPerServing: Value(recipe.kcalPerServing),
          proteinPerServing: Value(recipe.proteinPerServing),
          carbsPerServing: Value(recipe.carbsPerServing),
          fatPerServing: Value(recipe.fatPerServing),
        ),
      );
    }

    final ingredientCompanions = <RecipeIngredientsCompanion>[];
    for (var i = 0; i < recipe.ingredients.length; i++) {
      final ing = recipe.ingredients[i];
      ingredientCompanions.add(RecipeIngredientsCompanion(
        id: Value(ing.id.isEmpty ? _uuid.v4() : ing.id),
        recipeId: Value(recipe.id),
        foodItemId: Value(ing.foodItemId),
        name: Value(ing.name),
        grams: Value(ing.grams),
        kcalPer100: Value(ing.kcalPer100),
        proteinPer100: Value(ing.proteinPer100),
        carbsPer100: Value(ing.carbsPer100),
        fatPer100: Value(ing.fatPer100),
        sortOrder: Value(i),
      ));
    }
    await _recipeDao.replaceIngredients(recipe.id, ingredientCompanions);

    return (await getRecipeById(recipe.id))!;
  }

  Future<RecipeEntity?> getRecipeById(String id) async {
    final recipe = await _recipeDao.getById(id);
    if (recipe == null) return null;

    final ingredientRows = await _recipeDao.getIngredientsByRecipeId(id);
    final ingredients =
        ingredientRows.map((r) => RecipeIngredientEntity.fromDbRow(r)).toList();

    return RecipeEntity.fromDbRow(recipe, ingredients);
  }

  Future<List<RecipeEntity>> getAllRecipes() async {
    final recipes = await _recipeDao.getAll();
    return _mapRecipesWithIngredients(recipes);
  }

  Future<List<RecipeEntity>> getFavouriteRecipes() async {
    final recipes = await _recipeDao.getFavourites();
    return _mapRecipesWithIngredients(recipes);
  }

  Future<List<RecipeEntity>> getRecentRecipes() async {
    final recipes = await _recipeDao.getRecentlyUsed();
    return _mapRecipesWithIngredients(recipes);
  }

  Future<RecipeEntity> updateRecipe({
    required String id,
    required String name,
    required double servings,
    required List<RecipeIngredientEntity> ingredients,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    _log.fine('Updating recipe: $id');

    await _recipeDao.updateRecipe(id, RecipesCompanion(
      name: Value(name),
      servings: Value(servings),
      updatedAt: Value(now),
    ));

    final ingredientCompanions = <RecipeIngredientsCompanion>[];
    for (var i = 0; i < ingredients.length; i++) {
      final ing = ingredients[i];
      ingredientCompanions.add(RecipeIngredientsCompanion(
        id: Value(ing.id.isEmpty ? _uuid.v4() : ing.id),
        recipeId: Value(id),
        foodItemId: Value(ing.foodItemId),
        name: Value(ing.name),
        grams: Value(ing.grams),
        kcalPer100: Value(ing.kcalPer100),
        proteinPer100: Value(ing.proteinPer100),
        carbsPer100: Value(ing.carbsPer100),
        fatPer100: Value(ing.fatPer100),
        sortOrder: Value(i),
      ));
    }

    await _recipeDao.replaceIngredients(id, ingredientCompanions);
    await _recipeDao.recomputeNutrition(id);

    return (await getRecipeById(id))!;
  }

  Future<void> deleteRecipe(String id) async {
    _log.fine('Deleting recipe: $id');
    await _recipeDao.deleteRecipe(id);
  }

  Future<void> toggleFavourite(String id, bool value) async {
    await _recipeDao.toggleFavourite(id, value);
  }

  Future<void> updateLastUsed(String id) async {
    await _recipeDao.updateLastUsed(id, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<RecipeEntity>> searchRecipes(String query) async {
    final recipes = await _recipeDao.searchByName(query);
    return _mapRecipesWithIngredients(recipes);
  }

  Future<List<RecipeEntity>> _mapRecipesWithIngredients(
      List<Recipe> recipes) async {
    final result = <RecipeEntity>[];
    for (final recipe in recipes) {
      final ingredientRows =
          await _recipeDao.getIngredientsByRecipeId(recipe.id);
      final ingredients = ingredientRows
          .map((r) => RecipeIngredientEntity.fromDbRow(r))
          .toList();
      result.add(RecipeEntity.fromDbRow(recipe, ingredients));
    }
    return result;
  }
}
