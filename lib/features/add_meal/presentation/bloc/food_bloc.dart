import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';

part 'food_event.dart';

part 'food_state.dart';

class FoodBloc extends Bloc<FoodEvent, FoodState> {
  final log = Logger('FoodBloc');

  final SearchProductsUseCase _searchProductUseCase;
  final GetConfigUsecase _getConfigUsecase;

  String _searchString = "";

  /// See [ProductsBloc] for why the words alone are not enough to decide
  /// whether a search is worth making. Same fault, same fix, 24 August 2026.
  bool _lastSearchFailed = false;

  FoodBloc(this._searchProductUseCase, this._getConfigUsecase)
      : super(FoodInitial()) {
    on<LoadFoodEvent>((event, emit) async {
      if (event.searchString == _searchString && !_lastSearchFailed) return;
      _searchString = event.searchString;
      emit(FoodLoadingState());
      try {
        final result =
            await _searchProductUseCase.searchFDCFoodByString(_searchString);
        final config = await _getConfigUsecase.getConfig();

        _lastSearchFailed = false;
        emit(FoodLoadedState(
            food: result, usesImperialUnits: config.usesImperialUnits));
      } on FoodDatabaseNotSetUp {
        // Not marked as failed: there is nothing to try again, and leaving the
        // flag set would send a fresh doomed request every time the words are
        // retyped.
        log.severe('the food database has no usable key');
        emit(FoodSourceNotSetUpState());
      } catch (error) {
        log.severe(error);
        _lastSearchFailed = true;
        emit(FoodFailedState());
      }
    });
    on<RefreshFoodEvent>((event, emit) async {
      emit(FoodLoadingState());
      try {
        final result =
            await _searchProductUseCase.searchFDCFoodByString(_searchString);
        _lastSearchFailed = false;
        emit(FoodLoadedState(food: result));
      } on FoodDatabaseNotSetUp {
        log.severe('the food database has no usable key');
        emit(FoodSourceNotSetUpState());
      } catch (error) {
        log.severe(error);
        _lastSearchFailed = true;
        emit(FoodFailedState());
      }
    });
  }
}
