part of 'home_bloc.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => [];
}

class LoadItemsEvent extends HomeEvent {
  const LoadItemsEvent();
}

/// Refresh HealthKit active calories without a full reload.
///
/// Dispatched when the app returns to the foreground so the earned-calorie
/// allowance picks up exercise logged while the app was backgrounded. Only
/// re-reads HealthKit and recomputes the allowance — intake lists are reused
/// from the current loaded state.
class RefreshActiveCaloriesEvent extends HomeEvent {
  const RefreshActiveCaloriesEvent();
}
