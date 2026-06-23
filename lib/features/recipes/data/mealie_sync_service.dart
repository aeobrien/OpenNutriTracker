import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/features/recipes/data/data_source/mealie_data_source.dart';
import 'package:opennutritracker/features/recipes/data/mealie_recipe_mapper.dart';

/// Result of a one-way Mealie -> FoodTracker recipe sync.
class MealieSyncResult {
  /// Recipes successfully mirrored into the local store.
  final int synced;

  /// Recipes that errored while fetching/mapping (skipped, not fatal).
  final int failed;

  /// Total recipes Mealie reported.
  final int total;

  const MealieSyncResult({
    required this.synced,
    required this.failed,
    required this.total,
  });

  @override
  String toString() => 'MealieSyncResult(synced: $synced, failed: $failed, total: $total)';
}

/// Keeps FoodTracker's local recipe store as a **one-way, read-only mirror** of
/// Mealie. Mealie is the single source of truth (the shared cookbook); this pulls
/// every recipe down and upserts it locally so recipes are loggable offline.
/// FoodTracker never writes recipes back to Mealie.
///
/// Not yet handled (deliberately deferred — see MEALIE_INTEGRATION.md):
///  - Deletion pruning: recipes removed in Mealie are not yet removed from the
///    local mirror (needs a record of previously-synced slugs or a source marker).
///  - Incremental sync: every run re-fetches all recipes rather than only changed
///    ones (fine for modest libraries; optimise via Mealie's updatedAt later).
class MealieSyncService {
  final MealieDataSource _dataSource;
  final RecipeRepository _recipeRepository;
  final _log = Logger('MealieSyncService');

  static const _pageSize = 100;

  MealieSyncService(this._dataSource, this._recipeRepository);

  /// Pulls every recipe from Mealie and mirrors it locally. A single recipe that
  /// fails to fetch/map is logged and skipped — it never aborts the whole sync.
  Future<MealieSyncResult> syncAllRecipes({bool nutritionIsPerServing = true}) async {
    final slugs = await _collectAllSlugs();
    _log.info('Mealie sync: ${slugs.length} recipes to mirror');

    var synced = 0;
    var failed = 0;
    for (final slug in slugs) {
      try {
        final detail = await _dataSource.fetchRecipe(slug);
        final entity = MealieRecipeMapper.toRecipeEntity(
          detail,
          nutritionIsPerServing: nutritionIsPerServing,
        );
        await _recipeRepository.upsertMirroredRecipe(entity);
        synced++;
      } catch (e) {
        _log.warning('Skipping recipe "$slug" — sync failed: $e');
        failed++;
      }
    }

    final result = MealieSyncResult(synced: synced, failed: failed, total: slugs.length);
    _log.info('Mealie sync complete: $result');
    return result;
  }

  Future<List<String>> _collectAllSlugs() async {
    final slugs = <String>[];
    var page = 1;
    while (true) {
      final pageResult = await _dataSource.fetchRecipes(page: page, perPage: _pageSize);
      if (pageResult.items.isEmpty) break;
      slugs.addAll(pageResult.items.map((s) => s.slug).where((s) => s.isNotEmpty));
      if (pageResult.totalPages <= page) break;
      page++;
    }
    return slugs;
  }
}
