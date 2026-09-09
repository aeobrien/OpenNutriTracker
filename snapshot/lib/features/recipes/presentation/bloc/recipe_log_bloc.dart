import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/utils/calc/recipe_calc.dart';
import 'package:uuid/uuid.dart';

// Events
abstract class RecipeLogEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class LoadRecipeEvent extends RecipeLogEvent {
  final RecipeEntity recipe;
  LoadRecipeEvent(this.recipe);
  @override
  List<Object?> get props => [recipe];
}

class UpdateMultiplierEvent extends RecipeLogEvent {
  final double multiplier;
  UpdateMultiplierEvent(this.multiplier);
  @override
  List<Object?> get props => [multiplier];
}

class LogRecipeEvent extends RecipeLogEvent {
  final String mealSlot;
  final DateTime day;
  LogRecipeEvent({required this.mealSlot, required this.day});
  @override
  List<Object?> get props => [mealSlot, day];
}

// States
abstract class RecipeLogState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RecipeLogInitialState extends RecipeLogState {}

class RecipeLogLoadedState extends RecipeLogState {
  final RecipeEntity recipe;
  final double multiplier;
  final NutritionValues computedNutrition;

  RecipeLogLoadedState({
    required this.recipe,
    required this.multiplier,
    required this.computedNutrition,
  });

  @override
  List<Object?> get props => [recipe, multiplier, computedNutrition];
}

class RecipeLogSavingState extends RecipeLogState {}

class RecipeLogSavedState extends RecipeLogState {}

class RecipeLogErrorState extends RecipeLogState {
  final String message;
  RecipeLogErrorState(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class RecipeLogBloc extends Bloc<RecipeLogEvent, RecipeLogState> {
  final IntakeRepository _intakeRepository;
  final RecipeRepository _recipeRepository;
  final TrackedDayRepository _trackedDayRepository;
  final _log = Logger('RecipeLogBloc');
  static const _uuid = Uuid();

  RecipeEntity? _recipe;
  double _multiplier = 1.0;

  RecipeLogBloc(
    this._intakeRepository,
    this._recipeRepository,
    this._trackedDayRepository,
  ) : super(RecipeLogInitialState()) {
    on<LoadRecipeEvent>(_onLoad);
    on<UpdateMultiplierEvent>(_onUpdateMultiplier);
    on<LogRecipeEvent>(_onLog);
  }

  void _onLoad(LoadRecipeEvent event, Emitter<RecipeLogState> emit) {
    _recipe = event.recipe;
    _multiplier = 1.0;
    emit(_buildLoadedState());
  }

  void _onUpdateMultiplier(
      UpdateMultiplierEvent event, Emitter<RecipeLogState> emit) {
    _multiplier = event.multiplier;
    emit(_buildLoadedState());
  }

  Future<void> _onLog(
      LogRecipeEvent event, Emitter<RecipeLogState> emit) async {
    if (_recipe == null) return;
    emit(RecipeLogSavingState());

    try {
      final recipe = _recipe!;
      final kcal = recipe.kcalPerServing * _multiplier;
      final protein = recipe.proteinPerServing * _multiplier;
      final carbs = recipe.carbsPerServing * _multiplier;
      final fat = recipe.fatPerServing * _multiplier;

      await _intakeRepository.addRecipeIntake(
        id: _uuid.v4(),
        recipeId: recipe.id,
        recipeName: recipe.name,
        multiplier: _multiplier,
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        mealSlot: event.mealSlot,
        dateTime: event.day,
      );

      // Update daily stats
      await _trackedDayRepository.addDayTrackedCalories(event.day, kcal);
      await _trackedDayRepository.addDayMacrosTracked(event.day,
          carbsTracked: carbs, fatTracked: fat, proteinTracked: protein);

      // Update recipe lastUsedAt
      await _recipeRepository.updateLastUsed(recipe.id);

      _log.fine('Recipe logged: ${recipe.name} x$_multiplier');
      emit(RecipeLogSavedState());
    } catch (e, st) {
      _log.severe('Failed to log recipe', e, st);
      emit(RecipeLogErrorState(e.toString()));
    }
  }

  RecipeLogLoadedState _buildLoadedState() {
    final recipe = _recipe!;
    return RecipeLogLoadedState(
      recipe: recipe,
      multiplier: _multiplier,
      computedNutrition: NutritionValues(
        kcal: recipe.kcalPerServing * _multiplier,
        protein: recipe.proteinPerServing * _multiplier,
        carbs: recipe.carbsPerServing * _multiplier,
        fat: recipe.fatPerServing * _multiplier,
      ),
    );
  }
}
