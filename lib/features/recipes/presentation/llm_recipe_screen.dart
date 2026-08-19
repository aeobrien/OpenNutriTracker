import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/core/domain/entity/recipe_ingredient_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/label_scan/presentation/label_scan_screen_arguments.dart';
import 'package:opennutritracker/features/recipes/domain/usecase/resolve_ingredients_usecase.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/llm_recipe_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/widgets/ingredient_search_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

class LlmRecipeScreen extends StatelessWidget {
  const LlmRecipeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<LlmRecipeBloc>(),
      child: const _LlmRecipeBody(),
    );
  }
}

class _LlmRecipeBody extends StatefulWidget {
  const _LlmRecipeBody();

  @override
  State<_LlmRecipeBody> createState() => _LlmRecipeBodyState();
}

class _LlmRecipeBodyState extends State<_LlmRecipeBody> {
  final _textController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _searchForIngredient(BuildContext context,
      LlmRecipeBloc bloc, int index, ResolvedIngredient ingredient) async {
    final result = await showModalBottomSheet<RecipeIngredientEntity>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const IngredientSearchSheet(),
    );
    if (result != null && mounted) {
      bloc.add(ReplaceIngredientEvent(
        index: index,
        name: result.name,
        foodItemId: result.foodItemId,
        kcalPer100: result.kcalPer100,
        proteinPer100: result.proteinPer100,
        carbsPer100: result.carbsPer100,
        fatPer100: result.fatPer100,
        matchStatus: MatchStatus.matched,
      ));
    }
  }

  Future<void> _scanForIngredient(BuildContext context,
      LlmRecipeBloc bloc, int index, ResolvedIngredient ingredient) async {
    final result = await Navigator.of(context).pushNamed(
      NavigationOptions.labelScanRoute,
      arguments: LabelScanScreenArguments(
        day: DateTime.now(),
        ingredientMode: true,
      ),
    );
    if (result is LabelScanIngredientResult && mounted) {
      bloc.add(ReplaceIngredientEvent(
        index: index,
        name: result.name,
        foodItemId: result.foodItemId,
        kcalPer100: result.kcalPer100,
        proteinPer100: result.proteinPer100,
        carbsPer100: result.carbsPer100,
        fatPer100: result.fatPer100,
        matchStatus: MatchStatus.matched,
      ));
    }
  }

  Future<void> _manualEntryForIngredient(BuildContext context,
      LlmRecipeBloc bloc, int index, ResolvedIngredient ingredient) async {
    final result = await showDialog<_ManualNutritionResult>(
      context: context,
      builder: (ctx) => _ManualNutritionDialog(ingredientName: ingredient.name),
    );
    if (result != null && mounted) {
      bloc.add(ReplaceIngredientEvent(
        index: index,
        name: ingredient.name,
        kcalPer100: result.kcalPer100,
        proteinPer100: result.proteinPer100,
        carbsPer100: result.carbsPer100,
        fatPer100: result.fatPer100,
        matchStatus: MatchStatus.matched,
      ));
    }
  }

  bool _looksLikeUrl(String text) {
    final trimmed = text.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<LlmRecipeBloc, LlmRecipeState>(
      listener: (context, state) {
        if (state is LlmRecipeSavedState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).recipeSavedLabel)),
          );
          Navigator.of(context).pop();
        }
        if (state is LlmRecipeErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
        if (state is LlmRecipeResolvedState) {
          _nameController.text = state.recipeName;
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).createFromTextLabel),
          ),
          body: _buildBody(context, state, theme),
        );
      },
    );
  }

  Widget _buildBody(
      BuildContext context, LlmRecipeState state, ThemeData theme) {
    if (state is LlmRecipeParsingState) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(S.of(context).parsingLabel),
          ],
        ),
      );
    }

    if (state is LlmRecipeResolvedState) {
      return _buildResolvedView(context, state, theme);
    }

    // Initial state — input view
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                hintText: S.of(context).pasteIngredientsHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final text = _textController.text.trim();
              if (text.isEmpty) return;
              final bloc = context.read<LlmRecipeBloc>();
              if (_looksLikeUrl(text)) {
                bloc.add(ParseUrlEvent(text));
              } else {
                bloc.add(ParseTextEvent(text));
              }
            },
            child: Text(S.of(context).parseLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedView(
      BuildContext context, LlmRecipeResolvedState state, ThemeData theme) {
    final bloc = context.read<LlmRecipeBloc>();
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Recipe name
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: S.of(context).recipeNameHint,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (v) => bloc.add(UpdateResolvedNameEvent(v)),
              ),
              const SizedBox(height: 12),

              // Servings
              Row(
                children: [
                  Text(S.of(context).servingsLabel,
                      style: theme.textTheme.titleSmall),
                  const Spacer(),
                  IconButton(
                    onPressed: state.servings > 0.5
                        ? () => bloc.add(UpdateResolvedServingsEvent(
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
                        UpdateResolvedServingsEvent(state.servings + 0.5)),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ],
              ),
              const Divider(),

              // Ingredients
              Text(S.of(context).ingredientsLabel,
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),

              ...List.generate(state.resolvedIngredients.length, (index) {
                final ing = state.resolvedIngredients[index];
                return _ResolvedIngredientTile(
                  ingredient: ing,
                  onGramsChanged: (grams) =>
                      bloc.add(UpdateResolvedGramsEvent(index, grams)),
                  onSearch: () => _searchForIngredient(context, bloc, index, ing),
                  onScan: () => _scanForIngredient(context, bloc, index, ing),
                  onManualEntry: () => _manualEntryForIngredient(context, bloc, index, ing),
                );
              }),
            ],
          ),
        ),

        // Bottom bar
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(S.of(context).perServingLabel,
                          style: theme.textTheme.labelMedium),
                      Figures.kcalText(
                          context, state.perServingNutrition.kcal),
                      Text(
                          'P ${state.perServingNutrition.protein.round()}g'),
                      Text('C ${state.perServingNutrition.carbs.round()}g'),
                      Text('F ${state.perServingNutrition.fat.round()}g'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => bloc.add(SaveLlmRecipeEvent()),
                      child: Text(S.of(context).saveRecipeLabel),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ResolvedIngredientTile extends StatelessWidget {
  final ResolvedIngredient ingredient;
  final ValueChanged<double> onGramsChanged;
  final VoidCallback onSearch;
  final VoidCallback onScan;
  final VoidCallback onManualEntry;

  const _ResolvedIngredientTile({
    required this.ingredient,
    required this.onGramsChanged,
    required this.onSearch,
    required this.onScan,
    required this.onManualEntry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (ingredient.matchStatus) {
      MatchStatus.matched => Colors.green,
      MatchStatus.suggested => Colors.amber,
      MatchStatus.unresolved => theme.colorScheme.error,
    };
    final statusLabel = switch (ingredient.matchStatus) {
      MatchStatus.matched => S.of(context).resolvedLabel,
      MatchStatus.suggested => S.of(context).suggestedLabel,
      MatchStatus.unresolved => S.of(context).unresolvedLabel,
    };
    final needsFix = ingredient.matchStatus != MatchStatus.matched;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(statusLabel,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: statusColor)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(ingredient.name,
                      style: theme.textTheme.bodyMedium),
                ),
                SizedBox(
                  width: 80,
                  child: TextFormField(
                    initialValue: ingredient.grams % 1 == 0
                        ? ingredient.grams.toInt().toString()
                        : ingredient.grams.toString(),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      suffixText: S.of(context).gramsShortLabel,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) {
                      final grams = double.tryParse(v);
                      if (grams != null && grams > 0) {
                        onGramsChanged(grams);
                      }
                    },
                  ),
                ),
              ],
            ),
            if (ingredient.originalText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  ingredient.originalText,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
            if (ingredient.matchStatus != MatchStatus.matched ||
                ingredient.kcalPer100 == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    if (needsFix && !Figures.off(context))
                      Text(
                        Figures.per100(context, ingredient.kcalPer100) ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: ingredient.kcalPer100 == 0
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      onPressed: onSearch,
                      icon: const Icon(Icons.search, size: 20),
                      tooltip: S.of(context).searchLabel,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: onScan,
                      icon: const Icon(Icons.camera_alt, size: 20),
                      tooltip: S.of(context).scanLabel,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      onPressed: onManualEntry,
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: S.of(context).manualEntryLabel,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ManualNutritionResult {
  final double kcalPer100;
  final double proteinPer100;
  final double carbsPer100;
  final double fatPer100;

  _ManualNutritionResult({
    required this.kcalPer100,
    required this.proteinPer100,
    required this.carbsPer100,
    required this.fatPer100,
  });
}

class _ManualNutritionDialog extends StatefulWidget {
  final String ingredientName;

  const _ManualNutritionDialog({required this.ingredientName});

  @override
  State<_ManualNutritionDialog> createState() => _ManualNutritionDialogState();
}

class _ManualNutritionDialogState extends State<_ManualNutritionDialog> {
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void dispose() {
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.ingredientName),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(S.of(context).manualNutritionPer100gLabel,
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          _field(_kcalController, 'kcal'),
          const SizedBox(height: 8),
          _field(_proteinController, S.of(context).proteinLabel),
          const SizedBox(height: 8),
          _field(_carbsController, S.of(context).carbsLabel),
          const SizedBox(height: 8),
          _field(_fatController, S.of(context).fatLabel),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).dialogCancelLabel),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              _ManualNutritionResult(
                kcalPer100: double.tryParse(_kcalController.text) ?? 0,
                proteinPer100: double.tryParse(_proteinController.text) ?? 0,
                carbsPer100: double.tryParse(_carbsController.text) ?? 0,
                fatPer100: double.tryParse(_fatController.text) ?? 0,
              ),
            );
          },
          child: Text(S.of(context).confirmLabel),
        ),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        suffixText: label == 'kcal' ? '' : 'g',
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
