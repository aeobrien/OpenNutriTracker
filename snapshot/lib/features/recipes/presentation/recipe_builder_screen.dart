import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/ingredient_search_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipeBuilderScreen extends StatelessWidget {
  final RecipeEntity? existingRecipe;

  const RecipeBuilderScreen({super.key, this.existingRecipe});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final bloc = RecipeBuilderBloc(locator());
        if (existingRecipe != null) {
          bloc.add(InitBuilderEvent(existing: existingRecipe));
        }
        return bloc;
      },
      child: const _RecipeBuilderBody(),
    );
  }
}

class _RecipeBuilderBody extends StatefulWidget {
  const _RecipeBuilderBody();

  @override
  State<_RecipeBuilderBody> createState() => _RecipeBuilderBodyState();
}

class _RecipeBuilderBodyState extends State<_RecipeBuilderBody> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    final state = context.read<RecipeBuilderBloc>().state;
    _nameController = TextEditingController(text: state.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<RecipeBuilderBloc, RecipeBuilderState>(
      listener: (context, state) {
        if (state.savedRecipe != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).recipeSavedLabel)),
          );
          Navigator.of(context).pop(state.savedRecipe);
        }
        if (state.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.error!)),
          );
        }
      },
      builder: (context, state) {
        final bloc = context.read<RecipeBuilderBloc>();
        final isEditing = state.existingId != null;

        return Scaffold(
          appBar: AppBar(
            title: Text(isEditing
                ? S.of(context).editRecipeLabel
                : S.of(context).newRecipeLabel),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Name
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: S.of(context).recipeNameHint,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (v) => bloc.add(UpdateNameEvent(v)),
                    ),
                    const SizedBox(height: 16),

                    // Servings
                    Row(
                      children: [
                        Text(S.of(context).servingsLabel,
                            style: theme.textTheme.titleSmall),
                        const Spacer(),
                        IconButton(
                          onPressed: state.servings > 0.5
                              ? () => bloc.add(UpdateServingsEvent(
                                  state.servings - 0.5))
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          state.servings % 1 == 0
                              ? state.servings.toInt().toString()
                              : state.servings.toStringAsFixed(1),
                          style: theme.textTheme.titleMedium,
                        ),
                        IconButton(
                          onPressed: () => bloc.add(
                              UpdateServingsEvent(state.servings + 0.5)),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                    const Divider(),

                    // Ingredients header
                    Row(
                      children: [
                        Text(S.of(context).ingredientsLabel,
                            style: theme.textTheme.titleSmall),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () => _addIngredient(context),
                          icon: const Icon(Icons.add, size: 18),
                          label: Text(S.of(context).addIngredientLabel),
                        ),
                      ],
                    ),

                    if (state.ingredients.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            S.of(context).noIngredientsLabel,
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),

                    // Ingredient list
                    ...List.generate(state.ingredients.length, (index) {
                      final ing = state.ingredients[index];
                      return _IngredientTile(
                        ingredient: ing,
                        onGramsChanged: (grams) => bloc
                            .add(UpdateIngredientGramsEvent(index, grams)),
                        onRemove: () =>
                            bloc.add(RemoveIngredientEvent(index)),
                      );
                    }),
                  ],
                ),
              ),

              // Sticky nutrition summary + save
              _NutritionSummaryBar(
                nutrition: state.perServingNutrition,
                canSave: state.canSave,
                isSaving: state.isSaving,
                onSave: () => bloc.add(SaveRecipeEvent()),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addIngredient(BuildContext context) async {
    final result = await showModalBottomSheet<RecipeIngredientEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const IngredientSearchSheet(),
    );
    if (result != null && mounted) {
      context.read<RecipeBuilderBloc>().add(AddIngredientEvent(result));
    }
  }
}

class _IngredientTile extends StatefulWidget {
  final RecipeIngredientEntity ingredient;
  final ValueChanged<double> onGramsChanged;
  final VoidCallback onRemove;

  const _IngredientTile({
    required this.ingredient,
    required this.onGramsChanged,
    required this.onRemove,
  });

  @override
  State<_IngredientTile> createState() => _IngredientTileState();
}

class _IngredientTileState extends State<_IngredientTile> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.ingredient.grams % 1 == 0
          ? widget.ingredient.grams.toInt().toString()
          : widget.ingredient.grams.toString(),
    );
  }

  @override
  void didUpdateWidget(_IngredientTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ingredient.grams != widget.ingredient.grams) {
      final text = widget.ingredient.grams % 1 == 0
          ? widget.ingredient.grams.toInt().toString()
          : widget.ingredient.grams.toString();
      if (_controller.text != text) {
        _controller.text = text;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final kcal =
        (widget.ingredient.kcalPer100 * widget.ingredient.grams / 100).round();
    return Dismissible(
      key: ValueKey(widget.ingredient.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => widget.onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: theme.colorScheme.errorContainer,
        child: Icon(Icons.delete, color: theme.colorScheme.onErrorContainer),
      ),
      child: ListTile(
        title: Text(widget.ingredient.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('$kcal kcal', style: theme.textTheme.bodySmall),
        trailing: SizedBox(
          width: 80,
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              suffixText: S.of(context).gramsShortLabel,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) {
              final grams = double.tryParse(v);
              if (grams != null && grams > 0) {
                widget.onGramsChanged(grams);
              }
            },
          ),
        ),
      ),
    );
  }
}

class _NutritionSummaryBar extends StatelessWidget {
  final dynamic nutrition;
  final bool canSave;
  final bool isSaving;
  final VoidCallback onSave;

  const _NutritionSummaryBar({
    required this.nutrition,
    required this.canSave,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(S.of(context).perServingLabel,
                      style: theme.textTheme.labelMedium),
                  _NutritionChip(
                      '${(nutrition.kcal as double).round()} kcal', theme),
                  _NutritionChip(
                      'P ${(nutrition.protein as double).round()}g', theme),
                  _NutritionChip(
                      'C ${(nutrition.carbs as double).round()}g', theme),
                  _NutritionChip(
                      'F ${(nutrition.fat as double).round()}g', theme),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: canSave && !isSaving ? onSave : null,
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(S.of(context).saveRecipeLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionChip extends StatelessWidget {
  final String label;
  final ThemeData theme;

  const _NutritionChip(this.label, this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: theme.textTheme.labelSmall),
    );
  }
}
