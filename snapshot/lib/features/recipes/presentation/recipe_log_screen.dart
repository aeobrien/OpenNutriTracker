import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/recipe_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/calc/meal_slot_calc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_log_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class RecipeLogScreen extends StatelessWidget {
  const RecipeLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recipe =
        ModalRoute.of(context)!.settings.arguments as RecipeEntity;

    return BlocProvider(
      create: (_) => RecipeLogBloc(locator(), locator(), locator())
        ..add(LoadRecipeEvent(recipe)),
      child: const _RecipeLogBody(),
    );
  }
}

class _RecipeLogBody extends StatefulWidget {
  const _RecipeLogBody();

  @override
  State<_RecipeLogBody> createState() => _RecipeLogBodyState();
}

class _RecipeLogBodyState extends State<_RecipeLogBody> {
  late IntakeTypeEntity _mealSlot;

  @override
  void initState() {
    super.initState();
    final suggested = MealSlotCalc.suggestSlot(DateTime.now());
    _mealSlot = IntakeTypeEntity.values.firstWhere(
      (e) => e.name == suggested,
      orElse: () => IntakeTypeEntity.snack,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<RecipeLogBloc, RecipeLogState>(
      listener: (context, state) {
        if (state is RecipeLogSavedState) {
          locator<HomeBloc>().add(const LoadItemsEvent());
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).recipeLoggedLabel)),
          );
          Navigator.of(context).pop();
        }
        if (state is RecipeLogErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      builder: (context, state) {
        if (state is! RecipeLogLoadedState) {
          return Scaffold(
            appBar: AppBar(title: Text(S.of(context).logRecipeLabel)),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final recipe = state.recipe;
        final nutrition = state.computedNutrition;
        final multiplier = state.multiplier;

        return Scaffold(
          appBar: AppBar(title: Text(S.of(context).logRecipeLabel)),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Recipe name
                Row(
                  children: [
                    Icon(Icons.restaurant_menu,
                        color: theme.colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(recipe.name,
                          style: theme.textTheme.headlineSmall),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${S.of(context).perServingLabel}: '
                  '${recipe.kcalPerServing.round()} kcal · '
                  'P ${recipe.proteinPerServing.round()}g · '
                  'C ${recipe.carbsPerServing.round()}g · '
                  'F ${recipe.fatPerServing.round()}g',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Serving multiplier
                Text(S.of(context).servingsLabel,
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<double>(
                  segments: const [
                    ButtonSegment(value: 0.5, label: Text('½')),
                    ButtonSegment(value: 1.0, label: Text('1')),
                    ButtonSegment(value: 1.5, label: Text('1½')),
                    ButtonSegment(value: 2.0, label: Text('2')),
                  ],
                  selected: {multiplier},
                  onSelectionChanged: (v) => context
                      .read<RecipeLogBloc>()
                      .add(UpdateMultiplierEvent(v.first)),
                ),
                const SizedBox(height: 24),

                // Computed nutrition
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).servingMultiplierLabel(
                              multiplier % 1 == 0
                                  ? multiplier.toInt().toString()
                                  : multiplier.toString()),
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: 8),
                        _NutritionRow('kcal', nutrition.kcal, theme),
                        _NutritionRow('Protein', nutrition.protein, theme),
                        _NutritionRow('Carbs', nutrition.carbs, theme),
                        _NutritionRow('Fat', nutrition.fat, theme),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Meal slot selector
                Text('Meal', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                SegmentedButton<IntakeTypeEntity>(
                  segments: IntakeTypeEntity.values
                      .map((slot) => ButtonSegment(
                            value: slot,
                            label: Text(_slotLabel(context, slot)),
                          ))
                      .toList(),
                  selected: {_mealSlot},
                  onSelectionChanged: (v) =>
                      setState(() => _mealSlot = v.first),
                ),

                const Spacer(),

                // Log button
                SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.read<RecipeLogBloc>().add(
                            LogRecipeEvent(
                              mealSlot: _mealSlot.name,
                              day: DateTime.now(),
                            ),
                          ),
                      child: Text(S.of(context).logRecipeLabel),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _slotLabel(BuildContext context, IntakeTypeEntity slot) {
    switch (slot) {
      case IntakeTypeEntity.breakfast:
        return S.of(context).breakfastLabel;
      case IntakeTypeEntity.lunch:
        return S.of(context).lunchLabel;
      case IntakeTypeEntity.dinner:
        return S.of(context).dinnerLabel;
      case IntakeTypeEntity.snack:
        return S.of(context).snackLabel;
    }
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final double value;
  final ThemeData theme;

  const _NutritionRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            label == 'kcal'
                ? '${value.round()}'
                : '${value.toStringAsFixed(1)}g',
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
