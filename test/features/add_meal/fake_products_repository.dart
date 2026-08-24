/// A stand-in for the public food databases.
///
/// It records what it was asked, because half of Release C's promise is about
/// what the app does *not* do: a packet this household has already read the
/// label of must not send anybody out to the internet to have those numbers
/// replaced by a stranger's reading of the same packet. "It never asked" is the
/// assertion, so the fake has to be able to say whether it was asked.
library;

import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

class FakeProductsRepository implements ProductsRepository {
  List<MealEntity> willReturn = const [];
  MealEntity? willReturnForBarcode;

  /// Set to make every search fail the way Open Food Facts was failing on
  /// 24 August 2026: a 503 with a page of HTML saying "Page temporarily
  /// unavailable", from both of its search addresses, while its barcode
  /// lookup on the same host went on answering.
  Object? searchesFailWith;

  final List<String> searchesMade = [];
  final List<String> barcodesLookedUp = [];

  @override
  Future<List<MealEntity>> getOFFProductsByString(String searchString) async {
    searchesMade.add(searchString);
    final fault = searchesFailWith;
    if (fault != null) throw fault;
    return willReturn;
  }

  @override
  Future<List<MealEntity>> getFDCFoodsByString(String searchString) async {
    searchesMade.add(searchString);
    return willReturn;
  }

  @override
  Future<MealEntity> getOFFProductByBarcode(String barcode) async {
    barcodesLookedUp.add(barcode);
    final answer = willReturnForBarcode;
    if (answer == null) throw StateError('nothing set up for $barcode');
    return answer;
  }
}
