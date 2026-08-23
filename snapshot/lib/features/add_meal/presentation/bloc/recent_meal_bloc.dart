import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

part 'recent_meal_event.dart';

part 'recent_meal_state.dart';

class RecentMealBloc extends Bloc<RecentMealEvent, RecentMealState> {
  final log = Logger('RecentMealBloc');

  final GetIntakeUsecase _getIntakeUsecase;
  final GetConfigUsecase _getConfigUsecase;

  RecentMealBloc(this._getIntakeUsecase, this._getConfigUsecase)
      : super(RecentMealInitial()) {
    on<LoadRecentMealEvent>((event, emit) async {
      emit(RecentMealLoadingState());
      try {
        final config = await _getConfigUsecase.getConfig();
        final recentIntake = await _getIntakeUsecase.getRecentIntake();
        final favouriteMeals = await _getIntakeUsecase.getFavouriteMeals();
        final searchString = (event.searchString).toLowerCase();

        List<MealEntity> recentMeals;
        List<MealEntity> filteredFavourites;

        if (searchString.isEmpty) {
          recentMeals =
              recentIntake.map((intake) => intake.meal).toList();
          filteredFavourites = favouriteMeals;
        } else {
          recentMeals = recentIntake
              .where(matchesSearchString(searchString))
              .map((intake) => intake.meal)
              .toList();
          filteredFavourites = favouriteMeals
              .where((meal) => _mealMatchesSearch(meal, searchString))
              .toList();
        }

        emit(RecentMealLoadedState(
            recentMeals: recentMeals,
            favouriteMeals: filteredFavourites,
            usesImperialUnits: config.usesImperialUnits));
      } catch (error) {
        log.severe(error);
        emit(RecentMealFailedState());
      }
    });

    on<ToggleFavouriteEvent>((event, emit) async {
      try {
        await _getIntakeUsecase.toggleFavourite(
            event.foodItemId, !event.currentValue);
        // Reload to reflect the change
        final currentState = state;
        if (currentState is RecentMealLoadedState) {
          final favouriteMeals =
              await _getIntakeUsecase.getFavouriteMeals();
          final recentIntake = await _getIntakeUsecase.getRecentIntake();
          emit(RecentMealLoadedState(
              recentMeals:
                  recentIntake.map((intake) => intake.meal).toList(),
              favouriteMeals: favouriteMeals,
              usesImperialUnits: currentState.usesImperialUnits));
        }
      } catch (error) {
        log.severe('Error toggling favourite: $error');
      }
    });
  }

  bool Function(IntakeEntity) matchesSearchString(String searchString) {
    return (intake) =>
        (intake.meal.name?.toLowerCase().contains(searchString) ?? false) ||
        (intake.meal.brands?.toLowerCase().contains(searchString) ?? false);
  }

  bool _mealMatchesSearch(MealEntity meal, String searchString) {
    return (meal.name?.toLowerCase().contains(searchString) ?? false) ||
        (meal.brands?.toLowerCase().contains(searchString) ?? false);
  }
}
