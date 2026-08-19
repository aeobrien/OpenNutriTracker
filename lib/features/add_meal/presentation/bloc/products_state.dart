part of 'products_bloc.dart';

abstract class ProductsState extends Equatable {
  const ProductsState();
}

class ProductsInitial extends ProductsState {
  @override
  List<Object> get props => [];
}

class ProductsLoadingState extends ProductsState {
  @override
  List<Object?> get props => [];
}

class ProductsLoadedState extends ProductsState {
  final List<MealEntity> products;
  final bool usesImperialUnits;

  /// True when this list is the household's own foods rather than the result
  /// of a search. The screen says so above the list, because "foods this house
  /// already knows" and "everything on the internet matching what you typed"
  /// are different enough that a person should never have to work out which
  /// one they are looking at.
  final bool ours;

  const ProductsLoadedState(
      {required this.products,
      this.usesImperialUnits = false,
      this.ours = false});

  @override
  List<Object?> get props => [products, ours];
}

class ProductsFailedState extends ProductsState {
  @override
  List<Object?> get props => [];
}
