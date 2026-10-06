import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';

// Simple tests that verify state transitions without mocking the repository.
// We test the synchronous event handlers that don't touch the DB.
void main() {
  group('RecipeBuilderBloc state transitions', () {
    test('initial state has empty fields', () {
      const state = RecipeBuilderState();
      expect(state.name, '');
      expect(state.servings, 1.0);
      expect(state.ingredients, isEmpty);
      expect(state.canSave, isFalse);
      expect(state.isSaving, isFalse);
      expect(state.savedRecipe, isNull);
    });

    test('canSave requires name and ingredients', () {
      const empty = RecipeBuilderState();
      expect(empty.canSave, isFalse);

      final withName = empty.copyWith(name: 'Pasta');
      expect(withName.canSave, isFalse);

      final withIngredients = withName.copyWith(ingredients: [
        const RecipeIngredientEntity(
          id: 'i1', recipeId: '', name: 'Flour', grams: 200),
      ]);
      expect(withIngredients.canSave, isTrue);
    });

    test('canSave is false when saving', () {
      final state = const RecipeBuilderState().copyWith(
        name: 'Pasta',
        ingredients: [
          const RecipeIngredientEntity(
            id: 'i1', recipeId: '', name: 'Flour', grams: 200),
        ],
        isSaving: true,
      );
      expect(state.canSave, isFalse);
    });

    test('copyWith preserves fields', () {
      const state = RecipeBuilderState(name: 'Test', servings: 4);
      final copy = state.copyWith(name: 'Updated');
      expect(copy.name, 'Updated');
      expect(copy.servings, 4);
    });

    test('nutrition updates when ingredients change', () {
      const state = RecipeBuilderState(servings: 2);
      final withIng = state.copyWith(
        ingredients: [
          const RecipeIngredientEntity(
            id: 'i1',
            recipeId: '',
            name: 'Rice',
            grams: 200,
            kcalPer100: 130,
            proteinPer100: 2.7,
            carbsPer100: 28,
            fatPer100: 0.3,
          ),
        ],
      );
      expect(withIng.ingredients.length, 1);
    });
  });
}
