part of 'recent_meal_bloc.dart';

abstract class RecentMealState extends Equatable {
  const RecentMealState();
}

class RecentMealInitial extends RecentMealState {
  @override
  List<Object> get props => [];
}

class RecentMealLoadingState extends RecentMealState {
  @override
  List<Object?> get props => [];
}

class RecentMealLoadedState extends RecentMealState {
  final List<MealEntity> recentMeals;
  final List<MealEntity> favouriteMeals;
  final bool usesImperialUnits;

  const RecentMealLoadedState(
      {required this.recentMeals,
      this.favouriteMeals = const [],
      this.usesImperialUnits = false});

  @override
  List<Object?> get props => [recentMeals, favouriteMeals, usesImperialUnits];
}

class RecentMealFailedState extends RecentMealState {
  @override
  List<Object?> get props => [];
}
