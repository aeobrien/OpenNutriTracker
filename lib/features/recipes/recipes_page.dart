import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/recipes/data/data_source/mealie_data_source.dart';
import 'package:opennutritracker/features/recipes/data/mealie_secure_storage.dart';
import 'package:opennutritracker/features/recipes/data/mealie_sync_service.dart';
import 'package:opennutritracker/features/recipes/presentation/recipe_list_screen.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecipeListScreen();
  }
}

/// Recipes are mirrored one-way from Mealie (the cookbook), so authoring lives in
/// Mealie — not here. This button pulls the latest recipes down into the local
/// store so they can be logged offline.
///
/// The manual recipe builder and the LLM recipe importer still exist in the
/// codebase (RecipeBuilderScreen / llmRecipeRoute) but are intentionally no longer
/// reachable from this FAB, since Mealie owns recipe authoring.
class RecipesPageFab extends StatelessWidget {
  const RecipesPageFab({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'fab_sync_mealie',
      onPressed: () => _syncFromMealie(context),
      tooltip: 'Sync recipes from Mealie',
      child: const Icon(Icons.sync),
    );
  }

  Future<void> _syncFromMealie(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final storage = SecureAppStorageProvider();

    if (!await storage.hasMealieConfig()) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Set your Mealie server URL and token in Settings first.'),
      ));
      return;
    }

    final url = (await storage.getMealieBaseUrl())!;
    final token = (await storage.getMealieToken())!;

    messenger.showSnackBar(
      const SnackBar(content: Text('Syncing recipes from Mealie…')),
    );

    try {
      final service = MealieSyncService(
        MealieDataSource(baseUrl: url, token: token),
        locator<RecipeRepository>(),
      );
      final result = await service.syncAllRecipes();
      final skipped = result.failed > 0 ? ' (${result.failed} skipped)' : '';
      messenger.showSnackBar(SnackBar(
        content: Text('Synced ${result.synced} recipe(s) from Mealie$skipped.'),
      ));
      if (context.mounted) {
        RecipeListScreen.refreshIfMounted(context);
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Mealie sync failed: $e')),
      );
    }
  }
}
