import 'package:flutter/material.dart';
import 'package:opennutritracker/features/recipes/presentation/recipe_builder_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/recipe_list_screen.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const RecipeListScreen();
  }
}

class RecipesPageFab extends StatelessWidget {
  const RecipesPageFab({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        FloatingActionButton.small(
          heroTag: 'fab_llm_recipe',
          onPressed: () => Navigator.of(context)
              .pushNamed(NavigationOptions.llmRecipeRoute)
              .then((_) => RecipeListScreen.refreshIfMounted(context)),
          tooltip: S.of(context).createFromTextLabel,
          child: const Icon(Icons.auto_awesome),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          heroTag: 'fab_new_recipe',
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(
                builder: (_) => const RecipeBuilderScreen()),
          ).then((_) => RecipeListScreen.refreshIfMounted(context)),
          tooltip: S.of(context).newRecipeLabel,
          child: const Icon(Icons.add),
        ),
      ],
    );
  }
}
