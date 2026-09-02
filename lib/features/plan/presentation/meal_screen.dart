import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';
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
  static const fillThemIn = 'Fill these in for me';
  static const fillHeading = 'What these are, probably';
  static const fillBlurb =
      "Nothing is saved until you say so. The amounts are guesses at a normal "
      "helping — take them as they are and change the ones that are wrong.";
  static const takeThemAll = 'Take these';
  static const stillToLookUp = 'Still to look up';
  static const nothingToPropose =
      "The house has nothing to suggest for this one — its parts are either "
      'already filled in or are things the food list has never heard of.';
  static const guessedAmount = 'amount still a guess';

  // --- Getting a food the house has never bought -------------------------
  // Two doors, on Aidan's answer of 2 September 2026 when he was asked which
  // one he wanted: "Can we have the option of either?"
  static const neverBoughtThis =
      "This house has never bought that. You can photograph the packet, or "
      'have it looked up online — either way it joins the food list first.';
  static const photographThePacket = 'Photograph it';
  static const lookItUpOnline = 'Look it up';
  static const webCandidatesBlurb =
      "Read off shops' pages just now, and saved by nobody yet. Pick the one "
      'that matches your packet and check its numbers on the next screen.';
  static const nothingOnTheWeb =
      "Nothing came back for that. You can photograph the packet instead, or "
      'type it in from the food list.';
  static const savedButNotSentYet =
      "Saved on this phone, but the house has not heard about it yet — this "
      'phone cannot reach the Mac Mini. It will be here to pick once it can.';
  static const checkTheseNumbers = 'Check these numbers';
  static const savedUnderAnotherName =
      "Saved. It is not matching what you typed, so it has gone in under a "
      'different name — clear the box to see the whole list.';

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
      case 'estimated':
        // What a meal filled in from proposals and never corrected says about
        // itself. The foods may be perfectly well known; nobody has looked at
        // how much of them goes in, and that is what this figure is a figure
        // of.
        return 'Worked out from guessed helpings that nobody has checked, so '
            'treat the whole figure as a guess.';
      case 'web':
        return 'Worked out using numbers read off the web rather than off a '
            'packet in this house.';
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

  /// Offer the house's guess at every part nobody has filled in, and save the
  /// ones he takes.
  ///
  /// Two steps rather than one on purpose. Asking writes nothing, so what he
  /// sees is a list he can walk away from; taking them is the ordinary part
  /// write, once per row, each carrying the fact that its amount was a guess.
  /// A single button that filled the meal in silently would put numbers on a
  /// meal that nobody had agreed to, which is the one thing the whole trust
  /// story here exists to prevent.
  Future<void> _fillThemIn() async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    MealProposals? proposals;
    String? wentWrong;
    try {
      proposals = await widget.repository.proposalsFor(widget.mealId);
    } on HouseholdUnreachable catch (e) {
      wentWrong = "${e.headline}, so it can't suggest anything just now.";
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problem = wentWrong;
    });
    if (proposals == null) return;
    if (!proposals.ok || proposals.acceptable.isEmpty) {
      setState(() => _problem = proposals!.why ?? MealScreen.nothingToPropose);
      return;
    }
    final take = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ProposalSheet(proposals: proposals!),
    );
    if (take != true || !mounted) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    String? failed;
    try {
      await widget.repository.acceptAll(widget.mealId, proposals.acceptable);
    } on HouseholdUnreachable catch (e) {
      failed = "${e.headline}, so not all of those were saved.";
    }
    await _load();
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (failed != null) _problem = failed;
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
            // Offered only while something is actually missing. A meal whose
            // parts are all filled in has nothing to propose, and a button
            // that would come back saying so is a button that wastes a tap.
            if (made != null && made.isMadeOfParts && made.awaiting.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : _fillThemIn,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: const Text(MealScreen.fillThemIn),
                ),
              ),
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
          // A guessed helping reads as a guessed helping. The number itself is
          // indistinguishable from one somebody weighed, and the meal's total
          // is only as honest as the least-looked-at line under it.
          subtitle: Text(part.why ??
              (part.amountIsAGuess && part.howMuch != null
                  ? '${part.howMuch} — ${MealScreen.guessedAmount}'
                  : part.howMuch ?? part.component)),
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
    // Read here and carried in, the way the day sheet does it: a sheet opens on
    // the navigator's overlay rather than inside this screen's widget tree, so
    // whether this person wants to see calorie figures is not in scope by the
    // time the sheet builds. It matters now that a door out of this sheet shows
    // figures of its own.
    final figuresOff = Figures.off(context);
    final said = await showModalBottomSheet<_WhatGoesIn>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiguresScope(
        figuresOff: figuresOff,
        child: _PartSheet(component: part.component, was: part),
      ),
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
/// The list offered here is the household's own and nothing else. A part of a
/// meal this house cooks is a thing this house buys; offering the internet's
/// food database directly would let a meal be built out of somebody else's
/// guess at a packet, and the meal's whole calorie figure is only ever as good
/// as its worst part.
///
/// That left a dead end, which is what Aidan hit on 2 September 2026: a meal
/// naming something the house has never bought had nowhere to go from here.
/// His answer, asked which way out he wanted, was *"Can we have the option of
/// either?"* — so there are two, and the wall they are cut into is unchanged.
/// Both doors end by writing a food into the household's own list, carrying an
/// honest account of where its numbers came from ('photo' off a packet in this
/// house, 'web' off somebody's page), and only then is it picked from that
/// list like any other. Nothing here reads a figure straight off the internet
/// into a meal.
///
/// The new food is written through the same queue everything else goes
/// through, so it does not exist for the house until the phone has spoken to
/// it. That is why both doors drain the queue and then search again rather
/// than assuming: a part filled from a food the Mini has never heard of is a
/// part pointing at nothing.
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

  /// What is in the search box. Kept because the two doors out of an empty
  /// search need it: it is the name to photograph a packet for, the name to
  /// hunt the web with, and the name to search again with afterwards.
  String _looked = '';

  /// Set while a door is open or the queue is being drained, so the sheet
  /// says something is happening rather than sitting still.
  bool _busy = false;

  /// What went wrong, in words, when a door did not end in a food. Nulled on
  /// the next search so a stale sentence never sits under a fresh list.
  String? _trouble;
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
    setState(() {
      _looked = q;
      _foods = found;
      _trouble = null;
    });
  }

  /// Whether to offer the two ways of getting a food the house has never
  /// bought.
  ///
  /// Only once somebody has typed something and the house has answered with
  /// nothing. Offering it against an empty box would be offering to photograph
  /// a packet nobody has named, and offering it while the search is still out
  /// would be calling a slow answer a missing one.
  bool get _nothingHere =>
      _chosen == null && _looked.trim().isNotEmpty && (_foods?.isEmpty ?? false);

  /// Photograph the packet: the same three-shot screen a food is entered by
  /// anywhere else, so a food reached from here and a food reached from the
  /// food list are written the same way and are equally accountable.
  Future<void> _photographIt() async {
    await Navigator.of(context).pushNamed(NavigationOptions.labelCaptureRoute);
    await _pickUpWhatWasJustWritten();
  }

  /// Look it up online: candidates from the web, none of them saved, one of
  /// them confirmed by a person on the same form a photographed label goes
  /// through. Confirming is what writes it; looking costs nothing.
  Future<void> _lookItUp() async {
    final name = _looked.trim();
    setState(() {
      _busy = true;
      _trouble = null;
    });
    final drafts = await locator<FoodFinder>().huntFor(name);
    if (!mounted) return;
    setState(() => _busy = false);
    if (drafts.isEmpty) {
      setState(() => _trouble = MealScreen.nothingOnTheWeb);
      return;
    }
    final figuresOff = Figures.off(context);
    final draft = await showModalBottomSheet<FoodDraft>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => FiguresScope(
        figuresOff: figuresOff,
        child: _WebCandidates(name: name, drafts: drafts),
      ),
    );
    if (draft == null || !mounted) return;
    // The form is a section rather than a page — a bare Column, so the
    // photograph flow can drop it into its own layout. A route that hosts it
    // has to supply what a page needs: something for the fields to sit on,
    // somewhere to scroll, and a way back. Nine text fields on nothing is what
    // happens otherwise.
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (page) => Scaffold(
        appBar: AppBar(title: Text(MealScreen.checkTheseNumbers)),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 24),
            child: Builder(
              builder: (form) => ConfirmFoodScreen(
                logger: locator<HouseholdLogger>(),
                draft: draft,
                // No offer to put it on today. Naming what goes into a Tuesday
                // dinner is not eating it, and the same distinction is already
                // made on the photograph route.
                onSaved: (_) => Navigator.of(form).pop(true),
              ),
            ),
          ),
        ),
      ),
    ));
    if (saved != true || !mounted) return;
    await _pickUpWhatWasJustWritten();
  }

  /// Search again for what was just written, once the house has actually been
  /// told about it.
  ///
  /// The drain is not politeness. A food is queued on this phone and only gets
  /// the id the house knows it by when the Mini accepts it, and a part is
  /// saved by that id — so searching before the queue has emptied finds
  /// nothing, and saying "it did not work" would be a lie about a food that is
  /// sitting in a queue perfectly intact. When the Mini cannot be reached, that
  /// is what gets said, in those words.
  Future<void> _pickUpWhatWasJustWritten() async {
    if (!mounted) return;
    setState(() => _busy = true);
    final drained = await locator<Outbox>().drain();
    if (!mounted) return;
    await _search(_looked);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (drained.unreachable) {
        _trouble = MealScreen.savedButNotSentYet;
      } else if (_foods?.isEmpty ?? true) {
        // Written and sent, and still not matching what is in the box — most
        // often because the packet is named something other than what was
        // typed. Clearing the box shows the whole list, which is where it now
        // is.
        _trouble = MealScreen.savedUnderAnotherName;
      }
    });
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
              if (foods != null && foods.isNotEmpty)
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
              if (_nothingHere) ...[
                Text(MealScreen.neverBoughtThis,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _photographIt,
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: const Text(MealScreen.photographThePacket),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _lookItUp,
                      icon: const Icon(Icons.travel_explore),
                      label: const Text(MealScreen.lookItUpOnline),
                    ),
                  ),
                ]),
              ],
              if (_busy) ...[
                const SizedBox(height: 12),
                const LinearProgressIndicator(),
              ],
              if (_trouble != null) ...[
                const SizedBox(height: 8),
                Text(_trouble!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.error)),
              ],
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

/// What the house proposes for a meal's empty parts, before anything is saved.
///
/// A read-only list and two buttons. It exists so that "fill this in for me"
/// is something somebody agrees to rather than something that happens to their
/// meal — the amounts on it are guesses, and a guess arriving silently on a
/// figure that other screens go on to quote is exactly the failure the trust
/// wording elsewhere in this file is written to avoid.
class _ProposalSheet extends StatelessWidget {
  final MealProposals proposals;

  const _ProposalSheet({required this.proposals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stillMissing = proposals.needLookingUp;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(MealScreen.fillHeading, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(MealScreen.fillBlurb,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final p in proposals.acceptable)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(p.reads),
                      subtitle: Text(p.component),
                    ),
                  // The ones it cannot help with, named. After taking
                  // everything above, these are what will still be holding the
                  // meal's total up, and finding that out by pressing the
                  // button and watching nothing change would be worse than
                  // being told now.
                  if (stillMissing.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(MealScreen.stillToLookUp,
                        style: theme.textTheme.labelLarge),
                    for (final p in stillMissing)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(p.component),
                        subtitle: Text(p.why),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Not now'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text(MealScreen.takeThemAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


/// What the web came back with, before any of it is saved.
///
/// A read-only list. Tapping one carries it to the same form a photographed
/// label goes to, where a person looks at the numbers and is the one who saves
/// it — which is the whole reason this is a list of candidates and not a list
/// of foods. Nothing was written by asking, and nothing is written by looking.
class _WebCandidates extends StatelessWidget {
  final String name;
  final List<FoodDraft> drafts;

  const _WebCandidates({required this.name, required this.drafts});

  /// What one candidate reads as under its name.
  ///
  /// Through the one formatter, like every other calorie figure in the app, so
  /// it disappears with the rest when figures are switched off — a candidate
  /// list is exactly the sort of out-of-the-way surface that would otherwise
  /// keep quoting kcal at somebody who has asked not to see them. Null when the
  /// page carried no figure at all, because an empty line says "no numbers"
  /// more honestly than a zero does.
  static String? numbersLine(BuildContext context, FoodDraft d) =>
      Figures.per100(context, d.kcal100);

  /// How one candidate is named, brand first when it has one — two shops'
  /// own-brand versions of the same thing are otherwise the same line twice.
  static String titleFor(FoodDraft d) {
    final brand = d.brand;
    return brand == null || brand.isEmpty ? d.name : '$brand ${d.name}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(MealScreen.webCandidatesBlurb,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
            const SizedBox(height: 12),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final d in drafts)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(titleFor(d)),
                      subtitle: numbersLine(context, d) == null
                          ? null
                          : Text(numbersLine(context, d)!),
                      onTap: () => Navigator.of(context).pop(d),
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
