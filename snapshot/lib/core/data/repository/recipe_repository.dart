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
