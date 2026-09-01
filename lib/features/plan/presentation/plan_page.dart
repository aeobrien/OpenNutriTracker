import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/shopping/data/shopping_repository.dart';
import 'package:opennutritracker/features/week/data/week_repository.dart';
import 'package:opennutritracker/features/week/domain/week_view.dart';
import 'package:opennutritracker/features/week/presentation/week_ahead_section.dart';

/// The Plan tab — a door of its own into the week.
///
/// Four things were built in release 6 and reachable from nowhere: a planned
/// meal's own screen, building a meal out of its parts, its calories worked
/// out from those parts, and your own share of it. All four open from a day on
/// the week, and the week was taken off Home on 20 August. Built, tested,
/// installed and unreachable.
///
/// Aidan, 23 August 2026, asked whether to give them a way in: *"Yes, give
/// them their own menu item on the bottom of the screen."* So this is that —
/// its own tab, not the Home section coming back. Taking the week off Home
/// stands; what was wrong was that nothing replaced it.
///
/// It now holds one piece of state and only one: which week is showing. Until
/// 1 September 2026 it held none, which meant the tab could only ever show the
/// week you were standing in — *"The plan page only ever shows this week … I
/// can only view the week that I'm currently on."* A planner you cannot point
/// at next week is not a planner.
class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  static const label = 'Plan';

  /// What the arrows and the way back are called, for anyone reading them out
  /// or testing them.
  static const previousWeek = 'Previous week';
  static const nextWeek = 'Next week';
  static const thisWeek = 'This week';

  @override
  State<PlanPage> createState() => PlanPageState();
}

class PlanPageState extends State<PlanPage> {
  final _week = GlobalKey<WeekAheadSectionState>();

  /// The Monday being shown, as 'YYYY-MM-DD', or null for "whichever week the
  /// Mac Mini says today is in". Null is the starting state and the thing
  /// [showThisWeek] goes back to: the two handsets and the kitchen panel have
  /// to agree about where a week starts, and only the Mini can settle that.
  String? _start;

  /// The week currently on screen. Kept so the heading can name it and the
  /// arrows can step from the Monday the server actually sent, rather than
  /// from one this phone worked out and might disagree about.
  WeekView? _showing;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  /// 'Mon 1 – Sun 7 September'. The month is said once when both ends share
  /// it, and on both when a week straddles two.
  static String range(DateTime monday) {
    final sunday = monday.add(const Duration(days: 6));
    final from = monday.month == sunday.month
        ? '${monday.day}'
        : '${monday.day} ${_months[monday.month - 1]}';
    return '$from – ${sunday.day} ${_months[sunday.month - 1]}';
  }

  DateTime? get _monday {
    final showing = _showing;
    return showing == null ? null : DateTime.parse(showing.start);
  }

  /// Whether the week on screen is the one today falls in. Worked out from the
  /// server's own idea of today, which is the same one that decided the week.
  bool get _isThisWeek {
    final showing = _showing;
    if (showing == null) return true;
    final today = DateTime.parse(showing.today);
    final monday = DateTime.parse(showing.start);
    return !today.isBefore(monday) &&
        today.isBefore(monday.add(const Duration(days: 7)));
  }

  void _step(int weeks) {
    final monday = _monday;
    if (monday == null) return;
    _show(monday.add(Duration(days: 7 * weeks)));
  }

  void _show(DateTime day) {
    final monday = day.subtract(Duration(days: day.weekday - 1));
    setState(() => _start =
        '${monday.year.toString().padLeft(4, '0')}-'
        '${monday.month.toString().padLeft(2, '0')}-'
        '${monday.day.toString().padLeft(2, '0')}');
  }

  /// Back to the week today is in — and back to letting the Mac Mini say which
  /// one that is.
  void showThisWeek() => setState(() => _start = null);

  /// Jump to the week a chosen date falls in. Called from the calendar in the
  /// top-left of this tab, which until now was a picture: it sat in the slot a
  /// back button sits in, looked exactly like a button, and had nothing behind
  /// it. Aidan, 1 September 2026: *"There is a calendar button in the top left
  /// but tapping it does nothing."*
  Future<void> pickWeek() async {
    final monday = _monday ?? DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: monday,
      firstDate: DateTime(monday.year - 2),
      lastDate: DateTime(monday.year + 2),
      helpText: 'Which week?',
    );
    if (chosen == null || !mounted) return;
    _show(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final monday = _monday;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Which week, and the way to another one. Above the week rather than
          // below it: it is the first thing to read and the answer to "where
          // am I".
          Row(
            children: [
              IconButton(
                onPressed: monday == null ? null : () => _step(-1),
                tooltip: PlanPage.previousWeek,
                icon: const Icon(Icons.chevron_left),
              ),
              Expanded(
                child: Text(
                  monday == null ? '' : range(monday),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              IconButton(
                onPressed: monday == null ? null : () => _step(1),
                tooltip: PlanPage.nextWeek,
                icon: const Icon(Icons.chevron_right),
              ),
            ],
          ),
          // Only when it would do something. A way back to a week you are
          // already on is a control that has to be read before it can be
          // ignored.
          if (!_isThisWeek)
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: showThisWeek,
                child: const Text(PlanPage.thisWeek),
              ),
            ),
          WeekAheadSection(
            key: _week,
            repository: locator<WeekRepository>(),
            start: _start,
            // Both passed, so a day opens onto controls that work. The section
            // leaves them out of the screen entirely when they are missing, which
            // on a tab whose whole purpose is planning would be a blank week with
            // no way to say so.

            planner: locator<PlanRepository>(),
            shopping: locator<ShoppingRepository>(),
            onPlanned: () => _week.currentState?.reload(),
            onLoaded: (week) {
              if (!mounted) return;
              setState(() => _showing = week);
            },
          ),
        ],
      ),
    );
  }
}
