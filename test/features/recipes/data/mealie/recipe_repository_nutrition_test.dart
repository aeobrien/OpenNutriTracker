import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';

/// Exercises the persistence path for Mealie-imported recipes against a real
/// in-memory SQLite database (no mocks/codegen).
void main() {
  late AppDatabase db;
  late RecipeRepository repo;

  setUp(() {
    db = AppDatabase.createInMemory();
    repo = RecipeRepository(db.recipeDao);
  });

  tearDown(() async {
    await db.close();
  });

  test('createRecipeWithNutrition keeps explicit per-serving nutrition and round-trips', () async {
    final created = await repo.createRecipeWithNutrition(
      name: 'Mealie Bolognese',
      servings: 6,
      kcalPerServing: 624,
      proteinPerServing: 35,
      carbsPerServing: 58,
      fatPerServing: 25,
      ingredients: const [
        RecipeIngredientEntity(id: '', recipeId: '', name: '500g beef mince', grams: 0),
        RecipeIngredientEntity(id: '', recipeId: '', name: '2 onions', grams: 0),
      ],
    );

    expect(created.servings, 6);
    expect(created.kcalPerServing, 624);
    expect(created.proteinPerServing, 35);
    expect(created.carbsPerServing, 58);
    expect(created.fatPerServing, 25);
    expect(created.ingredients.length, 2);
    expect(created.ingredients.first.name, '500g beef mince');

    final fetched = await repo.getRecipeById(created.id);
    expect(fetched, isNotNull);
    expect(fetched!.kcalPerServing, 624);
    expect(fetched.fatPerServing, 25);
  });

  test('the existing createRecipe recomputes from ingredients (would zero a Mealie import)', () async {
    final created = await repo.createRecipe(
      name: 'Recompute path',
      servings: 2,
      ingredients: const [
        // Mealie-style ingredient: a label but no per-100g macros.
        RecipeIngredientEntity(id: '', recipeId: '', name: 'macro-less ingredient', grams: 100),
      ],
    );

    // Confirms the problem createRecipeWithNutrition exists to avoid.
    expect(created.kcalPerServing, 0);
    expect(created.proteinPerServing, 0);
  });
}
