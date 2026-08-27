import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

part 'products_event.dart';

part 'products_state.dart';

class ProductsBloc extends Bloc<ProductsEvent, ProductsState> {
  final log = Logger('ProductsBloc');

  final SearchProductsUseCase _searchProductUseCase;
  final GetConfigUsecase _getConfigUsecase;

  String _searchString = "";

  /// Whether the last search left an error on the screen.
  ///
  /// The words on their own are not enough to decide whether a search is worth
  /// making. Searching the same thing straight after it worked is worth
  /// nothing — the results are already there. Searching the same thing after it
  /// failed is the most ordinary thing a person does, and until 24 August 2026
  /// it sent nothing at all: no request, no spinner, no fresh error, forever,
  /// even once the database behind it had come back up. Aidan spent about a
  /// week pressing it.
  bool _lastSearchFailed = false;

  ProductsBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(ProductsInitial()) {
    on<LoadProductsEvent>((event, emit) async {
      if (event.searchString == _searchString && !_lastSearchFailed) return;
      _searchString = event.searchString;
      emit(ProductsLoadingState());
      try {
        final result =
            await _searchProductUseCase.searchOFFProductsByString(_searchString);
        final config = await _getConfigUsecase.getConfig();

        _lastSearchFailed = false;
        emit(ProductsLoadedState(
            products: result, usesImperialUnits: config.usesImperialUnits));
      } catch (error) {
        log.severe(error);
        _lastSearchFailed = true;
        emit(ProductsFailedState());
      }
    });
    on<LoadOurFoodsEvent>((event, emit) async {
      // No loading spinner and no error state on purpose. This runs before the
      // person has asked for anything, so it must never take the screen over
      // or accuse the Mac Mini of anything: it either quietly puts
      // their own foods up, or leaves the screen exactly as it was.
      final ours = await _searchProductUseCase.ourFoods();
      if (ours.foods.isEmpty) {
        // Only when the house was not there to answer. A house that answered
        // "none" leaves the ordinary opening prompt alone, which is the right
        // thing for somebody who genuinely has no foods of their own yet.
        if (!ours.houseAnswered) emit(OurFoodsUnreachableState());
        return;
      }
      final config = await _getConfigUsecase.getConfig();
      emit(ProductsLoadedState(
          products: ours.foods,
          usesImperialUnits: config.usesImperialUnits,
          ours: true));
    });
    on<RefreshProductsEvent>((event, emit) async {
      emit(ProductsLoadingState());
      try {
        final result = await _searchProductUseCase
            .searchOFFProductsByString(_searchString);
        _lastSearchFailed = false;
        emit(ProductsLoadedState(products: result));
      } catch (error) {
        log.severe(error);
        _lastSearchFailed = true;
        emit(ProductsFailedState());
      }
    });
  }
}
