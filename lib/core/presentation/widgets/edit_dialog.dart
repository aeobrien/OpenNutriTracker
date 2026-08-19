import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/utils/calc/unit_calc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class EditDialog extends StatefulWidget {
  final IntakeEntity intakeEntity;
  final bool usesImperialUnits;

  const EditDialog(
      {super.key, required this.intakeEntity, required this.usesImperialUnits});

  @override
  State<StatefulWidget> createState() => _EditDialogState();
}

class _EditDialogState extends State<EditDialog> {
  late TextEditingController amountEditingController;
  late double _currentKcalEstimate;

  @override
  void initState() {
    super.initState();
    double initialAmount = _convertValue(
        widget.intakeEntity.amount, widget.intakeEntity.meal.mealUnit);
    amountEditingController =
        TextEditingController(text: initialAmount.toStringAsFixed(2));
    _currentKcalEstimate = _calculateKcal(widget.intakeEntity.amount);

    // Pre-select text for easy replacement
    amountEditingController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: amountEditingController.text.length);

    amountEditingController.addListener(_onAmountChanged);
  }

  @override
  void dispose() {
    amountEditingController.removeListener(_onAmountChanged);
    amountEditingController.dispose();
    super.dispose();
  }

  void _onAmountChanged() {
    final parsed = double.tryParse(amountEditingController.text);
    if (parsed != null) {
      final metricAmount = _convertBackToMetricValue(
          parsed, widget.intakeEntity.meal.mealUnit);
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
        metricValue, widget.intakeEntity.meal.mealUnit);
    amountEditingController.text = displayValue.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final unitStr = _convertUnit(widget.intakeEntity.meal.mealUnit ?? '');
    final isLiquid = widget.intakeEntity.meal.isLiquid;
    final unitLabel = isLiquid ? 'ml' : 'g';
    final hasServing = widget.intakeEntity.meal.hasServingValues &&
        widget.intakeEntity.meal.servingQuantity != null;

    return AlertDialog(
      title: Text(S.of(context).editItemDialogTitle),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextFormField(
          controller: amountEditingController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
              labelText: S.of(context).quantityLabel,
              suffixText: unitStr),
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
                onPressed: () => _setAmount(
                    widget.intakeEntity.meal.servingQuantity! * 0.5),
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
        Figures.kcalText(
          context,
          _currentKcalEstimate,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7)),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () {
              double newAmount = double.parse(amountEditingController.text);
              Navigator.of(context).pop(_convertBackToMetricValue(
                  newAmount, widget.intakeEntity.meal.mealUnit));
            },
            child: Text(S.of(context).dialogOKLabel)),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel))
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
