import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/meal_slot_calc.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/label_scan/presentation/bloc/label_scan_bloc.dart';
import 'package:opennutritracker/features/label_scan/presentation/label_scan_screen_arguments.dart';
import 'package:opennutritracker/generated/l10n.dart';

class LabelScanScreen extends StatefulWidget {
  const LabelScanScreen({super.key});

  @override
  State<LabelScanScreen> createState() => _LabelScanScreenState();
}

class _LabelScanScreenState extends State<LabelScanScreen> {
  final _log = Logger('LabelScanScreen');
  late LabelScanBloc _bloc;
  late String _selectedSlot;
  final _amountController = TextEditingController(text: '100');
  bool _saving = false;
  bool _optionalExpanded = false;
  bool _useServings = false;
  bool _amountInitialized = false;

  @override
  void initState() {
    super.initState();
    _bloc = locator<LabelScanBloc>();
    _selectedSlot = MealSlotCalc.suggestSlot(DateTime.now());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments
        as LabelScanScreenArguments?;
    if (args?.intakeType != null) {
      _selectedSlot = args!.intakeType!.name;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LabelScanBloc, LabelScanState>(
      bloc: _bloc,
      builder: (context, state) {
        // Auto-configure amount mode when results first arrive
        if (state is LabelScanResultState && !_amountInitialized) {
          _amountInitialized = true;
          final hasServing = state.result.servingSizeG != null &&
              state.result.servingSizeG! > 0;
          _useServings = hasServing;
          _amountController.text = hasServing ? '1' : '100';
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(S.of(context).scanLabelTitle),
            actions: [
              if (state is LabelScanResultState)
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined),
                  onPressed: () {
                    _amountInitialized = false;
                    _bloc.add(const CaptureAndExtractEvent());
                  },
                ),
            ],
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, LabelScanState state) {
    if (state is LabelScanInitialState) {
      return _buildInitialState(context);
    } else if (state is LabelScanProcessingState) {
      return _buildProcessingState(context);
    } else if (state is LabelScanResultState) {
      return _buildResultState(context, state);
    } else if (state is LabelScanErrorState) {
      return _buildErrorState(context, state);
    }
    return const SizedBox();
  }

  Widget _buildInitialState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _bloc.add(const CaptureAndExtractEvent()),
            icon: const Icon(Icons.camera_alt),
            label: Text(S.of(context).takePhoto),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(S.of(context).analyzingLabel),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, LabelScanErrorState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(state.message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 24),
            if (state.isApiKeyMissing)
              FilledButton.icon(
                onPressed: () => Navigator.of(context)
                    .pushNamed(NavigationOptions.settingsRoute),
                icon: const Icon(Icons.settings),
                label: Text(S.of(context).goToSettings),
              )
            else
              FilledButton.icon(
                onPressed: () =>
                    _bloc.add(const CaptureAndExtractEvent()),
                icon: const Icon(Icons.camera_alt),
                label: Text(S.of(context).takePhoto),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultState(BuildContext context, LabelScanResultState state) {
    final result = state.result;
    final hasServing =
        result.servingSizeG != null && result.servingSizeG! > 0;
    final servingLabel = result.servingUnit ?? S.of(context).servingLabel;

    return Form(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Name + Brand
          TextField(
            controller: TextEditingController(text: result.name ?? '')
              ..selection = TextSelection.collapsed(
                  offset: result.name?.length ?? 0),
            decoration: InputDecoration(
              labelText: S.of(context).mealNameLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) =>
                _bloc.add(UpdateFieldEvent('name', v)),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: TextEditingController(text: result.brand ?? '')
              ..selection = TextSelection.collapsed(
                  offset: result.brand?.length ?? 0),
            decoration: InputDecoration(
              labelText: S.of(context).mealBrandsLabel,
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) =>
                _bloc.add(UpdateFieldEvent('brand', v)),
          ),
          const SizedBox(height: 16),

          // Calories — prominent
          _buildNumericField(
            context,
            label: '${S.of(context).kcalLabel} ${S.of(context).per100gmlLabel}',
            value: result.caloriesPer100g,
            field: 'caloriesPer100g',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),

          // Macros row
          Row(
            children: [
              Expanded(
                child: _buildNumericField(context,
                    label: S.of(context).proteinLabel,
                    value: result.proteinPer100g,
                    field: 'proteinPer100g'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumericField(context,
                    label: S.of(context).carbsLabel,
                    value: result.carbsPer100g,
                    field: 'carbsPer100g'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildNumericField(context,
                    label: S.of(context).fatLabel,
                    value: result.fatPer100g,
                    field: 'fatPer100g'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Optional fields
          ExpansionTile(
            title: const Text('Optional details'),
            initiallyExpanded: _optionalExpanded,
            onExpansionChanged: (v) => _optionalExpanded = v,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildNumericField(context,
                          label: S.of(context).fiberLabel,
                          value: result.fiberPer100g ?? 0,
                          field: 'fiberPer100g'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildNumericField(context,
                          label: S.of(context).sugarLabel,
                          value: result.sugarPer100g ?? 0,
                          field: 'sugarPer100g'),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildNumericField(context,
                          label: S.of(context).saturatedFatLabel,
                          value: result.saturatedFatPer100g ?? 0,
                          field: 'saturatedFatPer100g'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: _buildNumericField(context,
                    label: S.of(context).servingSizeLabelMetric,
                    value: result.servingSizeG ?? 0,
                    field: 'servingSizeG'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Validation badge
          _buildValidationBadge(context, state.validation),
          const SizedBox(height: 4),

          // Confidence indicator
          _buildConfidenceBadge(context, result.confidence),
          const SizedBox(height: 16),

          // Meal slot selector
          SegmentedButton<String>(
            segments: [
              ButtonSegment(
                  value: 'breakfast',
                  label: Text(S.of(context).breakfastLabel)),
              ButtonSegment(
                  value: 'lunch', label: Text(S.of(context).lunchLabel)),
              ButtonSegment(
                  value: 'dinner',
                  label: Text(S.of(context).dinnerLabel)),
              ButtonSegment(
                  value: 'snack',
                  label: Text(S.of(context).snackLabel)),
            ],
            selected: {_selectedSlot},
            onSelectionChanged: (set) {
              setState(() => _selectedSlot = set.first);
            },
          ),
          const SizedBox(height: 12),

          // Amount field with g/serving toggle
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                  ],
                  decoration: InputDecoration(
                    labelText: S.of(context).quantityLabel,
                    border: const OutlineInputBorder(),
                    helperText: _useServings && hasServing
                        ? '1 $servingLabel \u2248 ${result.servingSizeG!.round()}g'
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 56,
                child: SegmentedButton<bool>(
                  segments: [
                    const ButtonSegment(value: false, label: Text('g')),
                    ButtonSegment(
                      value: true,
                      label: Text(servingLabel),
                      enabled: hasServing,
                    ),
                  ],
                  selected: {_useServings},
                  onSelectionChanged: hasServing
                      ? (set) {
                          setState(() {
                            final switching = set.first;
                            if (switching && !_useServings) {
                              // g → servings: convert current grams to servings
                              final grams = double.tryParse(
                                      _amountController.text
                                          .replaceAll(',', '.')) ??
                                  100;
                              final servings =
                                  grams / result.servingSizeG!;
                              _amountController.text = servings == 1.0
                                  ? '1'
                                  : servings.toStringAsFixed(1);
                            } else if (!switching && _useServings) {
                              // servings → g: convert current servings to grams
                              final servings = double.tryParse(
                                      _amountController.text
                                          .replaceAll(',', '.')) ??
                                  1;
                              final grams =
                                  (servings * result.servingSizeG!).round();
                              _amountController.text = grams.toString();
                            }
                            _useServings = switching;
                          });
                        }
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save button
          FilledButton.icon(
            onPressed: _saving ? null : () => _save(state),
            icon: const Icon(Icons.add),
            label: Text(S.of(context).addLabel),
          ),
        ],
      ),
    );
  }

  Widget _buildNumericField(
    BuildContext context, {
    required String label,
    required double value,
    required String field,
    TextStyle? style,
  }) {
    return TextField(
      controller: TextEditingController(
          text: value == value.roundToDouble()
              ? value.round().toString()
              : value.toStringAsFixed(1)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
      ],
      style: style,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: (v) => _bloc.add(UpdateFieldEvent(field, v)),
    );
  }

  Widget _buildValidationBadge(
      BuildContext context, ValidationResult validation) {
    IconData icon;
    Color color;
    String text;

    switch (validation.status) {
      case ValidationStatus.ok:
        icon = Icons.check_circle;
        color = Colors.green;
        text = S.of(context).valuesLookConsistent;
        break;
      case ValidationStatus.reviewRecommended:
        icon = Icons.info_outline;
        color = Colors.amber;
        text = S.of(context).valuesMayNeedReview(
            validation.deviationPct.round().toString());
        break;
      case ValidationStatus.likelyError:
        icon = Icons.warning_amber;
        color = Colors.amber;
        text = S.of(context).pleaseCheckValues(
            validation.deviationPct.round().toString());
        break;
    }

    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color)),
        ),
      ],
    );
  }

  Widget _buildConfidenceBadge(BuildContext context, String confidence) {
    final color = confidence == 'high'
        ? Colors.green
        : confidence == 'medium'
            ? Colors.amber
            : Colors.orange;

    return Row(
      children: [
        Icon(Icons.psychology, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          S.of(context).confidenceLabel(confidence),
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(color: color),
        ),
      ],
    );
  }

  Future<void> _save(LabelScanResultState state) async {
    setState(() => _saving = true);

    try {
      final args = ModalRoute.of(context)?.settings.arguments
          as LabelScanScreenArguments?;
      final isIngredientMode = args?.ingredientMode ?? false;
      final day = args?.day ?? DateTime.now();
      final meal = state.meal;

      // In ingredient mode: save food item to DB (for future local lookup)
      // then return nutrition data without creating a log entry.
      if (isIngredientMode) {
        final intakeRepo = locator<IntakeRepository>();
        // Upsert the food item so it's available locally going forward
        final foodItemId = await intakeRepo.saveFoodItemOnly(meal);

        _log.fine('Label scan ingredient saved: ${meal.name}');

        if (mounted) {
          Navigator.of(context).pop(LabelScanIngredientResult(
            name: meal.name ?? 'Unknown',
            foodItemId: foodItemId,
            kcalPer100: meal.nutriments.energyKcal100 ?? 0,
            proteinPer100: meal.nutriments.proteins100 ?? 0,
            carbsPer100: meal.nutriments.carbohydrates100 ?? 0,
            fatPer100: meal.nutriments.fat100 ?? 0,
          ));
        }
        return;
      }

      final rawAmount =
          double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 100;

      // Convert servings to grams if needed
      final amount = _useServings &&
              state.result.servingSizeG != null &&
              state.result.servingSizeG! > 0
          ? rawAmount * state.result.servingSizeG!
          : rawAmount;

      final intakeType = IntakeTypeEntity.values.firstWhere(
          (e) => e.name == _selectedSlot,
          orElse: () => IntakeTypeEntity.snack);

      final intakeEntity = IntakeEntity(
        id: IdGenerator.getUniqueID(),
        unit: 'g/ml',
        amount: amount,
        type: intakeType,
        meal: meal,
        dateTime: day,
      );

      final intakeRepo = locator<IntakeRepository>();
      await intakeRepo.addIntake(intakeEntity);

      // Update daily stats
      final addTrackedDay = locator<AddTrackedDayUsecase>();
      final getKcalGoal = locator<GetKcalGoalUsecase>();
      final getMacroGoal = locator<GetMacroGoalUsecase>();

      final hasTrackedDay = await addTrackedDay.hasTrackedDay(day);
      if (!hasTrackedDay) {
        final totalKcalGoal = await getKcalGoal.getKcalGoal();
        final totalCarbsGoal =
            await getMacroGoal.getCarbsGoal(totalKcalGoal);
        final totalFatGoal = await getMacroGoal.getFatsGoal(totalKcalGoal);
        final totalProteinGoal =
            await getMacroGoal.getProteinsGoal(totalKcalGoal);
        await addTrackedDay.addNewTrackedDay(day, totalKcalGoal,
            totalCarbsGoal, totalFatGoal, totalProteinGoal);
      }

      await addTrackedDay.addDayCaloriesTracked(day, intakeEntity.totalKcal);
      await addTrackedDay.addDayMacrosTracked(day,
          carbsTracked: intakeEntity.totalCarbsGram,
          fatTracked: intakeEntity.totalFatsGram,
          proteinTracked: intakeEntity.totalProteinsGram);

      _log.fine('Label scan saved: ${meal.name}, ${intakeEntity.totalKcal} kcal');

      if (mounted) {
        locator<HomeBloc>().add(LoadItemsEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).labelScanSaved)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _log.severe('Error saving label scan', e);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
