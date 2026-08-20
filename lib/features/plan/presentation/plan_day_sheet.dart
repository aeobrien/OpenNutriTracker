import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/domain/plan_week.dart';

/// Planning one day, opened by tapping that day on the week.
///
/// This is the phone's whole planner and it is deliberately one sheet rather
/// than a tab. The week is already on the screen this person looks at every
/// day; a day on it is the obvious place to say *this is what we're having*.
/// Aidan's own note when he stopped the first build was that a second Today
/// tab beside the Home tab was a parallel system rather than an extension —
/// the same reasoning applies here, so the plan opens out of the week instead
/// of sitting beside it.
///
/// What it will not do:
///
///  * **Plan into a queue.** If the Mac Mini cannot be reached, the
///    sheet says so and offers nothing. Planning a meal against a week you
///    cannot see is planning blind, and the second phone might have put
///    something on that day a minute ago.
///  * **Silently remove a meal somebody has already eaten.** Taking a dinner
///    off the plan never touches the ledger, so a meal that has been answered
///    would leave the plan and the day disagreeing with nothing on screen
///    explaining it. The sheet says that before it removes it.
class PlanDaySheet extends StatefulWidget {
  final PlanRepository repository;

  /// The day being planned, as 'YYYY-MM-DD'.
  final String day;

  const PlanDaySheet({super.key, required this.repository, required this.day});

  static const addLabel = 'Add a meal';
  static const nothingPlanned = 'Nothing planned.';
  static const noMeals = 'No meals here by that name.';
  static const alreadyEaten =
      'Somebody has already eaten this. Taking it off the plan '
      "won't take it off their day.";

  /// How the day is written at the top of the sheet — 'Tuesday 25 August'.
  static String heading(String day) {
    final date = DateTime.parse(day);
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June', 'July',
      'August', 'September', 'October', 'November', 'December',
    ];
    return '${days[date.weekday - 1]} ${date.day} ${months[date.month - 1]}';
  }

  /// Show it, and answer whether anything changed — so the week behind it
  /// knows whether it needs to ask the Mac Mini again.
  static Future<bool> show(
    BuildContext context, {
    required PlanRepository repository,
    required String day,
  }) async {
    // A sheet opens on the navigator's overlay, which in some layouts sits
    // above the scope that says whether this person wants to see calorie
    // figures. So the answer is read here, where it is definitely in scope,
    // and carried in — rather than the sheet depending on where in the tree
    // somebody happened to mount the scope.
    final figuresOff = Figures.off(context);
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiguresScope(
        figuresOff: figuresOff,
        child: PlanDaySheet(repository: repository, day: day),
      ),
    );
    return changed ?? false;
  }

  @override
  State<PlanDaySheet> createState() => _PlanDaySheetState();
}

class _PlanDaySheetState extends State<PlanDaySheet> {
  PlanDay? _day;
  String? _problem;
  bool _busy = false;

  /// Whether anything on the plan actually changed while this was open. The
  /// week behind only reloads if it did.
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final week = await widget.repository.week(start: widget.day);
      if (!mounted) return;
      setState(() {
        // Asking for the week that starts at this day would be wrong — the
        // server decides which Monday a date belongs to, and dayFor picks the
        // day back out of whatever week it sent.
        _day = week.dayFor(widget.day);
        _problem = null;
      });
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem = "${e.headline}, so the plan can't be changed "
          'from here just now.');
    }
  }

  Future<void> _add() async {
    final figuresOff = Figures.off(context);
    final chosen = await showModalBottomSheet<MealChoice>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FiguresScope(
        figuresOff: figuresOff,
        child: _MealPicker(repository: widget.repository),
      ),
    );
    if (chosen == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await widget.repository.add(day: widget.day, mealId: chosen.id);
      _changed = true;
      await _load();
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem = '${e.headline}, so that meal is not on the '
          'plan. Nothing was saved.');
    } on HouseholdRefused catch (e) {
      if (!mounted) return;
      setState(() => _problem = 'The Mac Mini would not take that: '
          '${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove(PlannedMeal meal) async {
    if (meal.anybodyAnswered) {
      final go = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          content: const Text(PlanDaySheet.alreadyEaten),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Leave it')),
            TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Take it off')),
          ],
        ),
      );
      if (go != true || !mounted) return;
    }
    setState(() => _busy = true);
    try {
      await widget.repository.remove(meal.planId);
      _changed = true;
      await _load();
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem = '${e.headline}, so that meal is still on the '
          'plan.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(PlanDaySheet.heading(widget.day),
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (_problem != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(_problem!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error)),
                ),
              if (_problem == null) ..._planned(theme),
              const SizedBox(height: 8),
              // No add button when the house cannot be reached: a control that
              // cannot work should not be offered, and this one would have
              // nothing to check the day against.
              if (_problem == null)
                TextButton.icon(
                  onPressed: _busy ? null : _add,
                  icon: const Icon(Icons.add),
                  label: const Text(PlanDaySheet.addLabel),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _planned(ThemeData theme) {
    final day = _day;
    if (day == null) {
      return const [Padding(padding: EdgeInsets.all(8), child: Text('…'))];
    }
    if (day.planned.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(PlanDaySheet.nothingPlanned,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.outline)),
        ),
      ];
    }
    return [
      for (final meal in day.planned)
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(meal.title),
          subtitle: _mealSubtitle(context, meal),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Take it off',
            onPressed: _busy ? null : () => _remove(meal),
          ),
        ),
    ];
  }

  Widget? _mealSubtitle(BuildContext context, PlannedMeal meal) {
    final figure = Figures.kcal(context, meal.mealKcal);
    if (figure != null) return Text('$figure a portion');
    // A meal with no numbers says so rather than showing nothing, because
    // "nobody has worked this out yet" is the thing somebody can go and fix.
    if (Figures.off(context)) return null;
    return const Text("We don't have numbers for this yet");
  }
}

/// Choosing one of the house's meals.
///
/// The list is the kitchen panel's own. Typing a name that matches nothing
/// gets a plain "no meals here by that name" rather than quietly planning a
/// meal that does not exist — a planned name with no recipe behind it has no
/// calories for the week and no ingredients for the shopping list.
class _MealPicker extends StatefulWidget {
  final PlanRepository repository;

  const _MealPicker({required this.repository});

  @override
  State<_MealPicker> createState() => _MealPickerState();
}

class _MealPickerState extends State<_MealPicker> {
  List<MealChoice>? _meals;
  String? _problem;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  Future<void> _search(String q) async {
    try {
      final meals = await widget.repository.meals(q: q);
      if (!mounted) return;
      setState(() {
        _meals = meals;
        _problem = null;
      });
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem = "${e.headline}, so there is nothing to "
          'choose from.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meals = _meals;
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
            TextField(
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Which meal?',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            if (_problem != null)
              Text(_problem!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error))
            else if (meals != null && meals.isEmpty)
              Text(PlanDaySheet.noMeals,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline))
            else if (meals != null)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final meal in meals)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(meal.name),
                        subtitle: _kcalLine(context, meal),
                        onTap: () => Navigator.of(context).pop(meal),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget? _kcalLine(BuildContext context, MealChoice meal) {
    final figure = Figures.kcal(context, meal.kcal);
    return figure == null ? null : Text('$figure a portion');
  }
}
