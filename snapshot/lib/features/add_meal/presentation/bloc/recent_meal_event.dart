part of 'recent_meal_bloc.dart';

abstract class RecentMealEvent extends Equatable {
  const RecentMealEvent();
}

class LoadRecentMealEvent extends RecentMealEvent {
  final String searchString;

  /// an empty `searchString` will load all RecentMeal
  const LoadRecentMealEvent({required this.searchString});

  @override
  List<Object?> get props => [];
}

class ToggleFavouriteEvent extends RecentMealEvent {
  final String foodItemId;
  final bool currentValue;

  const ToggleFavouriteEvent(
      {required this.foodItemId, required this.currentValue});

  @override
  List<Object?> get props => [foodItemId, currentValue];
}
