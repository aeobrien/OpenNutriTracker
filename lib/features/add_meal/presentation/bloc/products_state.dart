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

  /// True when the usual food database refused every ask and a second one
  /// answered instead.
  ///
  /// The screen says so, because those results are measurably worse — on
  /// 1 September 2026 "tesco milk" came back from the second service as milk
  /// chocolate lollipops, raisins and orange cookies with no milk in the top
  /// four, where the usual one returned semi-skimmed milk — and a person who
  /// cannot tell which list they are looking at will read a bad list as the app
  /// getting worse rather than as the source having refused.
  final bool secondChoice;

  const ProductsLoadedState(
      {required this.products,
      this.usesImperialUnits = false,
      this.ours = false,
      this.secondChoice = false});

  @override
  List<Object?> get props => [products, ours, secondChoice];
}

/// The picker opened, asked the house what this person's foods are, and could
/// not reach it.
///
/// Separate from [ProductsFailedState], which is a search that failed after
/// somebody asked for one. Nobody asked for this: it happens on opening the
/// screen, so it must not take the screen over or offer a retry button. All it
/// does is replace the "type something to search" prompt, which is the wrong
/// sentence when the truth is that the house was not there to answer.
class OurFoodsUnreachableState extends ProductsState {
  static const sentence =
      "Couldn't reach the house, so your own foods aren't here.";

  @override
  List<Object?> get props => [];
}

class ProductsFailedState extends ProductsState {
  @override
  List<Object?> get props => [];
}
