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
  /// A sleeping Mac Mini costs nothing here: [FoodFinder] answers with
  /// an empty list rather than throwing, and the public search runs exactly as
  /// it always did. Searching for food away from home has to keep working.
  ///
  /// And the mirror of it, which was missing until 24 August 2026: a public
  /// database that is down costs this household its own list nothing either.
  /// Open Food Facts answered every search that morning with a 503 and a page
  /// of HTML, from both of its search addresses, while its barcode lookup on
  /// the same host went on answering — and Aidan got an error screen with
  /// nothing on it, in a house whose own food list has twenty-one things in
  /// it. One throw discarded results that had already arrived.
  ///
  /// It is deliberately quiet about the failure rather than saying so on the
  /// screen: the shorter list is the only thing the person sees. Saying it out
  /// loud would be better and is a change to the screen, not to this.
  Future<List<MealEntity>> searchOFFProductsByString(
    String searchString,
  ) async {
    final ours = await _ours?.matching(searchString) ?? const <MealEntity>[];
    try {
      final theirs = await _productsRepository.getOFFProductsByString(
        searchString,
      );
      return [...ours, ...theirs];
    } catch (_) {
      // Nothing of ours either is the one case that still fails, because there
      // genuinely is nothing to show and an empty list would read as "no such
      // food" rather than "nobody could be asked".
      if (ours.isEmpty) rethrow;
      return ours;
    }
  }

  /// The foods this household already has, most-used-by-this-person first.
  /// Empty when the Mac Mini cannot be asked, which is what keeps the
  /// picker usable away from home.
  /// What the picker opens with, and whether the house answered at all.
  ///
  /// Carries the second half because an empty list on its own cannot tell the
  /// screen whether this household owns nothing or whether the Mac Mini was
  /// simply not reachable. See [FoodFinder.theirsAndWhether].
  ///
  /// With no household configured at all there is nothing to reach, so the
  /// house counts as having answered: the ordinary "type something to search"
  /// prompt is right for that person and always was.
  Future<({List<MealEntity> foods, bool houseAnswered})> ourFoods() async =>
      await _ours?.theirsAndWhether() ??
      (foods: const <MealEntity>[], houseAnswered: true);

  Future<List<MealEntity>> searchFDCFoodByString(String searchString) async {
    final foods = await _productsRepository.getFDCFoodsByString(searchString);
    return foods;
  }
}
