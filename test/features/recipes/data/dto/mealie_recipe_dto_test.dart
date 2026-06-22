import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/recipes/data/dto/mealie/mealie_recipe_dto.dart';

void main() {
  group('MealieRecipeDto.fromJson', () {
    test('parses a full recipe with nutrition and ingredients', () {
      final json = <String, dynamic>{
        'id': 'abc',
        'name': 'Tomato Soup',
        'slug': 'tomato-soup',
        'recipeServings': 4,
        'nutrition': {
          'calories': '120',
          'proteinContent': '5',
          'carbohydrateContent': '18',
          'fatContent': '3',
          'sodiumContent': '400',
        },
        'recipeIngredient': [
          {
            'quantity': 2,
            'unit': {'name': 'cup'},
            'food': {'name': 'tomato'},
            'note': 'chopped',
            'display': '2 cup tomato, chopped',
          },
          {
            'quantity': 1,
            'food': {'name': 'onion'},
            'display': '',
          },
        ],
      };

      final r = MealieRecipeDto.fromJson(json);
      expect(r.id, 'abc');
      expect(r.name, 'Tomato Soup');
      expect(r.slug, 'tomato-soup');
      expect(r.recipeServings, 4);
      expect(r.nutrition!.calories, '120');
      expect(r.nutrition!.sodiumContent, '400');
      expect(r.ingredients.length, 2);
      expect(r.ingredients[0].label, '2 cup tomato, chopped');
      // display empty -> assembled from quantity + food name
      expect(r.ingredients[1].label, '1 onion');
    });

    test('falls back to slug when name missing; tolerates absent nutrition/ingredients', () {
      final r = MealieRecipeDto.fromJson({'id': '1', 'slug': 'x', 'recipeServings': 1});
      expect(r.name, 'x');
      expect(r.nutrition, isNull);
      expect(r.ingredients, isEmpty);
    });

    test('handles recipeServings as string or num', () {
      expect(MealieRecipeDto.fromJson({'slug': 'a', 'recipeServings': '3'}).recipeServings, 3);
      expect(MealieRecipeDto.fromJson({'slug': 'a', 'recipeServings': 2.5}).recipeServings, 2.5);
    });
  });

  group('MealieRecipePage.fromJson', () {
    test('parses paginated items with name fallback', () {
      final r = MealieRecipePage.fromJson({
        'page': 1,
        'perPage': 50,
        'total': 2,
        'totalPages': 1,
        'items': [
          {'id': '1', 'name': 'Apple Pie', 'slug': 'apple-pie', 'recipeServings': 8},
          {'id': '2', 'slug': 'banana-bread'},
        ],
      });
      expect(r.total, 2);
      expect(r.items.length, 2);
      expect(r.items[0].name, 'Apple Pie');
      expect(r.items[0].recipeServings, 8);
      expect(r.items[1].name, 'banana-bread'); // name fallback to slug
    });
  });
}
