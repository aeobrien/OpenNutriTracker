import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/recipes/data/data_source/mealie_data_source.dart';

void main() {
  group('MealieDataSource', () {
    test('fetchRecipe parses response, strips trailing slash, sends bearer token', () async {
      late http.Request captured;
      final client = MockClient((req) async {
        captured = req;
        return http.Response(
          jsonEncode({
            'id': '1',
            'name': 'Soup',
            'slug': 'soup',
            'recipeServings': 2,
            'nutrition': {'calories': '100'},
            'recipeIngredient': const [],
          }),
          200,
        );
      });

      final ds = MealieDataSource(
        baseUrl: 'http://host:9000/',
        token: 'tok',
        client: client,
      );
      final recipe = await ds.fetchRecipe('soup');

      expect(recipe.name, 'Soup');
      expect(recipe.nutrition!.calories, '100');
      expect(captured.headers['Authorization'], 'Bearer tok');
      expect(captured.url.toString(), 'http://host:9000/api/recipes/soup');
    });

    test('401 throws MealieAuthException', () {
      final ds = MealieDataSource(
        baseUrl: 'http://h:9000',
        token: 'x',
        client: MockClient((_) async => http.Response('nope', 401)),
      );
      expect(() => ds.fetchRecipe('s'), throwsA(isA<MealieAuthException>()));
    });

    test('404 throws MealieNotFoundException carrying the slug', () {
      final ds = MealieDataSource(
        baseUrl: 'http://h:9000',
        token: 'x',
        client: MockClient((_) async => http.Response('nope', 404)),
      );
      expect(
        () => ds.fetchRecipe('missing'),
        throwsA(isA<MealieNotFoundException>()
            .having((e) => e.slug, 'slug', 'missing')),
      );
    });

    test('fetchRecipes builds the query and parses the page', () async {
      late Uri url;
      final client = MockClient((req) async {
        url = req.url;
        return http.Response(
          jsonEncode({
            'page': 1,
            'perPage': 50,
            'total': 1,
            'totalPages': 1,
            'items': [
              {'id': '1', 'name': 'Soup', 'slug': 'soup', 'recipeServings': 2}
            ],
          }),
          200,
        );
      });

      final ds = MealieDataSource(baseUrl: 'http://h:9000', token: 'x', client: client);
      final page = await ds.fetchRecipes(search: 'so');

      expect(page.items.single.slug, 'soup');
      expect(page.total, 1);
      expect(url.path, '/api/recipes');
      expect(url.queryParameters['search'], 'so');
      expect(url.queryParameters['perPage'], '50');
    });

    test('network failure surfaces as MealieException', () {
      final ds = MealieDataSource(
        baseUrl: 'http://h:9000',
        token: 'x',
        client: MockClient((_) async => throw Exception('boom')),
      );
      expect(() => ds.fetchRecipe('s'), throwsA(isA<MealieException>()));
    });
  });
}
