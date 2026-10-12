import 'package:flutter/material.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';

class RecipeCard extends StatelessWidget {
  final RecipeEntity recipe;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onFavouriteToggle;

  const RecipeCard({
    super.key,
    required this.recipe,
    required this.onTap,
    this.onLongPress,
    this.onFavouriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.restaurant_menu,
                  color: theme.colorScheme.primary, size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${recipe.kcalPerServing.round()} kcal · '
                      'P ${recipe.proteinPerServing.round()}g · '
                      'C ${recipe.carbsPerServing.round()}g · '
                      'F ${recipe.fatPerServing.round()}g',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (onFavouriteToggle != null)
                IconButton(
                  icon: Icon(
                    recipe.favourite ? Icons.star : Icons.star_border,
                    color: recipe.favourite
                        ? Colors.amber
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onPressed: onFavouriteToggle,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
