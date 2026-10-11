import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';

// Events
abstract class RecipeListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRecipesEvent extends RecipeListEvent {}

class SearchRecipesEvent extends RecipeListEvent {
  final String query;
  SearchRecipesEvent(this.query);
  @override
  List<Object?> get props => [query];
}

class DeleteRecipeEvent extends RecipeListEvent {
  final String id;
  DeleteRecipeEvent(this.id);
  @override
  List<Object?> get props => [id];
}

class ToggleFavouriteEvent extends RecipeListEvent {
  final String id;
  final bool value;
  ToggleFavouriteEvent(this.id, this.value);
  @override
  List<Object?> get props => [id, value];
}

// States
abstract class RecipeListState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RecipeListInitialState extends RecipeListState {}

class RecipeListLoadingState extends RecipeListState {}

class RecipeListLoadedState extends RecipeListState {
  final List<RecipeEntity> recipes;
  final List<RecipeEntity> favourites;

  RecipeListLoadedState({required this.recipes, required this.favourites});

  @override
  List<Object?> get props => [recipes, favourites];
}

class RecipeListErrorState extends RecipeListState {
  final String message;
  RecipeListErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class RecipeListBloc extends Bloc<RecipeListEvent, RecipeListState> {
  final RecipeRepository _recipeRepository;
  final _log = Logger('RecipeListBloc');

  RecipeListBloc(this._recipeRepository) : super(RecipeListInitialState()) {
    on<LoadRecipesEvent>(_onLoadRecipes);
    on<SearchRecipesEvent>(_onSearchRecipes);
    on<DeleteRecipeEvent>(_onDeleteRecipe);
    on<ToggleFavouriteEvent>(_onToggleFavourite);
  }

  Future<void> _onLoadRecipes(
      LoadRecipesEvent event, Emitter<RecipeListState> emit) async {
    emit(RecipeListLoadingState());
    try {
      final recipes = await _recipeRepository.getAllRecipes();
      final favourites = await _recipeRepository.getFavouriteRecipes();
      emit(RecipeListLoadedState(recipes: recipes, favourites: favourites));
    } catch (e, st) {
      _log.severe('Failed to load recipes', e, st);
      emit(RecipeListErrorState(e.toString()));
    }
  }

  Future<void> _onSearchRecipes(
      SearchRecipesEvent event, Emitter<RecipeListState> emit) async {
    try {
      if (event.query.isEmpty) {
        add(LoadRecipesEvent());
        return;
      }
      final recipes = await _recipeRepository.searchRecipes(event.query);
      final favourites =
          recipes.where((r) => r.favourite).toList();
      emit(RecipeListLoadedState(recipes: recipes, favourites: favourites));
    } catch (e, st) {
      _log.severe('Failed to search recipes', e, st);
      emit(RecipeListErrorState(e.toString()));
    }
  }

  Future<void> _onDeleteRecipe(
      DeleteRecipeEvent event, Emitter<RecipeListState> emit) async {
    try {
      await _recipeRepository.deleteRecipe(event.id);
      add(LoadRecipesEvent());
    } catch (e, st) {
      _log.severe('Failed to delete recipe', e, st);
    }
  }

  Future<void> _onToggleFavourite(
      ToggleFavouriteEvent event, Emitter<RecipeListState> emit) async {
    try {
      await _recipeRepository.toggleFavourite(event.id, event.value);
      add(LoadRecipesEvent());
    } catch (e, st) {
      _log.severe('Failed to toggle favourite', e, st);
    }
  }
}
