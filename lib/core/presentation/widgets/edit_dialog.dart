import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/household/presentation/this_entrys_history.dart';
import 'package:opennutritracker/features/household/presentation/whose_day_is_it.dart';
import 'package:opennutritracker/features/household/domain/what_it_was.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
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

  /// Which meal of the day it should be under, or null to leave it where it
  /// is. One of breakfast / lunch / dinner / snack — the same four names the
  /// Mac Mini uses, so nothing has to be translated on the way.
  final String? slot;

  /// The food this row should be of instead, or null to leave it as it is.
  ///
  /// Not one of [fields] — it is not a figure to be written over one, it is
  /// the thing every figure is worked out from. Everything else in this class
  /// says what the row should say; this says what the row *is*.
  final MealEntity? nowItIs;

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
    this.slot,
    this.nowItIs,
    this.remove = false,
  });

  /// The correction as the diary takes it. Only the fields actually corrected
  /// are present, so a row is never quietly rewritten in a way nobody asked
  /// for.
  Map<String, dynamic> get fields => {
    if (amount != null) 'amount': amount,
    if (label != null) 'label': label,
    if (kcal != null) 'kcal': kcal,
    if (slot != null) 'slot': slot,
  };
}

class EditDialog extends StatefulWidget {
  /// What the meal-of-the-day control is called on screen. Named here so the
  /// test that finds it and the dialog that draws it cannot drift apart.
  static const whichMealLabel = 'Which meal';

  /// What the offer to swap the food is called on screen.
  static const changeTheFoodLabel = 'Change the food';

  final IntakeEntity intakeEntity;
  final bool usesImperialUnits;

  /// Whose day this row is on at the moment, when the house has said. Only so
  /// that putting an older version back knows whether it is also a move.
  final int? currentOwner;

  /// Only so a test can hand in a ledger for the history panel. The running
  /// app leaves it null and the panel fetches its own.
  final FoodLedger? ledger;

  /// BC-0026's one refusal, in the person's own terms.
  static String cannotMoveOnto(String name) =>
      'The other half of this meal is already on $name\'s day. Moving this '
      'half there would count one dinner twice against them and leave nobody '
      'with the other half.';

  static const notReallySharedLabel = 'Delete it instead';
  static const leaveItLabel = 'Leave it as it is';

  const EditDialog({
    super.key,
    required this.intakeEntity,
    required this.usesImperialUnits,
    this.currentOwner,
    this.ledger,
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

  /// The food to put behind the row instead, once one has been chosen. Null
  /// for the overwhelmingly common case, where the row is of the right thing
  /// and only the amount was wrong.
  MealEntity? _instead;

  /// Which meal of the day the row is under, as the control currently shows
  /// it. Starts on the one it is already under, so opening the dialog and
  /// saving without touching this changes nothing — see [_save].
  late IntakeTypeEntity _slot;

  /// Whether this is a row the amount cannot speak for.
  ///
  /// A spoken row and a quick-added row both arrive as a name and a set of
  /// figures with nothing underneath them: there is no food, so there is no
  /// per-100g number, so "300g" of it is not a fact about anything. Those get
  /// asked what they should be called and what they came to instead.
  bool get _hasNoFoodBehindIt => widget.intakeEntity.isQuickAdd;

  /// A recipe row takes the shape above — it has an amount and a unit — but
  /// what it is *of* is a recipe, not a food, and its amount is a number of
  /// servings of that recipe. There is no food there to replace, so it is not
  /// offered: an offer that can only end in a refusal is worse than no offer.
  bool get _theFoodCanBeChanged =>
      !widget.intakeEntity.isQuickAdd && !widget.intakeEntity.isRecipe;

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
    _slot = widget.intakeEntity.type;
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
      final metricAmount = _convertBackToMetricValue(parsed, _food.mealUnit);
      setState(() {
        _currentKcalEstimate = _calculateKcal(metricAmount);
      });
    }
  }

  /// What the row is of, as the dialog currently stands — which is not
  /// necessarily what it arrived as. Every figure and every unit on this
  /// screen comes from here, so choosing a different food changes the
  /// calories under the amount box before anything is saved.
  MealEntity get _food => _instead ?? widget.intakeEntity.meal;

  double _calculateKcal(double metricAmount) {
    return metricAmount * (_food.nutriments.energyPerUnit ?? 0);
  }

  void _changeAmount(double delta) {
    final current = double.tryParse(amountEditingController.text) ?? 0.0;
    final displayDelta = widget.usesImperialUnits
        ? _convertValue(delta, _food.mealUnit) -
              _convertValue(0, _food.mealUnit)
        : delta;
    final newVal = (current + displayDelta).clamp(0.0, double.infinity);
    amountEditingController.text = newVal.toStringAsFixed(2);
  }

  void _setAmount(double metricValue) {
    final displayValue = _convertValue(metricValue, _food.mealUnit);
    amountEditingController.text = displayValue.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final unitStr = _convertUnit(_food.mealUnit ?? '');
    final isLiquid = _food.isLiquid;
    final unitLabel = isLiquid ? 'ml' : 'g';
    final hasServing =
        _food.hasServingValues && _food.servingQuantity != null;

    return AlertDialog(
      title: Text(S.of(context).editItemDialogTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _hasNoFoodBehindIt
                ? _foodlessRow(context)
                : _rowWithAFoodBehindIt(
                    context, unitStr, unitLabel, hasServing),
            // Under both shapes, for the same reason: a breakfast eaten late
            // and a snack that was really lunch are the same mistake whether
            // or not there is a food behind the row.
            _whichMealOfTheDay(context),
            // Under both shapes of the dialog, because a row with a food
            // behind it and a row without one are corrected just as often and
            // wrongly just as often.
            ThisEntrysHistory(
              intakeId: widget.intakeEntity.id,
              ledger: widget.ledger,
              onPutBack: _putBack,
            ),
          ],
        ),
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

  /// Which meal of the day this row is under.
  ///
  /// The Mac Mini has accepted a corrected slot since the day it could accept
  /// a correction at all; this is the control that was missing, not the
  /// ability. Until now a lunch logged under dinner could only be removed and
  /// logged again, which loses when it was eaten and who entered it.
  ///
  /// It starts on the slot the row already has rather than on nothing, so it
  /// reads as a statement of where the row is — and saving without touching it
  /// sends no slot at all.
  Widget _whichMealOfTheDay(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: DropdownButtonFormField<IntakeTypeEntity>(
        initialValue: _slot,
        decoration: const InputDecoration(labelText: EditDialog.whichMealLabel),
        items: [
          for (final slot in IntakeTypeEntity.values)
            DropdownMenuItem(value: slot, child: Text(_nameOf(slot))),
        ],
        onChanged: (chosen) {
          if (chosen != null) setState(() => _slot = chosen);
        },
      ),
    );
  }

  /// What each meal of the day is called on screen. Capitalised here rather
  /// than shown as the enum spells it, because 'breakfast' in a dropdown reads
  /// like a value out of a database.
  static String _nameOf(IntakeTypeEntity slot) {
    switch (slot) {
      case IntakeTypeEntity.breakfast:
        return 'Breakfast';
      case IntakeTypeEntity.lunch:
        return 'Lunch';
      case IntakeTypeEntity.dinner:
        return 'Dinner';
      case IntakeTypeEntity.snack:
        return 'Snack';
    }
  }

  /// Only sent when it actually changed. See [_save].
  String? get _slotIfMoved =>
      _slot == widget.intakeEntity.type ? null : _slot.name;

  /// What the row is of, and the way to say it was something else.
  ///
  /// Only on the shape of the dialog that has a food behind it. A spoken or
  /// quick-added row has no food to replace — it is corrected by what it was
  /// called and what it came to, which is what that shape already asks.
  ///
  /// Choosing here does not save anything. The amount stays where it is and
  /// every figure on this screen is worked out again from the new food, so the
  /// calories under the box move before OK is pressed — which is the only way
  /// somebody can tell whether the food they picked is the one they meant.
  Widget _whatItIs(BuildContext context) {
    final quieter = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        );
    return Row(
      children: [
        Expanded(
          child: Text(
            _instead == null
                ? (_food.name ?? '')
                : 'Now: ${_food.name ?? ''}',
            style: quieter,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        TextButton(
          onPressed: _chooseAnotherFood,
          child: const Text(EditDialog.changeTheFoodLabel),
        ),
      ],
    );
  }

  /// Open the picker, and take back whatever was chosen.
  ///
  /// The same picker that adds a food to the day, in a mode where tapping a
  /// food hands it back rather than going on to log it. A second picker would
  /// be a second place for "the household's own foods come first" to be true
  /// or not.
  Future<void> _chooseAnotherFood() async {
    final chosen = await Navigator.of(context).pushNamed(
      NavigationOptions.addMealRoute,
      arguments: AddMealScreenArguments(
        // No meal of the day, on purpose: nothing here is being logged, so
        // there is nothing for it to be logged under. The picker names itself
        // after what it was opened to do instead.
        null,
        widget.intakeEntity.dateTime,
        insteadOfWhatIsThere: true,
      ),
    );
    if (chosen is! MealEntity) return;
    if (!mounted) return;
    setState(() => _instead = chosen);
    // The amount has not moved, but what it comes to has.
    _onAmountChanged();
  }

  /// Put an older version back.
  ///
  /// It leaves as an ordinary correction, down the same path as anything typed
  /// into this dialog, which is the whole design of it: there is one way of
  /// writing to a row and restoring is that way, replayed. The fields come off
  /// the version the Mac Mini sent, and the Mini worked out which fields those
  /// are — a phone keeping its own copy of that list would go quietly wrong the
  /// day the list changed.
  void _putBack(WhatItWas was) {
    Navigator.of(context).pop(
      IntakeEdit(
        was.putBackAmount?.toDouble(),
        label: was.putBackLabel,
        kcal: was.putBackKcal?.toDouble(),
        moveTo: was.putBackOwner(widget.currentOwner),
      ),
    );
  }

  /// Whether the move being asked for is the one BC-0026 refuses.
  ///
  /// Asked here, before anything moves, so the person hears it rather than
  /// watching a row leave their day and come back. The Mac Mini refuses it too
  /// — it is the only machine that can see both halves — but that answer
  /// arrives through the queue, some time after the screen has gone.
  ///
  /// A house that cannot be reached is not treated as "nobody holds it". The
  /// mistake this prevents is invisible once made, so the honest answer to
  /// "I could not ask" is to say so and change nothing.
  Future<String?> _whyTheMoveIsRefused(HouseholdPerson moveTo) async {
    final ledger = widget.ledger;
    if (ledger == null) return null;
    try {
      final held = await ledger.whoElseHolds(widget.intakeEntity.id);
      if (!held.contains(moveTo.id)) return null;
      return EditDialog.cannotMoveOnto(moveTo.name);
    } on HouseholdUnreachable catch (e) {
      return '${e.headline}, so this cannot be moved yet — it is the only '
          'machine that knows whose day the other half of a shared meal is on.';
    }
  }

  /// The refusal, with the one thing it could still be: the meal was never
  /// shared, and this half should not be on anybody's day.
  Future<void> _sayItCannotMove(String why) async {
    final chosen = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(why),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text(EditDialog.notReallySharedLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(EditDialog.leaveItLabel),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (chosen == true) {
      Navigator.of(context).pop(const IntakeEdit(null, remove: true));
    }
    // Anything else leaves the person on the edit screen with the row exactly
    // as it was. Nothing has moved, so there is nothing to put back.
  }

  /// The correction, as one thing, once. See [IntakeEdit].
  Future<void> _save() async {
    final moveTo = _moveTo;
    if (moveTo != null) {
      final why = await _whyTheMoveIsRefused(moveTo);
      if (!mounted) return;
      if (why != null) return _sayItCannotMove(why);
    }
    if (_hasNoFoodBehindIt) {
      final name = nameEditingController.text.trim();
      Navigator.of(context).pop(
        IntakeEdit(
          null,
          label: name.isEmpty ? null : name,
          kcal: double.tryParse(kcalEditingController.text.trim()),
          moveTo: _moveTo?.id,
          slot: _slotIfMoved,
        ),
      );
      return;
    }
    final newAmount = double.tryParse(amountEditingController.text);
    if (newAmount == null) return;
    Navigator.of(context).pop(
      IntakeEdit(
        _convertBackToMetricValue(newAmount, _food.mealUnit),
        moveTo: _moveTo?.id,
        slot: _slotIfMoved,
        nowItIs: _instead,
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
                onPressed: () => _setAmount(_food.servingQuantity! * 0.5),
              ),
              ActionChip(
                label: const Text('1 srv'),
                onPressed: () => _setAmount(_food.servingQuantity!),
              ),
            ],
          ],
        ),
        if (_theFoodCanBeChanged) ...[
          const SizedBox(height: 8.0),
          _whatItIs(context),
        ],
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
