import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';

/// Looking at what a packet says, and putting it in the household list.
///
/// One screen for both routes. It opens filled in when the photographs were
/// read, and blank when they were not — or when there were none, because
/// somebody is simply typing a packet in. That is not a convenience: the whole
/// premise of filling the food list in as you go is that it works on the days
/// the camera does not, so the hand-typed path cannot be a lesser branch of the
/// photograph path.
///
/// Nothing is saved until Save is pressed. Up to that point a person can change
/// anything, and changing anything drops the trust from what a photograph
/// claimed to what a person typed — the list keeps saying where its numbers
/// came from long after everybody has forgotten.
class ConfirmFoodScreen extends StatefulWidget {
  final HouseholdLogger logger;

  /// What to open with. Null starts an empty form, which is the hand-typed
  /// route.
  final FoodDraft? draft;

  /// Called once the food has been put on the queue for the household list.
  final void Function(String clientId)? onSaved;

  const ConfirmFoodScreen({
    super.key,
    required this.logger,
    this.draft,
    this.onSaved,
  });

  @override
  State<ConfirmFoodScreen> createState() => _ConfirmFoodScreenState();
}

class _ConfirmFoodScreenState extends State<ConfirmFoodScreen> {
  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _kcal;
  late final TextEditingController _protein;
  late final TextEditingController _fat;
  late final TextEditingController _carbs;
  late final TextEditingController _serving;

  late FoodDraft _draft;
  bool _touched = false;
  bool _saving = false;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _draft = widget.draft ?? const FoodDraft(name: '');
    _name = TextEditingController(text: _draft.name);
    _brand = TextEditingController(text: _draft.brand ?? '');
    _kcal = TextEditingController(text: _numText(_draft.kcal100));
    _protein = TextEditingController(text: _numText(_draft.protein100));
    _fat = TextEditingController(text: _numText(_draft.fat100));
    _carbs = TextEditingController(text: _numText(_draft.carbs100));
    _serving = TextEditingController(text: _numText(_draft.servingG));
    for (final c in [_name, _brand, _kcal, _protein, _fat, _carbs, _serving]) {
      c.addListener(_noteAnEdit);
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _brand, _kcal, _protein, _fat, _carbs, _serving]) {
      c.dispose();
    }
    super.dispose();
  }

  static String _numText(num? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.round().toString()
        : value.toString();
  }

  void _noteAnEdit() {
    if (_touched) return;
    setState(() => _touched = true);
  }

  num? _read(TextEditingController c) => num.tryParse(c.text.trim());

  /// What the food will be saved as. Built here rather than at save time so the
  /// screen can show the trust it is about to record, before it records it.
  FoodDraft get pending {
    final base = FoodDraft(
      name: _name.text.trim(),
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      barcode: _draft.barcode,
      kcal100: _read(_kcal),
      protein100: _read(_protein),
      fat100: _read(_fat),
      carbs100: _read(_carbs),
      packGrams: _draft.packGrams,
      servingG: _read(_serving),
      trust: _draft.trust,
      source: _draft.source,
      unreadable: _draft.unreadable,
    );
    return _touched ? base.edited() : base;
  }

  /// Said plainly, because the person is being asked to stand behind it.
  static String trustSentence(FoodDraft draft) {
    switch (draft.trust) {
      case 'photo':
        return 'These numbers came off the photographs.';
      case 'typed':
        return draft.source == 'photo'
            ? 'You corrected these, so they are recorded as typed in.'
            : 'You typed these in.';
      default:
        return 'Recorded as ${draft.trust}.';
    }
  }

  Future<void> _save() async {
    final food = pending;
    if (!food.isSaveable) {
      setState(() => _problem = 'A food needs a name before it can be saved.');
      return;
    }
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final clientId = await widget.logger.addFood(
        name: food.name,
        trust: food.trust,
        source: food.source,
        brand: food.brand,
        barcode: food.barcode,
        kcal100: food.kcal100,
        protein100: food.protein100,
        fat100: food.fat100,
        carbs100: food.carbs100,
        packGrams: food.packGrams,
        servingG: food.servingG,
      );
      widget.onSaved?.call(clientId);
    } on HouseholdRefused catch (e) {
      if (!mounted) return;
      setState(() => _problem = "That wasn't accepted: ${e.message}");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _field(String label, TextEditingController controller,
          {bool number = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: TextField(
          controller: controller,
          keyboardType: number ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final food = pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('Name', _name),
        _field('Brand', _brand),
        _field('Calories per 100g', _kcal, number: true),
        _field('Protein per 100g', _protein, number: true),
        _field('Fat per 100g', _fat, number: true),
        _field('Carbohydrate per 100g', _carbs, number: true),
        _field('Serving size in grams', _serving, number: true),
        if (_draft.unreadable.isNotEmpty && !_touched)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
                'The photographs did not give up everything — please check the '
                'blanks.'),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(trustSentence(food)),
        ),
        if (food.hasNoNumbers)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
                'No calories yet. It will go in the list by name, and you can '
                'add the numbers later.'),
          ),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(_problem!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save to the household list'),
          ),
        ),
      ],
    );
  }
}
