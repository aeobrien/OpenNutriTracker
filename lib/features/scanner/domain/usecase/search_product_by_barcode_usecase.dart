import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';

class SearchProductByBarcodeUseCase {
  final ProductsRepository _productsRepository;

  /// The household's own foods. Optional only so the existing tests can build
  /// this without one; the running app always passes it — see the locator.
  final FoodFinder? _ours;

  SearchProductByBarcodeUseCase(this._productsRepository, [this._ours]);

  /// Have we already got this packet?
  ///
  /// Asked of the house before the internet, and this is the case where it
  /// matters most. A barcode is an exact answer: if this household has scanned
  /// this packet before, somebody here has already read its label and corrected
  /// whatever the public database had wrong. Going out to the internet anyway
  /// would throw that work away and quietly re-import the numbers it replaced.
  ///
  /// If the house has never seen it — or cannot be asked, which for this
  /// purpose is the same answer — the public lookup runs as before.
  Future<MealEntity> searchProductByBarcode(String barcode) async {
    final known = await _ours?.withBarcode(barcode);
    if (known != null) return known;
    return await _productsRepository.getOFFProductByBarcode(barcode);
  }
}
