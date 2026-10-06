import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/utils/calc/recipe_calc.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/recipes/data/data_source/claude_recipe_data_source.dart';
import 'package:opennutritracker/features/recipes/data/data_source/url_fetcher.dart';
import 'package:opennutritracker/features/recipes/domain/usecase/resolve_ingredients_usecase.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class LlmRecipeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ParseTextEvent extends LlmRecipeEvent {
  final String text;
  ParseTextEvent(this.text);
  @override
  List<Object?> get props => [text];
}

class ParseUrlEvent extends LlmRecipeEvent {
  final String url;
  ParseUrlEvent(this.url);
  @override
  List<Object?> get props => [url];
}

class UpdateResolvedGramsEvent extends LlmRecipeEvent {
  final int index;
  final double grams;
  UpdateResolvedGramsEvent(this.index, this.grams);
  @override
  List<Object?> get props => [index, grams];
}

class UpdateResolvedNameEvent extends LlmRecipeEvent {
  final String name;
  UpdateResolvedNameEvent(this.name);
  @override
  List<Object?> get props => [name];
}

class UpdateResolvedServingsEvent extends LlmRecipeEvent {
  final double servings;
  UpdateResolvedServingsEvent(this.servings);
  @override
  List<Object?> get props => [servings];
}

class ReplaceIngredientEvent extends LlmRecipeEvent {
  final int index;
  final String name;
  final String? foodItemId;
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;
  final MatchStatus matchStatus;

  ReplaceIngredientEvent({
    required this.index,
    required this.name,
    this.foodItemId,
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
    required this.matchStatus,
  });

  @override
  List<Object?> get props => [index, name, kcalPer100];
}

class SaveLlmRecipeEvent extends LlmRecipeEvent {}

// States
abstract class LlmRecipeState extends Equatable {
  @override
  List<Object?> get props => [];
}

class LlmRecipeInitialState extends LlmRecipeState {}

class LlmRecipeParsingState extends LlmRecipeState {}

class LlmRecipeResolvedState extends LlmRecipeState {
  final String recipeName;
  final double servings;
  final List<ResolvedIngredient> resolvedIngredients;
  final NutritionValues perServingNutrition;

  LlmRecipeResolvedState({
    required this.recipeName,
    required this.servings,
    required this.resolvedIngredients,
    required this.perServingNutrition,
  });

  @override
  List<Object?> get props =>
      [recipeName, servings, resolvedIngredients, perServingNutrition];
}

class LlmRecipeSavedState extends LlmRecipeState {}

class LlmRecipeErrorState extends LlmRecipeState {
  final String message;
  LlmRecipeErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class LlmRecipeBloc extends Bloc<LlmRecipeEvent, LlmRecipeState> {
  final ClaudeRecipeDataSource _claudeDataSource;
  final ResolveIngredientsUsecase _resolveUsecase;
  final RecipeRepository _recipeRepository;
  final SecureAppStorageProvider _secureStorage;
  final _log = Logger('LlmRecipeBloc');
  static const _uuid = Uuid();

  String _recipeName = '';
  double _servings = 4.0;
  List<ResolvedIngredient> _resolved = [];

  LlmRecipeBloc(
    this._claudeDataSource,
    this._resolveUsecase,
    this._recipeRepository,
    this._secureStorage,
  ) : super(LlmRecipeInitialState()) {
    on<ParseTextEvent>(_onParseText);
    on<ParseUrlEvent>(_onParseUrl);
    on<UpdateResolvedGramsEvent>(_onUpdateGrams);
    on<UpdateResolvedNameEvent>(_onUpdateName);
    on<UpdateResolvedServingsEvent>(_onUpdateServings);
    on<ReplaceIngredientEvent>(_onReplaceIngredient);
    on<SaveLlmRecipeEvent>(_onSave);
  }

  Future<void> _onParseText(
      ParseTextEvent event, Emitter<LlmRecipeState> emit) async {
    emit(LlmRecipeParsingState());
    try {
      final apiKey = await _secureStorage.getClaudeApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        emit(LlmRecipeErrorState('Claude API key not set'));
        return;
      }

      final result =
          await _claudeDataSource.parseRecipeFromText(apiKey, event.text);
      if (result.hasError) {
        emit(LlmRecipeErrorState(result.error!));
        return;
      }

      _resolved = await _resolveUsecase.execute(result.ingredients);
      _recipeName = result.recipeName;
      _servings = result.servings;

      emit(_buildResolvedState());
    } catch (e, st) {
      _log.severe('Failed to parse recipe text', e, st);
      emit(LlmRecipeErrorState(e.toString()));
    }
  }

  Future<void> _onParseUrl(
      ParseUrlEvent event, Emitter<LlmRecipeState> emit) async {
    emit(LlmRecipeParsingState());
    try {
      final apiKey = await _secureStorage.getClaudeApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        emit(LlmRecipeErrorState('Claude API key not set'));
        return;
      }

      final html = await UrlFetcher.fetch(event.url);
      final result = await _claudeDataSource.parseRecipeFromHtml(
          apiKey, html, event.url);
      if (result.hasError) {
        emit(LlmRecipeErrorState(result.error!));
        return;
      }

      _resolved = await _resolveUsecase.execute(result.ingredients);
      _recipeName = result.recipeName;
      _servings = result.servings;

      emit(_buildResolvedState());
    } catch (e, st) {
      _log.severe('Failed to parse recipe URL', e, st);
      emit(LlmRecipeErrorState(e.toString()));
    }
  }

  void _onUpdateGrams(
      UpdateResolvedGramsEvent event, Emitter<LlmRecipeState> emit) {
    if (event.index >= 0 && event.index < _resolved.length) {
      _resolved = [..._resolved];
      _resolved[event.index] = _resolved[event.index].copyWith(grams: event.grams);
      emit(_buildResolvedState());
    }
  }

  void _onUpdateName(
      UpdateResolvedNameEvent event, Emitter<LlmRecipeState> emit) {
    _recipeName = event.name;
    emit(_buildResolvedState());
  }

  void _onUpdateServings(
      UpdateResolvedServingsEvent event, Emitter<LlmRecipeState> emit) {
    _servings = event.servings;
    emit(_buildResolvedState());
  }

  void _onReplaceIngredient(
      ReplaceIngredientEvent event, Emitter<LlmRecipeState> emit) {
    if (event.index >= 0 && event.index < _resolved.length) {
      _resolved = [..._resolved];
      _resolved[event.index] = _resolved[event.index].copyWith(
        name: event.name,
        foodItemId: event.foodItemId,
        kcalPer100: event.kcalPer100,
        proteinPer100: event.proteinPer100,
        carbsPer100: event.carbsPer100,
        fatPer100: event.fatPer100,
        matchStatus: event.matchStatus,
      );
      emit(_buildResolvedState());
    }
  }

  Future<void> _onSave(
      SaveLlmRecipeEvent event, Emitter<LlmRecipeState> emit) async {
    try {
      final ingredients = _resolved.map((r) => RecipeIngredientEntity(
            id: _uuid.v4(),
            recipeId: '',
            foodItemId: r.foodItemId,
            name: r.name,
            grams: r.grams,
            kcalPer100: r.kcalPer100,
            proteinPer100: r.proteinPer100,
            carbsPer100: r.carbsPer100,
            fatPer100: r.fatPer100,
          )).toList();

      await _recipeRepository.createRecipe(
        name: _recipeName.trim().isNotEmpty ? _recipeName.trim() : 'Untitled Recipe',
        servings: _servings,
        ingredients: ingredients,
      );

      emit(LlmRecipeSavedState());
    } catch (e, st) {
      _log.severe('Failed to save LLM recipe', e, st);
      emit(LlmRecipeErrorState(e.toString()));
    }
  }

  LlmRecipeResolvedState _buildResolvedState() {
    final calcIngredients = _resolved.map((r) => RecipeIngredient(
          kcalPer100g: r.kcalPer100,
          proteinPer100g: r.proteinPer100,
          carbsPer100g: r.carbsPer100,
          fatPer100g: r.fatPer100,
          grams: r.grams,
        )).toList();

    final nutrition = RecipeCalc.calculatePerServing(calcIngredients, _servings);

    return LlmRecipeResolvedState(
      recipeName: _recipeName,
      servings: _servings,
      resolvedIngredients: _resolved,
      perServingNutrition: nutrition,
    );
  }
}
