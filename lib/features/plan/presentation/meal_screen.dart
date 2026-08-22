import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/domain/household_food.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/domain/meal_parts.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/plan/domain/plan_week.dart';

/// A meal's own screen — what it is made of, and whose share is whose.
///
/// Until now a meal on the plan was a name and a number, and the number could
/// not be checked. That is the failure this screen exists for: a calorie figure
/// with nothing behind it is believed exactly as readily when it is wrong, and
/// the only way to find out is to see what it was added up from.
///
/// Three things, in the order somebody reads them:
///
///   1. **Each person's portion**, and what that portion comes to. Side by
///      side, because the whole point of keeping them apart is that they are
///      usually different, and a number on its own line looks like the answer
///      for everybody.
///   2. **The parts**, each with what it contributes — including the ones that
///      contribute nothing yet. A component nobody has chosen a food for is
///      listed and named. It is the commonest reason a meal has no total, and
///      leaving it out turns a half-described dinner into a confident-looking
///      list with an unexplained gap where the total should be.
///   3. **How far the figure can be trusted**, which is the weakest of any part
///      it was built from. A dinner mostly weighed and partly guessed is a
///      guess, and the line says so in words rather than showing a badge.
///
/// Both the portions and the parts are set from here. A part named as missing
/// and not fixable from the screen that named it is a screen that reports a
/// problem and offers nothing — and until this existed, every gap this screen
/// found could only be closed by walking to the kitchen panel.
class MealScreen extends StatefulWidget {
  final PlanRepository repository;

  /// The meal being looked at.
  final int mealId;
  final String title;

  /// The planned row this was opened from, when it was opened from one. The
  /// portions live on the plan row rather than on the meal, so a meal reached
  /// from the picker has no portions to show — and says so, rather than
  /// showing zeroes that would read as *nobody is having any*.
  final PlannedMeal? planned;

  /// The house, for putting a name beside each portion.
  final List<HouseholdPerson> people;

  const MealScreen({
    super.key,
    required this.repository,
    required this.mealId,
    required this.title,
    required this.people,
    this.planned,
  });

  static const madeOfHeading = 'What this is made of';
  static const portionsHeading = 'Whose share';
  static const notMadeOfParts =
      "This one came out of a packet — its numbers are the packet's, not "
      'added up from anything.';
  static const noPortionsHere =
      'Portions are set on the day this is planned for.';
  static const sayWhatItIs = 'Say what this is';
  static const changeIt = 'Change it';
  static const whichFood = 'Which food?';
  static const howMuch = 'How much goes in?';
  static const workItOut = 'Work out its calories';
  static const doItAgain = 'Work them out again';
  static const nobodyHasSaid = 'Nobody has said';

  /// The trust line, in words. Null when there is no figure to qualify —
  /// a caveat about a number nobody has is a sentence about nothing.
  static String? trustLine(MealMadeOf made) {
    if (made.kcal == null) return null;
    switch (made.trust) {
      case 'weighed':
        return 'Worked out from weighed amounts.';
      case 'typed':
        return 'Worked out from amounts somebody typed in.';
      case 'photo':
        return 'Worked out from numbers read off a photographed packet.';
      case 'guess':
        return 'Worked out from a guess at one of the parts, so treat the '
            'whole figure as a guess.';
      default:
        return 'Worked out from its parts.';
    }
  }

  /// What a portion reads as. A portion nobody has set is not one: the two
  /// are kept apart everywhere, because a default of one is a calorie figure
  /// nobody chose sitting where a chosen one would be.
  static String portionText(num? portions) {
    if (portions == null) return nobodyHasSaid;
    if (portions == 1) return 'One portion';
    if (portions == portions.roundToDouble()) {
      return '${portions.toInt()} portions';
    }
    return '$portions of it';
  }

  static Future<void> show(
    BuildContext context, {
    required PlanRepository repository,
    required int mealId,
    required String title,
    required List<HouseholdPerson> people,
    PlannedMeal? planned,
  }) {
    // Read outside the route, for the same reason the day sheet does: a route
    // pushed onto the root navigator does not sit under whatever scope
    // happened to be around the widget that opened it.
    final figuresOff = Figures.off(context);
    return Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => FiguresScope(
        figuresOff: figuresOff,
        child: MealScreen(
          repository: repository,
          mealId: mealId,
          title: title,
          people: people,
          planned: planned,
        ),
      ),
    ));
  }

  @override
  State<MealScreen> createState() => _MealScreenState();
}

class _MealScreenState extends State<MealScreen> {
  MealMadeOf? _made;
  String? _problem;

  /// Portions as this screen currently has them — the plan row's to begin
  /// with, then whatever has been typed since. Held here rather than read back
  /// off the server after every keystroke.
  late Map<int, num?> _portions;

  /// Whoever this phone belongs to — which of the two shares on this screen
  /// is the one that fills in an amount box.
  int? _owner;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _portions = {...?widget.planned?.portions};
    _load();
  }

  Future<void> _load() async {
    try {
      final made = await widget.repository.madeOf(widget.mealId);
      final owner = await widget.repository.owner();
      if (!mounted) return;
      setState(() {
        _made = made;
        _owner = owner;
        _problem = null;
      });
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() =>
          _problem = "${e.headline}, so what this is made of can't be shown.");
    }
  }

  /// Ask the house to add this meal up.
  ///
  /// A meal it cannot add up is not an error and is not shown as one: the
  /// answer names the part holding it up, which is the thing somebody can go
  /// and fix. Re-doing it is safe and is offered plainly, because days already
  /// logged keep the numbers they were logged with.
  Future<void> _workItOut() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    String? said;
    try {
      final result = await widget.repository.workOut(widget.mealId);
      if (!result.ok) {
        final named = result.awaiting.map((p) => p.component).join(', ');
        final why = result.why ?? 'Some of this meal has no numbers yet';
        said = named.isEmpty ? '$why.' : '$why — $named.';
      }
    } on HouseholdUnreachable catch (e) {
      said = "${e.headline}, so it can't be added up from here just now.";
    }
    // The re-read happens first and the message is put up after it, in that
    // order. Reloading clears whatever was on screen — which is right, since
    // the screen is being rebuilt — and a message set before it would be wiped
    // by the very reload meant to show what the message is about. It was, and
    // pressing the button looked like it did nothing at all.
    await _load();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (said != null) _problem = said;
    });
  }

  Future<void> _setPortion(HouseholdPerson person, num portions) async {
    final planned = widget.planned;
    if (planned == null) return;
    try {
      await widget.repository.setPortion(
          planId: planned.planId, personId: person.id, portions: portions);
      if (!mounted) return;
      setState(() => _portions[person.id] = portions);
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem = "${e.headline}, so that hasn't been saved.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final made = _made;
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_problem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(_problem!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error)),
              ),
            _heading(theme, MealScreen.portionsHeading),
            ..._whoseShare(theme, made),
            const SizedBox(height: 24),
            _heading(theme, MealScreen.madeOfHeading),
            if (made == null && _problem == null) const Text('…'),
            if (made != null) ..._theParts(theme, made),
            // Only offered for a meal that is made of parts. A packet's
            // numbers are the packet's; there is nothing here to add up, and a
            // button that cannot work should not be on the screen.
            if (made != null && made.isMadeOfParts)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: TextButton.icon(
                  onPressed: _busy ? null : _workItOut,
                  icon: const Icon(Icons.calculate_outlined),
                  label: Text(made.kcal == null
                      ? MealScreen.workItOut
                      : MealScreen.doItAgain),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _heading(ThemeData theme, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text, style: theme.textTheme.titleMedium),
      );

  List<Widget> _whoseShare(ThemeData theme, MealMadeOf? made) {
    if (widget.planned == null) {
      return [
        Text(MealScreen.noPortionsHere,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline)),
      ];
    }
    final perPortion = made?.kcal ?? widget.planned?.mealKcal;
    return [
      for (final person in widget.people)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(person.name),
          subtitle: Text(MealScreen.portionText(_portions[person.id])),
          // The figure that portion comes to, beside the portion itself —
          // which is the only place the two can be checked against each other.
          trailing: _shareFigure(perPortion, _portions[person.id]),
          onTap: () => _askForPortion(person),
        ),
    ];
  }

  Widget? _shareFigure(num? perPortion, num? portions) {
    if (perPortion == null || portions == null) return null;
    final figure = Figures.kcal(context, perPortion * portions);
    return figure == null ? null : Text(figure);
  }

  Future<void> _askForPortion(HouseholdPerson person) async {
    final chosen = await showDialog<num>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('How much of it is ${person.name}’s?'),
        children: [
          for (final amount in const [0.5, 0.75, 1, 1.5, 2])
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(amount),
              child: Text(MealScreen.portionText(amount)),
            ),
        ],
      ),
    );
    if (chosen != null) await _setPortion(person, chosen);
  }

  List<Widget> _theParts(ThemeData theme, MealMadeOf made) {
    if (!made.isMadeOfParts) {
      return [
        Text(MealScreen.notMadeOfParts,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.outline)),
      ];
    }
    final trust = MealScreen.trustLine(made);
    return [
      for (final part in made.parts)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(part.foodName ?? part.component),
          subtitle: Text(part.why ?? part.howMuch ?? part.component),
          // A part that cannot be counted shows its reason where its figure
          // would be, so the row that is holding the total up is the row that
          // explains itself.
          trailing: _partTrailing(theme, part),
          // Tapping a part logs that food, opening on this person's share of
          // it rather than on whatever they last had of it on its own. A
          // component with no food behind it has nothing to open.
          // A row does the one thing that makes sense for it: a part with a
          // gap is filled in, a part that is settled is logged.
          onTap: part.isAGap ? () => _sayWhatItIs(part) : () => _logPart(part),
        ),
      if (trust != null)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(trust,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.outline)),
        ),
    ];
  }

  /// Say what one part of this meal is, and how much of it goes in.
  ///
  /// The same sheet whether the component had nothing against it or had the
  /// wrong thing, because the house stores one part per component and saying
  /// it again replaces it. A separate correction path would be a second way of
  /// doing one thing, and the two would drift.
  Future<void> _sayWhatItIs(MealPart part) async {
    final said = await showModalBottomSheet<_WhatGoesIn>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _PartSheet(component: part.component, was: part),
    );
    if (said == null || !mounted) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    String? wentWrong;
    try {
      await widget.repository.setPart(
        mealId: widget.mealId,
        component: part.component,
        foodId: said.foodId,
        qty: said.qty,
        unit: said.unit,
      );
    } on HouseholdUnreachable catch (e) {
      wentWrong = "${e.headline}, so that hasn't been saved.";
    }
    await _load();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (wentWrong != null) _problem = wentWrong;
    });
  }

  /// Open the amount box for one part of this meal.
  ///
  /// The starting amount is this person's share of the part: how much of it
  /// goes in the pan, times how much of the finished meal is theirs. Half a
  /// traybake made with 500 g of chicken thighs is 250 g of chicken thighs,
  /// and that is a figure somebody in this house actually decided — which is
  /// why it comes before what they happened to eat last time.
  ///
  /// In grams, which is what the box's own ladder divides through. A share
  /// arriving as a count would read as two hundred and fifty fish cakes.
  Future<void> _logPart(MealPart part) async {
    final navigator = Navigator.of(context);
    final food = await locator<FoodFinder>().asThePickerHasIt(part.food!);
    final config = await locator<ConfigRepository>().getConfig();
    if (!mounted) return;
    final mine = _owner == null ? null : _portions[_owner];
    final grams = part.grams;
    navigator.pushNamed(
      NavigationOptions.mealDetailRoute,
      arguments: MealDetailScreenArguments(
        food,
        _slot(),
        DateTime.now(),
        config.usesImperialUnits,
        householdPortion: (mine == null || grams == null)
            ? null
            : (grams * mine).toDouble(),
      ),
    );
  }

  /// Which meal of the day this goes under. The plan already says — it is the
  /// slot the panel put this meal in — so it is read rather than guessed at,
  /// and only a plan that does not say falls back to the time on the clock.
  IntakeTypeEntity _slot() {
    switch (widget.planned?.kind) {
      case 'breakfast':
        return IntakeTypeEntity.breakfast;
      case 'lunch':
        return IntakeTypeEntity.lunch;
      case 'dinner':
        return IntakeTypeEntity.dinner;
      case 'snack':
        return IntakeTypeEntity.snack;
      default:
        final hour = DateTime.now().hour;
        if (hour < 11) return IntakeTypeEntity.breakfast;
        if (hour < 15) return IntakeTypeEntity.lunch;
        if (hour < 21) return IntakeTypeEntity.dinner;
        return IntakeTypeEntity.snack;
    }
  }

  Widget _partTrailing(ThemeData theme, MealPart part) {
    if (part.isAGap) {
      return Icon(Icons.help_outline, color: theme.colorScheme.outline);
    }
    final figure = _partFigure(part);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (figure != null) figure,
      IconButton(
        icon: const Icon(Icons.edit_outlined),
        tooltip: MealScreen.changeIt,
        onPressed: _busy ? null : () => _sayWhatItIs(part),
      ),
    ]);
  }

  Widget? _partFigure(MealPart part) {
    final figure = Figures.kcal(context, part.kcal);
    return figure == null ? null : Text(figure);
  }
}


/// What somebody said one part of a meal is.
class _WhatGoesIn {
  final int foodId;
  final num qty;
  final String unit;

  const _WhatGoesIn(this.foodId, this.qty, this.unit);
}

/// Choosing the food that stands for one component, and how much of it.
///
/// The food list is the household's own and nothing else. A part of a meal
/// this house cooks is a thing this house buys; offering the internet's food
/// database here would let a meal be built out of somebody else's guess at a
/// packet, and the meal's whole calorie figure is only ever as good as its
/// worst part.
class _PartSheet extends StatefulWidget {
  final String component;

  /// What the part already was, when it was anything. Its amount is what the
  /// boxes open on, so correcting a 500 to a 400 is one character rather than
  /// a re-entry.
  final MealPart? was;

  const _PartSheet({required this.component, this.was});

  @override
  State<_PartSheet> createState() => _PartSheetState();
}

class _PartSheetState extends State<_PartSheet> {
  List<MealEntity>? _foods;
  MealEntity? _chosen;
  late final TextEditingController _amount;
  late String _unit;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
        text: widget.was?.quantity == null ? '' : '${widget.was!.quantity}');
    // A correction opens on the amount, not on the food list. The food is
    // already known and is usually the thing that was right — somebody
    // weighing the chicken properly should not have to find the chicken again
    // before they can say what it weighed.
    final already = widget.was?.food;
    if (already != null) _chosen = MealEntity.fromHouseholdFood(already);
    final was = widget.was?.unit;
    _unit = was != null && PlanRepository.partUnits.contains(was) ? was : 'g';
    _search('');
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _search(String q) async {
    final found = await locator<FoodFinder>().matching(q);
    if (!mounted) return;
    setState(() => _foods = found);
  }

  /// The amount as a number, or null when what is typed is not one. Null is
  /// what disables the button — a part with no amount is not a part, and the
  /// house refuses one anyway.
  num? get _typed {
    final value = num.tryParse(_amount.text.trim());
    return (value == null || value <= 0) ? null : value;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foods = _foods;
    final chosen = _chosen;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.component, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (chosen == null) ...[
              TextField(
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: MealScreen.whichFood,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: _search,
              ),
              const SizedBox(height: 8),
              if (foods != null)
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final food in foods)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(food.name ?? ''),
                          onTap: () => setState(() => _chosen = food),
                        ),
                    ],
                  ),
                ),
            ] else ...[
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(chosen.name ?? ''),
                trailing: TextButton(
                  onPressed: () => setState(() => _chosen = null),
                  child: const Text('Not that one'),
                ),
              ),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration:
                        const InputDecoration(labelText: MealScreen.howMuch),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<String>(
                  value: _unit,
                  onChanged: (u) => setState(() => _unit = u ?? _unit),
                  items: [
                    for (final unit in PlanRepository.partUnits)
                      DropdownMenuItem(value: unit, child: Text(unit)),
                  ],
                ),
              ]),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _typed == null
                    ? null
                    : () {
                        final id = HouseholdFood.idFromCode(chosen.code ?? '');
                        if (id == null) return;
                        Navigator.of(context)
                            .pop(_WhatGoesIn(id, _typed!, _unit));
                      },
                child: const Text('Save'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
