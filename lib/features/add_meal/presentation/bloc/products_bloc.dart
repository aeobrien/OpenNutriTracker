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

  ProductsBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(ProductsInitial()) {
    on<LoadProductsEvent>((event, emit) async {
      if (event.searchString != _searchString) {
        _searchString = event.searchString;
        emit(ProductsLoadingState());
        try {
          final result = await _searchProductUseCase
              .searchOFFProductsByString(_searchString);
          final config = await _getConfigUsecase.getConfig();

          emit(ProductsLoadedState(
              products: result, usesImperialUnits: config.usesImperialUnits));
        } catch (error) {
          log.severe(error);
          emit(ProductsFailedState());
        }
      }
    });
    on<LoadOurFoodsEvent>((event, emit) async {
      // No loading spinner and no error state on purpose. This runs before the
      // person has asked for anything, so it must never take the screen over
      // or accuse the kitchen computer of anything: it either quietly puts
      // their own foods up, or leaves the screen exactly as it was.
      final ours = await _searchProductUseCase.ourFoods();
      if (ours.isEmpty) return;
      final config = await _getConfigUsecase.getConfig();
      emit(ProductsLoadedState(
          products: ours,
          usesImperialUnits: config.usesImperialUnits,
          ours: true));
    });
    on<RefreshProductsEvent>((event, emit) async {
      emit(ProductsLoadingState());
      try {
        final result = await _searchProductUseCase
            .searchOFFProductsByString(_searchString);
        emit(ProductsLoadedState(products: result));
      } catch (error) {
        log.severe(error);
        emit(ProductsFailedState());
      }
    });
  }
}
