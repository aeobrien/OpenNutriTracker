import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_list_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/recipe_builder_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/recipe_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipeListScreen extends StatelessWidget {
  const RecipeListScreen({super.key});

  /// Reload the recipe list from anywhere that has access to GetIt.
  static void refresh() {
    locator<RecipeListBloc>().add(LoadRecipesEvent());
  }

  /// Safe variant that catches if widget tree is unmounted.
  static void refreshIfMounted(BuildContext context) {
    try {
      refresh();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: locator<RecipeListBloc>()..add(LoadRecipesEvent()),
      child: const _RecipeListBody(),
    );
  }
}

class _RecipeListBody extends StatefulWidget {
  const _RecipeListBody();

  @override
  State<_RecipeListBody> createState() => _RecipeListBodyState();
}

class _RecipeListBodyState extends State<_RecipeListBody> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocBuilder<RecipeListBloc, RecipeListState>(
      builder: (context, state) {
        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SearchBar(
                controller: _searchController,
                hintText: S.of(context).searchLabel,
                leading: const Icon(Icons.search),
                onChanged: (query) => context
                    .read<RecipeListBloc>()
                    .add(SearchRecipesEvent(query)),
              ),
            ),
            Expanded(
              child: _buildContent(context, state, theme),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(
      BuildContext context, RecipeListState state, ThemeData theme) {
    if (state is RecipeListLoadingState) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is RecipeListErrorState) {
      return Center(child: Text(state.message));
    }

    if (state is RecipeListLoadedState) {
      if (state.recipes.isEmpty && state.favourites.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu,
                  size: 64, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(S.of(context).noRecipesLabel,
                  style: theme.textTheme.bodyLarge),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: () async {
          context.read<RecipeListBloc>().add(LoadRecipesEvent());
        },
        child: ListView(
          children: [
            if (state.favourites.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(S.of(context).favouritesLabel,
                    style: theme.textTheme.titleSmall),
              ),
              ...state.favourites.map((recipe) => RecipeCard(
                    recipe: recipe,
                    onTap: () => _navigateToLog(context, recipe),
                    onLongPress: () =>
                        _showRecipeOptions(context, recipe),
                    onFavouriteToggle: () => context
                        .read<RecipeListBloc>()
                        .add(ToggleFavouriteEvent(
                            recipe.id, !recipe.favourite)),
                  )),
              const Divider(indent: 16, endIndent: 16),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(S.of(context).allItemsLabel,
                  style: theme.textTheme.titleSmall),
            ),
            ...state.recipes.map((recipe) => RecipeCard(
                  recipe: recipe,
                  onTap: () => _navigateToLog(context, recipe),
                  onLongPress: () =>
                      _showRecipeOptions(context, recipe),
                  onFavouriteToggle: () => context
                      .read<RecipeListBloc>()
                      .add(ToggleFavouriteEvent(
                          recipe.id, !recipe.favourite)),
                )),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  void _navigateToLog(BuildContext context, RecipeEntity recipe) {
    Navigator.of(context).pushNamed(
      NavigationOptions.recipeLogRoute,
      arguments: recipe,
    ).then((_) {
      if (mounted) {
        context.read<RecipeListBloc>().add(LoadRecipesEvent());
      }
    });
  }

  Future<void> _navigateToBuilder(
      BuildContext context, RecipeEntity? existing) async {
    final result = await Navigator.of(context).push<RecipeEntity>(
      MaterialPageRoute(
        builder: (_) => RecipeBuilderScreen(existingRecipe: existing),
      ),
    );
    if (result != null && mounted) {
      context.read<RecipeListBloc>().add(LoadRecipesEvent());
    }
  }

  void _showRecipeOptions(BuildContext context, RecipeEntity recipe) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(S.of(context).editRecipeLabel),
              onTap: () {
                Navigator.pop(ctx);
                _navigateToBuilder(context, recipe);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: Text(S.of(context).deleteRecipeLabel),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context, recipe);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, RecipeEntity recipe) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(S.of(context).deleteRecipeLabel),
        content: Text(S.of(context).deleteRecipeConfirmLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(S.of(context).dialogCancelLabel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<RecipeListBloc>()
                  .add(DeleteRecipeEvent(recipe.id));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(S.of(context).recipeDeletedLabel)),
              );
            },
            child: Text(S.of(context).buttonYesLabel),
          ),
        ],
      ),
    );
  }
}
