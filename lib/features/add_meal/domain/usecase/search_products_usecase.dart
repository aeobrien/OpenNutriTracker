import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';

class SearchProductsUseCase {
  final ProductsRepository _productsRepository;

  /// The household's own foods. Optional only so the existing tests can build
  /// this without one; the running app always passes it — see the locator.
  final FoodFinder? _ours;

  SearchProductsUseCase(this._productsRepository, [this._ours]);

  /// Ours first, then everybody else's.
  ///
  /// The order is the whole point and it is not a preference. A food in the
  /// household's own list carries numbers somebody here checked against the
  /// packet in the cupboard; a public database's entry is a stranger's reading
  /// of a packet that may not even be the same one. So when the house already
  /// knows a food, that is the row the thumb lands on.
  ///
  /// A sleeping kitchen computer costs nothing here: [FoodFinder] answers with
  /// an empty list rather than throwing, and the public search runs exactly as
  /// it always did. Searching for food away from home has to keep working.
  Future<List<MealEntity>> searchOFFProductsByString(
    String searchString,
  ) async {
    final ours = await _ours?.matching(searchString) ?? const <MealEntity>[];
    final theirs = await _productsRepository.getOFFProductsByString(
      searchString,
    );
    return [...ours, ...theirs];
  }

  /// The foods this household already has, most-used-by-this-person first.
  /// Empty when the kitchen computer cannot be asked, which is what keeps the
  /// picker usable away from home.
  Future<List<MealEntity>> ourFoods() async =>
      await _ours?.theirs() ?? const <MealEntity>[];

  Future<List<MealEntity>> searchFDCFoodByString(String searchString) async {
    final foods = await _productsRepository.getFDCFoodsByString(searchString);
    return foods;
  }
}
