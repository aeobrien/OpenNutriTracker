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
  /// The message on a field the photographs could not read.
  ///
  /// It sits on the field itself rather than in a sentence underneath the form.
  /// A blank box and a box the camera failed on look identical, and "check the
  /// blanks" leaves somebody comparing the screen against the packet to work
  /// out which blanks were meant.
  static const couldNotRead = "Couldn't read this — check the packet";

  /// What the person is told once the food is in the list.
  ///
  /// It names the food, because "Saved" on a screen that is about to disappear
  /// tells somebody who pressed Save nothing they did not already know. And it
  /// says where it went, because the household food list and today's day are
  /// two different places and putting a packet in the first does not put it on
  /// the second — Aidan pressed Save, was told nothing at all, and had to go
  /// and scan the barcode afterwards to find out whether it had worked.
  static String savedSentence(String name) =>
      '$name is in the household food list. '
      'Search for it when you want to put it on a day.';

  /// The shorter version, for when the offer is there to be taken.
  ///
  /// It drops "search for it when you want to put it on a day", because a
  /// button offering to do exactly that is sitting beside the words. Telling
  /// somebody to go and look for something while offering to fetch it reads as
  /// though the button is for something else.
  static String savedWithOfferSentence(String name) =>
      '$name is in the household food list.';

  /// The offer itself. A verb, and it names the day rather than the list, so
  /// it cannot be misread as another way of saving.
  static const putItOnToday = 'Put it on today';

  /// The same message for a food that came off a web page rather than a
  /// photograph. Different words because it is a different situation: nothing
  /// failed to be read, the page simply never said, and telling somebody to
  /// check a reading that never happened sends them looking for the wrong
  /// thing.
  static const pageDidNotSay = "The page didn't say — check the packet";

  final HouseholdLogger logger;

  /// What to open with. Null starts an empty form, which is the hand-typed
  /// route.
  final FoodDraft? draft;

  /// Called once the food has been put on the queue for the household list.
  final void Function(String clientId)? onSaved;

  /// What to do if the person takes up the offer to put the packet straight on
  /// today. Optional: where it is not given, no offer is made and saving ends
  /// where it always did.
  ///
  /// It is an offer and not something that happens on its own, on Aidan's
  /// answer of 21 August 2026. Entering a packet and eating a packet are two
  /// different acts — somebody typing in a jar of coffee at the point of
  /// putting it in the cupboard has not drunk it — so the day is never touched
  /// unless it is asked for.
  /// [where] is the messenger's own context, not this form's. The offer is
  /// pressed from a message that deliberately outlives the screen that raised
  /// it — on the photograph route the form and the one under it are both gone
  /// by then — so a callback handed this form's context would be navigating
  /// from a widget that no longer exists.
  final void Function(BuildContext where, FoodDraft saved)? onPutOnDay;

  const ConfirmFoodScreen({
    super.key,
    required this.logger,
    this.draft,
    this.onSaved,
    this.onPutOnDay,
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

  /// Rebuilds on every keystroke, not only the first.
  ///
  /// The early return that used to be here was right about the flag and wrong
  /// about the screen: filling in the second field the camera missed has to
  /// clear the second field's warning, and it cannot if nothing redraws after
  /// the first one.
  void _noteAnEdit() {
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
      case 'web':
        return 'These came off a web page. Nobody here has checked them '
            'against the packet.';
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
    // Held before the first await. This is the messenger at the root of the
    // app rather than one belonging to this screen, which is what lets the
    // sentence outlive the form: on the photograph route [widget.onSaved] pops
    // this screen and the one under it, and the person reads the confirmation
    // on the screen they land on.
    final messenger = ScaffoldMessenger.of(context);
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
      // Said before the screen is dismissed, not after: onSaved is what closes
      // the form, and a message queued behind it would be shouted at a widget
      // that no longer exists.
      final offer = widget.onPutOnDay;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            offer == null
                ? ConfirmFoodScreen.savedSentence(food.name)
                : ConfirmFoodScreen.savedWithOfferSentence(food.name),
          ),
          // Longer when there is something to press. Five seconds is enough to
          // read a confirmation and not enough to notice an offer, put the
          // packet down and decide.
          duration: Duration(seconds: offer == null ? 5 : 10),
          action: offer == null
              ? null
              : SnackBarAction(
                  label: ConfirmFoodScreen.putItOnToday,
                  onPressed: () => offer(messenger.context, food),
                ),
        ),
      );
      widget.onSaved?.call(clientId);
    } on HouseholdRefused catch (e) {
      if (!mounted) return;
      setState(() => _problem = "That wasn't accepted: ${e.message}");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Whether this field is one the photographs gave up on, and is still empty.
  ///
  /// Still empty matters: once there is a figure in the box the warning has
  /// done its job, and leaving it there would read as a complaint about the
  /// number the person just typed.
  bool _unread(String key, TextEditingController controller) =>
      _draft.unreadable.contains(key) && controller.text.trim().isEmpty;

  Widget _field(
    String label,
    TextEditingController controller, {
    bool number = false,
    String? readingKey,
  }) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
    child: TextField(
      controller: controller,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        helperText: readingKey != null && _unread(readingKey, controller)
            ? (_draft.trust == 'web'
                  ? ConfirmFoodScreen.pageDidNotSay
                  : ConfirmFoodScreen.couldNotRead)
            : null,
        helperMaxLines: 2,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final food = pending;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field('Name', _name, readingKey: 'name'),
        _field('Brand', _brand, readingKey: 'brand'),
        _field(
          'Calories per 100g',
          _kcal,
          number: true,
          readingKey: 'kcal_100',
        ),
        _field(
          'Protein per 100g',
          _protein,
          number: true,
          readingKey: 'protein_100',
        ),
        _field('Fat per 100g', _fat, number: true, readingKey: 'fat_100'),
        _field(
          'Carbohydrate per 100g',
          _carbs,
          number: true,
          readingKey: 'carbs_100',
        ),
        _field(
          'Serving size in grams',
          _serving,
          number: true,
          readingKey: 'serving_g',
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
              'add the numbers later.',
            ),
          ),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              _problem!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
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
