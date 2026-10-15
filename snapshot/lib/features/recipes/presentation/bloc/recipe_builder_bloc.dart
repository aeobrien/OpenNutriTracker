import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/utils/calc/recipe_calc.dart';

// Events
abstract class RecipeBuilderEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class InitBuilderEvent extends RecipeBuilderEvent {
  final RecipeEntity? existing;
  InitBuilderEvent({this.existing});
  @override
  List<Object?> get props => [existing];
}

class UpdateNameEvent extends RecipeBuilderEvent {
  final String name;
  UpdateNameEvent(this.name);
  @override
  List<Object?> get props => [name];
}

class UpdateServingsEvent extends RecipeBuilderEvent {
  final double servings;
  UpdateServingsEvent(this.servings);
  @override
  List<Object?> get props => [servings];
}

class AddIngredientEvent extends RecipeBuilderEvent {
  final RecipeIngredientEntity ingredient;
  AddIngredientEvent(this.ingredient);
  @override
  List<Object?> get props => [ingredient];
}

class RemoveIngredientEvent extends RecipeBuilderEvent {
  final int index;
  RemoveIngredientEvent(this.index);
  @override
  List<Object?> get props => [index];
}

class UpdateIngredientGramsEvent extends RecipeBuilderEvent {
  final int index;
  final double grams;
  UpdateIngredientGramsEvent(this.index, this.grams);
  @override
  List<Object?> get props => [index, grams];
}

class SaveRecipeEvent extends RecipeBuilderEvent {}

// State
class RecipeBuilderState extends Equatable {
  final String? existingId;
  final String name;
  final double servings;
  final List<RecipeIngredientEntity> ingredients;
  final NutritionValues perServingNutrition;
  final bool isSaving;
  final RecipeEntity? savedRecipe;
  final String? error;

  const RecipeBuilderState({
    this.existingId,
    this.name = '',
    this.servings = 1.0,
    this.ingredients = const [],
    this.perServingNutrition = const NutritionValues(
        kcal: 0, protein: 0, carbs: 0, fat: 0),
    this.isSaving = false,
    this.savedRecipe,
    this.error,
  });

  RecipeBuilderState copyWith({
    String? existingId,
    String? name,
    double? servings,
    List<RecipeIngredientEntity>? ingredients,
    NutritionValues? perServingNutrition,
    bool? isSaving,
    RecipeEntity? savedRecipe,
    String? error,
  }) {
    return RecipeBuilderState(
      existingId: existingId ?? this.existingId,
      name: name ?? this.name,
      servings: servings ?? this.servings,
      ingredients: ingredients ?? this.ingredients,
      perServingNutrition: perServingNutrition ?? this.perServingNutrition,
      isSaving: isSaving ?? this.isSaving,
      savedRecipe: savedRecipe ?? this.savedRecipe,
      error: error,
    );
  }

  bool get canSave => name.trim().isNotEmpty && ingredients.isNotEmpty && !isSaving;

  @override
  List<Object?> get props => [existingId, name, servings, ingredients,
      perServingNutrition, isSaving, savedRecipe, error];
}

// BLoC
class RecipeBuilderBloc extends Bloc<RecipeBuilderEvent, RecipeBuilderState> {
  final RecipeRepository _recipeRepository;
  final _log = Logger('RecipeBuilderBloc');

  RecipeBuilderBloc(this._recipeRepository) : super(const RecipeBuilderState()) {
    on<InitBuilderEvent>(_onInit);
    on<UpdateNameEvent>(_onUpdateName);
    on<UpdateServingsEvent>(_onUpdateServings);
    on<AddIngredientEvent>(_onAddIngredient);
    on<RemoveIngredientEvent>(_onRemoveIngredient);
    on<UpdateIngredientGramsEvent>(_onUpdateIngredientGrams);
    on<SaveRecipeEvent>(_onSave);
  }

  void _onInit(InitBuilderEvent event, Emitter<RecipeBuilderState> emit) {
    final existing = event.existing;
    if (existing != null) {
      final nutrition = _computeNutrition(existing.ingredients, existing.servings);
      emit(RecipeBuilderState(
        existingId: existing.id,
        name: existing.name,
        servings: existing.servings,
        ingredients: existing.ingredients,
        perServingNutrition: nutrition,
      ));
    }
  }

  void _onUpdateName(UpdateNameEvent event, Emitter<RecipeBuilderState> emit) {
    emit(state.copyWith(name: event.name));
  }

  void _onUpdateServings(
      UpdateServingsEvent event, Emitter<RecipeBuilderState> emit) {
    final servings = event.servings.clamp(0.25, 100.0);
    final nutrition = _computeNutrition(state.ingredients, servings);
    emit(state.copyWith(servings: servings, perServingNutrition: nutrition));
  }

  void _onAddIngredient(
      AddIngredientEvent event, Emitter<RecipeBuilderState> emit) {
    final updated = [...state.ingredients, event.ingredient];
    final nutrition = _computeNutrition(updated, state.servings);
    emit(state.copyWith(ingredients: updated, perServingNutrition: nutrition));
  }

  void _onRemoveIngredient(
      RemoveIngredientEvent event, Emitter<RecipeBuilderState> emit) {
    if (event.index < 0 || event.index >= state.ingredients.length) return;
    final updated = [...state.ingredients]..removeAt(event.index);
    final nutrition = _computeNutrition(updated, state.servings);
    emit(state.copyWith(ingredients: updated, perServingNutrition: nutrition));
  }

  void _onUpdateIngredientGrams(
      UpdateIngredientGramsEvent event, Emitter<RecipeBuilderState> emit) {
    if (event.index < 0 || event.index >= state.ingredients.length) return;
    final updated = [...state.ingredients];
    updated[event.index] = updated[event.index].copyWith(grams: event.grams);
    final nutrition = _computeNutrition(updated, state.servings);
    emit(state.copyWith(ingredients: updated, perServingNutrition: nutrition));
  }

  Future<void> _onSave(
      SaveRecipeEvent event, Emitter<RecipeBuilderState> emit) async {
    if (!state.canSave) return;
    emit(state.copyWith(isSaving: true));

    try {
      RecipeEntity saved;
      if (state.existingId != null) {
        saved = await _recipeRepository.updateRecipe(
          id: state.existingId!,
          name: state.name.trim(),
          servings: state.servings,
          ingredients: state.ingredients,
        );
      } else {
        saved = await _recipeRepository.createRecipe(
          name: state.name.trim(),
          servings: state.servings,
          ingredients: state.ingredients,
        );
      }
      emit(state.copyWith(isSaving: false, savedRecipe: saved));
    } catch (e, st) {
      _log.severe('Failed to save recipe', e, st);
      emit(state.copyWith(isSaving: false, error: e.toString()));
    }
  }

  NutritionValues _computeNutrition(
      List<RecipeIngredientEntity> ingredients, double servings) {
    if (ingredients.isEmpty) {
      return const NutritionValues(kcal: 0, protein: 0, carbs: 0, fat: 0);
    }
    final calcIngredients =
        ingredients.map((i) => i.toRecipeIngredient()).toList();
    return RecipeCalc.calculatePerServing(calcIngredients, servings);
  }
}
