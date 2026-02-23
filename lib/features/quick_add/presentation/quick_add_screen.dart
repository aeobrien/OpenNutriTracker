import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/meal_slot_calc.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/quick_add/presentation/quick_add_screen_arguments.dart';
import 'package:opennutritracker/generated/l10n.dart';

class QuickAddScreen extends StatefulWidget {
  const QuickAddScreen({super.key});

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen> {
  final _log = Logger('QuickAddScreen');
  final _kcalController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _labelController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  late String _selectedSlot;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedSlot = MealSlotCalc.suggestSlot(DateTime.now());
  }

  @override
  void dispose() {
    _kcalController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _labelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments
        as QuickAddScreenArguments?;
    final day = args?.day ?? DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).quickAddLabel),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Calories field — prominent
            TextFormField(
              controller: _kcalController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              style: Theme.of(context).textTheme.headlineMedium,
              decoration: InputDecoration(
                labelText: S.of(context).quickAddCaloriesHint,
                suffixText: 'kcal',
                border: const OutlineInputBorder(),
              ),
              validator: (value) {
                final v = double.tryParse(value?.replaceAll(',', '.') ?? '');
                if (v == null || v <= 0) {
                  return S.of(context).quickAddCaloriesHint;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Optional macros row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Carbs',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Fat',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Label field
            TextField(
              controller: _labelController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: S.of(context).quickAddLabelHint,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.label_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Meal slot selector
            SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'breakfast',
                  label: Text(S.of(context).breakfastLabel),
                ),
                ButtonSegment(
                  value: 'lunch',
                  label: Text(S.of(context).lunchLabel),
                ),
                ButtonSegment(
                  value: 'dinner',
                  label: Text(S.of(context).dinnerLabel),
                ),
                ButtonSegment(
                  value: 'snack',
                  label: Text(S.of(context).snackLabel),
                ),
              ],
              selected: {_selectedSlot},
              onSelectionChanged: (set) {
                setState(() => _selectedSlot = set.first);
              },
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(day),
              icon: const Icon(Icons.bolt),
              label: Text(S.of(context).buttonSaveLabel),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(DateTime day) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final kcal =
          double.parse(_kcalController.text.replaceAll(',', '.'));
      final protein =
          double.tryParse(_proteinController.text.replaceAll(',', '.')) ?? 0.0;
      final carbs =
          double.tryParse(_carbsController.text.replaceAll(',', '.')) ?? 0.0;
      final fat =
          double.tryParse(_fatController.text.replaceAll(',', '.')) ?? 0.0;
      final label =
          _labelController.text.trim().isEmpty ? null : _labelController.text.trim();

      final intakeRepo = locator<IntakeRepository>();
      final addTrackedDay = locator<AddTrackedDayUsecase>();
      final getKcalGoal = locator<GetKcalGoalUsecase>();
      final getMacroGoal = locator<GetMacroGoalUsecase>();

      final intake = await intakeRepo.addQuickAddIntake(
        id: IdGenerator.getUniqueID(),
        kcal: kcal,
        protein: protein,
        carbs: carbs,
        fat: fat,
        label: label,
        mealSlot: _selectedSlot,
        dateTime: day,
      );

      // Update daily_stats (same pattern as MealDetailBloc._updateTrackedDay)
      final hasTrackedDay = await addTrackedDay.hasTrackedDay(day);
      if (!hasTrackedDay) {
        final totalKcalGoal = await getKcalGoal.getKcalGoal();
        final totalCarbsGoal =
            await getMacroGoal.getCarbsGoal(totalKcalGoal);
        final totalFatGoal = await getMacroGoal.getFatsGoal(totalKcalGoal);
        final totalProteinGoal =
            await getMacroGoal.getProteinsGoal(totalKcalGoal);
        await addTrackedDay.addNewTrackedDay(
            day, totalKcalGoal, totalCarbsGoal, totalFatGoal, totalProteinGoal);
      }

      await addTrackedDay.addDayCaloriesTracked(day, intake.totalKcal);
      await addTrackedDay.addDayMacrosTracked(day,
          carbsTracked: intake.totalCarbsGram,
          fatTracked: intake.totalFatsGram,
          proteinTracked: intake.totalProteinsGram);

      _log.fine('Quick-add saved: $kcal kcal, slot=$_selectedSlot');

      if (mounted) {
        locator<HomeBloc>().add(LoadItemsEvent());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).quickAddSaved)),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      _log.severe('Error saving quick-add', e);
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
