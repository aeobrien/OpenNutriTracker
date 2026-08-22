import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/domain/meal_parts.dart';
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
/// The portions are editable here and the parts are not. Correcting a portion
/// is an ordinary weekly thing — he had less of it than usual — and correcting
/// what a meal is made of is a change to a household record that the kitchen
/// panel owns. Both were asked for; only the first belongs on a phone.
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

  @override
  void initState() {
    super.initState();
    _portions = {...?widget.planned?.portions};
    _load();
  }

  Future<void> _load() async {
    try {
      final made = await widget.repository.madeOf(widget.mealId);
      if (!mounted) return;
      setState(() {
        _made = made;
        _problem = null;
      });
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() =>
          _problem = "${e.headline}, so what this is made of can't be shown.");
    }
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
          trailing: part.isAGap
              ? Icon(Icons.help_outline, color: theme.colorScheme.outline)
              : _partFigure(part),
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

  Widget? _partFigure(MealPart part) {
    final figure = Figures.kcal(context, part.kcal);
    return figure == null ? null : Text(figure);
  }
}
