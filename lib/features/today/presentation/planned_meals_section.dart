import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';
import 'package:opennutritracker/features/today/presentation/planned_meal_row.dart';

/// What the household has planned for this person today, on the screen they
/// already look at.
///
/// This used to be most of a second tab. There was a Home tab that showed the
/// day and a Today tab that showed the day, and Aidan spent a test looking at
/// one and reporting the other as broken. In his words: *"the 'home' tab
/// already functions as a 'today' tab, so we should really be working within
/// the version of that which already exists rather than adding something
/// new."* So the planned meals — the one thing Home genuinely did not have —
/// moved onto Home, and the second tab went.
///
/// Three states, kept apart on purpose:
///
///  * **Something planned** — the rows, under a heading.
///  * **Nothing planned** — nothing at all. Not a heading with an empty space
///    under it. A day with no plan should leave Home looking exactly as it did
///    before this existed.
///  * **Could not ask** — one quiet line. "Nothing is planned" and "I could not
///    find out what is planned" are different facts, and showing the first when
///    the second is true is the mistake this whole release is about.
class PlannedMealsSection extends StatefulWidget {
  final DayRepository repository;

  /// Puts the answer on the queue. Optional only so a test can mount the
  /// section read-only; Home always passes it, and without it the row shows no
  /// buttons rather than showing buttons that do nothing.
  final HouseholdLogger? logger;

  /// Called after an answer is given, so the screen around this can redraw —
  /// eating a planned dinner changes what is left of the day.
  final VoidCallback? onDecided;

  /// The day, as 'YYYY-MM-DD'. Passed in rather than read from the clock so a
  /// test is not at the mercy of what time it runs.
  final String day;

  const PlannedMealsSection({
    super.key,
    required this.repository,
    required this.day,
    this.logger,
    this.onDecided,
  });

  /// What today is called, in the form the server uses.
  static String dayKey(DateTime now) => '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  @override
  State<PlannedMealsSection> createState() => PlannedMealsSectionState();
}

class PlannedMealsSectionState extends State<PlannedMealsSection> {
  List<PlannedItem>? _planned;
  String? _problem;

  /// Meals answered on this phone whose answer has not reached the Mac Mini
  /// yet. The queue will deliver it; until it does the server still calls the
  /// meal planned, and showing it again would be asking somebody to confirm
  /// their dinner twice. Kept here rather than pretended into the server's
  /// answer, so the two facts stay separate.
  final _answered = <int>{};

  final _log = Logger('PlannedMealsSection');

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(covariant PlannedMealsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day) reload();
  }

  /// Ask the household again. Called by Home whenever it reloads, so logging a
  /// meal and seeing the planned row that matches it disappear happens in one
  /// motion rather than needing the app restarted.
  Future<void> reload() async {
    try {
      final day = await widget.repository.today(widget.day);
      if (!mounted) return;
      setState(() {
        _planned =
            day.planned.where((p) => !_answered.contains(p.planId)).toList();
        _problem = null;
      });
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem = '${e.headline}, so what is planned for today '
          "isn't showing.");
    } on StateError {
      // Nobody has said whose phone this is yet. The app asks that before it
      // opens, so this only happens in the moment before the answer lands —
      // and an error on Home about it would be noise, not news.
      if (!mounted) return;
      setState(() => _planned = const []);
    }
  }

  /// Record what they did about a planned meal.
  ///
  /// The row goes as soon as they tap, before the Mini has heard. That is not
  /// optimism about the network — the answer is on the queue, which is where
  /// every other write on this phone waits too, and the queue's whole promise
  /// is that it arrives. What would be dishonest is the opposite: leaving a
  /// meal on the day looking undecided when the person has decided.
  Future<void> _decide(PlannedItem item, bool ate) async {
    final logger = widget.logger;
    if (logger == null) return;
    setState(() {
      _answered.add(item.planId);
      _planned = _planned?.where((p) => p.planId != item.planId).toList();
    });
    try {
      await logger.decidePlan(planId: item.planId, ate: ate);
    } catch (e) {
      // Putting work on the queue is a local write and should not fail. If it
      // somehow did, the meal has to come back — a decision the person made
      // that nothing recorded is worse than asking them again.
      _log.warning('[PLAN] could not queue the answer for ${item.planId}: $e');
      if (!mounted) return;
      setState(() => _answered.remove(item.planId));
      await reload();
      return;
    }
    widget.onDecided?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final problem = _problem;
    if (problem != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(problem,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline)),
      );
    }
    final planned = _planned;
    if (planned == null || planned.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Planned today', style: theme.textTheme.titleSmall),
        ),
        for (final item in planned)
          PlannedMealRow(
            item: item,
            onAte: widget.logger == null ? null : () => _decide(item, true),
            onNotEaten: widget.logger == null ? null : () => _decide(item, false),
          ),
      ],
    );
  }
}
