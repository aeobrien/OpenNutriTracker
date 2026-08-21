import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/household/presentation/whose_day_is_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// What the edit dialog was asked to change.
///
/// The correction and whose day it is come back together rather than one at a
/// time. They are noticed at the same moment and they save at the same moment:
/// a move that landed without its corrected figure would leave two people's
/// totals wrong with nothing to say so.
///
/// Which fields are filled in depends on what kind of row was tapped. A row
/// with a food behind it comes back as an [amount], because everything else
/// follows from the food's own figures. A row with no food behind it — anything
/// spoken, anything quick-added — has no figures to follow, so it comes back as
/// what it should be called and what it came to.
class IntakeEdit {
  /// In metric, as the rest of the app holds it. Null for a row with no food
  /// behind it, where an amount on its own would mean nothing.
  final double? amount;

  /// What the row should be called, when that is what was corrected.
  final String? label;

  /// What the row came to, when that is what was corrected.
  final double? kcal;

  /// Who to move it to, or null to leave it where it is.
  final int? moveTo;

  /// Whether what was asked for is that the row goes away entirely.
  ///
  /// Removing used to be a sideways swipe on the card. The strip of a meal's
  /// items scrolls sideways too, so the two fought and the swipe always won —
  /// which is why removing is asked for here by name now, alongside the
  /// corrections, rather than by a gesture nobody could aim.
  final bool remove;

  const IntakeEdit(
    this.amount, {
    this.label,
    this.kcal,
    this.moveTo,
    this.remove = false,
  });

  /// The correction as the diary takes it. Only the fields actually corrected
  /// are present, so a row is never quietly rewritten in a way nobody asked
  /// for.
  Map<String, dynamic> get fields => {
    if (amount != null) 'amount': amount,
    if (label != null) 'label': label,
    if (kcal != null) 'kcal': kcal,
  };
}

class EditDialog extends StatefulWidget {
  final IntakeEntity intakeEntity;
  final bool usesImperialUnits;

  const EditDialog({
    super.key,
    required this.intakeEntity,
    required this.usesImperialUnits,
  });

  @override
  State<StatefulWidget> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController amountEditingController;

  /// Only for a row with no food behind it — see [_hasNoFoodBehindIt].
  late TextEditingController nameEditingController;
  late TextEditingController kcalEditingController;

  late double _currentKcalEstimate;
  HouseholdPerson? _moveTo;

  /// Whether this is a row the amount cannot speak for.
  ///
  /// A spoken row and a quick-added row both arrive as a name and a set of
  /// figures with nothing underneath them: there is no food, so there is no
  /// per-100g number, so "300g" of it is not a fact about anything. Those get
  /// asked what they should be called and what they came to instead.
  bool get _hasNoFoodBehindIt => widget.intakeEntity.isQuickAdd;

  @override
  void initState() {
    super.initState();
    double initialAmount = _convertValue(
      widget.intakeEntity.amount,
      widget.intakeEntity.meal.mealUnit,
    );
    amountEditingController = TextEditingController(
      text: initialAmount.toStringAsFixed(2),
    );
    nameEditingController = TextEditingController(
      text: widget.intakeEntity.quickAddLabel ?? '',
    );
    kcalEditingController = TextEditingController(
      text: widget.intakeEntity.totalKcal.round().toString(),
    );
    _currentKcalEstimate = _hasNoFoodBehindIt
        ? widget.intakeEntity.totalKcal
        : _calculateKcal(widget.intakeEntity.amount);

    // Pre-select text for easy replacement
    amountEditingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: amountEditingController.text.length,
    );
    kcalEditingController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: kcalEditingController.text.length,
    );

    amountEditingController.addListener(_onAmountChanged);
    kcalEditingController.addListener(_onKcalChanged);
  }

  @override
  void dispose() {
    amountEditingController.removeListener(_onAmountChanged);
    amountEditingController.dispose();
    kcalEditingController.removeListener(_onKcalChanged);
    kcalEditingController.dispose();
    nameEditingController.dispose();
    super.dispose();
  }

  void _onKcalChanged() {
    final parsed = double.tryParse(kcalEditingController.text);
    if (parsed != null) setState(() => _currentKcalEstimate = parsed);
  }

  void _onAmountChanged() {
    final parsed = double.tryParse(amountEditingController.text);
    if (parsed != null) {
      final metricAmount = _convertBackToMetricValue(
        parsed,
        widget.intakeEntity.meal.mealUnit,
      );
      setState(() {
        _currentKcalEstimate = _calculateKcal(metricAmount);
      });
    }
  }

  double _calculateKcal(double metricAmount) {
    return metricAmount *
        (widget.intakeEntity.meal.nutriments.energyPerUnit ?? 0);
  }

  void _changeAmount(double delta) {
    final current = double.tryParse(amountEditingController.text) ?? 0.0;
    final displayDelta = widget.usesImperialUnits
        ? _convertValue(delta, widget.intakeEntity.meal.mealUnit) -
              _convertValue(0, widget.intakeEntity.meal.mealUnit)
        : delta;
    final newVal = (current + displayDelta).clamp(0.0, double.infinity);
    amountEditingController.text = newVal.toStringAsFixed(2);
  }

  void _setAmount(double metricValue) {
    final displayValue = _convertValue(
      metricValue,
      widget.intakeEntity.meal.mealUnit,
    );
    amountEditingController.text = displayValue.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final unitStr = _convertUnit(widget.intakeEntity.meal.mealUnit ?? '');
    final isLiquid = widget.intakeEntity.meal.isLiquid;
    final unitLabel = isLiquid ? 'ml' : 'g';
    final hasServing =
        widget.intakeEntity.meal.hasServingValues &&
        widget.intakeEntity.meal.servingQuantity != null;

    return AlertDialog(
      title: Text(S.of(context).editItemDialogTitle),
      content: SingleChildScrollView(
        child: _hasNoFoodBehindIt
            ? _foodlessRow(context)
            : _rowWithAFoodBehindIt(context, unitStr, unitLabel, hasServing),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const IntakeEdit(null, remove: true)),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: Text(S.of(context).dialogDeleteLabel),
        ),
        TextButton(onPressed: _save, child: Text(S.of(context).dialogOKLabel)),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
      ],
    );
  }

  /// The correction, as one thing, once. See [IntakeEdit].
  void _save() {
    if (_hasNoFoodBehindIt) {
      final name = nameEditingController.text.trim();
      Navigator.of(context).pop(
        IntakeEdit(
          null,
          label: name.isEmpty ? null : name,
          kcal: double.tryParse(kcalEditingController.text.trim()),
          moveTo: _moveTo?.id,
        ),
      );
      return;
    }
    final newAmount = double.tryParse(amountEditingController.text);
    if (newAmount == null) return;
    Navigator.of(context).pop(
      IntakeEdit(
        _convertBackToMetricValue(newAmount, widget.intakeEntity.meal.mealUnit),
        moveTo: _moveTo?.id,
      ),
    );
  }

  /// A row with nothing underneath it: what it is called, what it came to, and
  /// whose day it is. Plus, when somebody spoke it, the sentence the house was
  /// working from — which is the only way to tell a wrong guess from a wrong
  /// hearing.
  Widget _foodlessRow(BuildContext context) {
    final said = widget.intakeEntity.said;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (said != null && said.trim().isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'You said: "${said.trim()}"',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
        ],
        TextFormField(
          controller: nameEditingController,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'What it was'),
        ),
        const SizedBox(height: 8.0),
        TextFormField(
          controller: kcalEditingController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Calories',
            suffixText: 'kcal',
          ),
        ),
        const SizedBox(height: 4.0),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'The protein, fat and carbs move with the calories.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        const SizedBox(height: 8.0),
        WhoseDayIsIt(onChanged: (person) => _moveTo = person),
      ],
    );
  }

  Widget _rowWithAFoodBehindIt(
    BuildContext context,
    String unitStr,
    String unitLabel,
    bool hasServing,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: amountEditingController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: S.of(context).quantityLabel,
            suffixText: unitStr,
          ),
        ),
        const SizedBox(height: 8.0),
        Wrap(
          spacing: 8.0,
          runSpacing: 4.0,
          children: [
            ActionChip(
              label: Text('+10$unitLabel'),
              onPressed: () => _changeAmount(10),
            ),
            ActionChip(
              label: Text('+50$unitLabel'),
              onPressed: () => _changeAmount(50),
            ),
            if (hasServing) ...[
              ActionChip(
                label: const Text('\u00BD srv'),
                onPressed: () =>
                    _setAmount(widget.intakeEntity.meal.servingQuantity! * 0.5),
              ),
              ActionChip(
                label: const Text('1 srv'),
                onPressed: () =>
                    _setAmount(widget.intakeEntity.meal.servingQuantity!),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8.0),
        WhoseDayIsIt(onChanged: (person) => _moveTo = person),
        const SizedBox(height: 8.0),
        Figures.kcalText(
          context,
          _currentKcalEstimate,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  double _convertValue(double value, String? unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? UnitCalc.gToOz(value) : value;
      case 'ml':
        return widget.usesImperialUnits ? UnitCalc.mlToFlOz(value) : value;
      default:
        return value;
    }
  }

  double _convertBackToMetricValue(double value, String? unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? UnitCalc.ozToG(value) : value;
      case 'ml':
        return widget.usesImperialUnits ? UnitCalc.flOzToMl(value) : value;
      default:
        return value;
    }
  }

  String _convertUnit(String unit) {
    switch (unit) {
      case 'g':
        return widget.usesImperialUnits ? 'oz' : 'g';
      case 'ml':
        return widget.usesImperialUnits ? 'fl.oz' : 'ml';
      default:
        return unit;
    }
  }
}
