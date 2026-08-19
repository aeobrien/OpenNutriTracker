part of 'products_bloc.dart';

abstract class ProductsEvent extends Equatable {
  const ProductsEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductsEvent extends ProductsEvent {
  final String searchString;

  const LoadProductsEvent({required this.searchString});

  @override
  List<Object?> get props => [searchString];
}

class RefreshProductsEvent extends ProductsEvent {
  const RefreshProductsEvent();

  @override
  List<Object?> get props => [];
}

/// Open the picker on the foods this household already has, before anybody has
/// typed anything.
class LoadOurFoodsEvent extends ProductsEvent {
  const LoadOurFoodsEvent();

  @override
  List<Object?> get props => [];
}
