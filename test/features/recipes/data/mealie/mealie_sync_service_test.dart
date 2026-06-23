import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/features/recipes/data/data_source/mealie_data_source.dart';
import 'package:opennutritracker/features/recipes/data/mealie_sync_service.dart';

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

  RecipeEntity entity(String slug, {double kcal = 100, String name = 'R'}) => RecipeEntity(
        id: slug,
        name: name,
        servings: 2,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
        kcalPerServing: kcal,
        proteinPerServing: 5,
        carbsPerServing: 10,
        fatPerServing: 2,
      );

  group('upsertMirroredRecipe', () {
    test('inserts when new, updates in place when the slug already exists', () async {
      await repo.upsertMirroredRecipe(entity('soup', kcal: 100, name: 'Soup'));
      var all = await repo.getAllRecipes();
      expect(all.length, 1);
      expect(all.first.kcalPerServing, 100);

      // Same slug, changed nutrition + name -> update in place, not a duplicate.
      await repo.upsertMirroredRecipe(entity('soup', kcal: 250, name: 'Soup v2'));
      all = await repo.getAllRecipes();
      expect(all.length, 1);
      expect(all.first.id, 'soup');
      expect(all.first.name, 'Soup v2');
      expect(all.first.kcalPerServing, 250);
    });
  });

  group('MealieSyncService.syncAllRecipes', () {
    test('mirrors all Mealie recipes into the local store (one-way)', () async {
      final client = MockClient((req) async {
        switch (req.url.path) {
          case '/api/recipes':
            return http.Response(
                jsonEncode({
                  'page': 1,
                  'perPage': 100,
                  'total': 2,
                  'totalPages': 1,
                  'items': [
                    {'id': '1', 'name': 'Soup', 'slug': 'soup', 'recipeServings': 2},
                    {'id': '2', 'name': 'Stew', 'slug': 'stew', 'recipeServings': 4},
                  ],
                }),
                200);
          case '/api/recipes/soup':
            return http.Response(
                jsonEncode({
                  'id': '1',
                  'name': 'Soup',
                  'slug': 'soup',
                  'recipeServings': 2,
                  'nutrition': {
                    'calories': '120',
                    'proteinContent': '6',
                    'carbohydrateContent': '12',
                    'fatContent': '3'
                  },
                  'recipeIngredient': const [],
                }),
                200);
          case '/api/recipes/stew':
            return http.Response(
                jsonEncode({
                  'id': '2',
                  'name': 'Stew',
                  'slug': 'stew',
                  'recipeServings': 4,
                  'nutrition': {'calories': '300'},
                  'recipeIngredient': const [],
                }),
                200);
          default:
            return http.Response('not found', 404);
        }
      });

      final ds = MealieDataSource(baseUrl: 'http://h:9000', token: 'x', client: client);
      final result = await MealieSyncService(ds, repo).syncAllRecipes();

      expect(result.synced, 2);
      expect(result.failed, 0);
      expect(result.total, 2);

      final all = await repo.getAllRecipes();
      expect(all.length, 2);
      final soup = await repo.getRecipeById('soup');
      expect(soup!.kcalPerServing, 120);
      expect(soup.proteinPerServing, 6);
    });

    test('a single failing recipe is skipped, not fatal', () async {
      final client = MockClient((req) async {
        switch (req.url.path) {
          case '/api/recipes':
            return http.Response(
                jsonEncode({
                  'page': 1,
                  'perPage': 100,
                  'total': 2,
                  'totalPages': 1,
                  'items': [
                    {'id': '1', 'slug': 'good', 'recipeServings': 1},
                    {'id': '2', 'slug': 'bad', 'recipeServings': 1},
                  ],
                }),
                200);
          case '/api/recipes/good':
            return http.Response(
                jsonEncode({
                  'id': '1',
                  'name': 'Good',
                  'slug': 'good',
                  'recipeServings': 1,
                  'nutrition': {'calories': '50'},
                  'recipeIngredient': const [],
                }),
                200);
          default:
            return http.Response('boom', 500); // 'bad' slug fails
        }
      });

      final ds = MealieDataSource(baseUrl: 'http://h:9000', token: 'x', client: client);
      final result = await MealieSyncService(ds, repo).syncAllRecipes();

      expect(result.synced, 1);
      expect(result.failed, 1);
      final all = await repo.getAllRecipes();
      expect(all.length, 1);
      expect(all.first.id, 'good');
    });
  });
}
