part of 'food_bloc.dart';

abstract class FoodState extends Equatable {
  const FoodState();
}

class FoodInitial extends FoodState {
  @override
  List<Object> get props => [];
}

class FoodLoadingState extends FoodState {
  @override
  List<Object?> get props => [];
}

class FoodLoadedState extends FoodState {
  final List<MealEntity> food;
  final bool usesImperialUnits;

  const FoodLoadedState({required this.food, this.usesImperialUnits = false});

  @override
  List<Object?> get props => [food, usesImperialUnits];
}

class FoodFailedState extends FoodState {
  @override
  List<Object?> get props => [];
}

/// This tab's database will not accept the key the app was built with, so no
/// search here can work until somebody puts a real one in. Separate from
/// [FoodFailedState] because that one is worth trying again and this one never
/// is.
class FoodSourceNotSetUpState extends FoodState {
  static const sentence =
      "This tab searches a US government food database that hasn't been set "
      "up with a key, so it can't answer. The Products tab still works.";

  @override
  List<Object?> get props => [];
}
