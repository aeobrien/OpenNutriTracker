/// The household's own foods, asked for the way each screen needs them.
library;

import 'package:logging/logging.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_food.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';

/// What the house has, before anything from the internet.
///
/// Three screens ask this the same question in three shapes — the picker's
/// opening list, the search box, and the barcode scanner — and all three want
/// the same answer first: *have we already got this?* Their own foods carry
/// numbers this household checked; a public database's are somebody else's
/// guess at a packet that may not even be the one on the counter.
///
/// Every method here answers with an empty list rather than throwing when the
/// Mac Mini cannot be reached. That is deliberate and it is the whole shape of
/// the release: the household list is a *first* look, not the only one, so a
/// sleeping Mini has to degrade into "we did not find one of ours" and let the
/// public search carry on. A screen that failed here would be a screen that
/// stops working away from home.
class FoodFinder {
  final HouseholdApi _api;
  final HouseholdRepository _household;
  final _log = Logger('FoodFinder');

  FoodFinder(this._api, this._household);

  /// This person's own foods, most-used first. What the picker opens with.
  Future<List<MealEntity>> theirs() => _ask(() async =>
      _api.foods(forPerson: await _household.storedOwner()));

  /// The household's foods matching what was typed, still in this person's
  /// order.
  ///
  /// The match is checked twice — once by the Mac Mini, which is the
  /// authority, and once here. See [HouseholdFood.matches] for why the second
  /// check is not redundant.
  Future<List<MealEntity>> matching(String text) {
    if (text.trim().isEmpty) return theirs();
    return _ask(() async {
      final found =
          await _api.foods(q: text, forPerson: await _household.storedOwner());
      return [for (final f in found) if (f.matches(text)) f];
    });
  }

  /// The household's own food for a barcode, or null if the house has never
  /// seen this packet.
  ///
  /// Null and "the Mini is asleep" are the same answer here on purpose: both
  /// mean "we cannot serve this from our own list", and the caller's next move
  /// is the same either way.
  Future<MealEntity?> withBarcode(String barcode) async {
    final found = await _ask(() => _api.foods(barcode: barcode));
    return found.isEmpty ? null : found.first;
  }

  /// Go and look a packet up on the web, when neither list here had it.
  ///
  /// Last, always. The order is the point of the whole release: the
  /// household's own foods carry numbers somebody here checked, the public
  /// database carries numbers somebody somewhere checked, and this carries
  /// numbers a model read off a shop's page ten seconds ago. Putting it above
  /// either of the others would be putting the least-checked figures in front
  /// of the most-checked ones.
  ///
  /// What comes back are drafts, not foods. Nothing is saved by asking — a
  /// person picks one and confirms it on the same screen a photographed label
  /// goes through, and that screen is the only place a food is written.
  ///
  /// An empty list covers three different situations on purpose: nothing was
  /// found, the Mac Mini could not be reached, and the Mac Mini
  /// is too old to know how to look. All three mean the same thing to the
  /// person holding the phone — no, and you can still type it in yourself.
  Future<List<FoodDraft>> huntFor(String text) async {
    final name = text.trim();
    if (name.isEmpty) return const [];
    try {
      final candidates = await _api.findFood(name);
      return [for (final c in candidates) FoodDraft.fromWebCandidate(c)];
    } catch (e) {
      _log.info('[HOUSE] the hunt for "$name" did not come back: $e');
      return const [];
    }
  }

  Future<List<MealEntity>> _ask(
      Future<List<HouseholdFood>> Function() call) async {
    try {
      final foods = await call();
      return [
        for (final f in foods) MealEntity.fromHouseholdFood(f),
      ];
    } catch (e) {
      // Not shown to anybody. The public search is about to run and will say
      // its own piece if it fails too; two error messages for one search would
      // be worse than the one that is coming.
      _log.info('[HOUSE] the household food list was not available: $e');
      return const [];
    }
  }
}
