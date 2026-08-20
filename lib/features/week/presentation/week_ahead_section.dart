import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/presentation/plan_day_sheet.dart';
import 'package:opennutritracker/features/week/data/week_repository.dart';
import 'package:opennutritracker/features/week/domain/week_view.dart';

/// The week, on the screen this person already looks at.
///
/// A view and not a second planner. It shows what the household has planned
/// and what has already been eaten, seven days at a time, and it changes
/// nothing — the planning itself stays where it has always been, on the
/// kitchen panel.
///
/// The one thing it has to get right is the gap. A day with a dinner nobody
/// has worked out the calories for reads as *"1,400 so far, and one meal we
/// don't have numbers for"* — never as 1,400, and never as a number quietly
/// containing a zero where the dinner should be. That is the whole reason the
/// server carries the count of what it could not count.
///
/// It is now also the way into planning: tapping a day opens that day's plan.
/// Not a second planner — the same plan the kitchen panel keeps, opened from
/// the day you are already looking at rather than from a tab of its own.
class WeekAheadSection extends StatefulWidget {
  final WeekRepository repository;

  /// Changing the plan, when this phone is allowed to. Optional only so a test
  /// can mount the week read-only; Home always passes it, and without it a day
  /// simply does not open rather than opening onto controls that do nothing.
  final PlanRepository? planner;

  /// Called after the plan changes, so the screen around this can redraw —
  /// putting tonight's dinner on the plan changes what today looks like.
  final VoidCallback? onPlanned;

  /// The Monday, as 'YYYY-MM-DD', or null for the week today is in. Passed in
  /// rather than read from the clock so a test is not at the mercy of what day
  /// it runs.
  final String? start;

  const WeekAheadSection({
    super.key,
    required this.repository,
    this.start,
    this.planner,
    this.onPlanned,
  });

  static const heading = 'This week';
  static const nothingYet = 'Nothing on the week yet.';

  /// What the day is called on its row. The date comes from the server, so
  /// this is the phone's only say in the matter.
  static const dayNames = [
    'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
  ];

  /// The honest sentence. Plural handled here rather than in three places.
  static String awaitingLine(int count) => count == 1
      ? "and one meal we don't have numbers for"
      : "and $count meals we don't have numbers for";

  @override
  State<WeekAheadSection> createState() => WeekAheadSectionState();
}

class WeekAheadSectionState extends State<WeekAheadSection> {
  WeekView? _week;
  String? _problem;

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void didUpdateWidget(covariant WeekAheadSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.start != widget.start) reload();
  }

  Future<void> reload() async {
    try {
      final week = await widget.repository.mine(start: widget.start);
      if (!mounted) return;
      setState(() {
        _week = week;
        _problem = null;
      });
    } on HouseholdUnreachable catch (e) {
      // "Nothing is planned" and "I could not find out what is planned" are
      // different facts, and showing the first when the second is true is the
      // mistake this whole release is about.
      if (!mounted) return;
      setState(() => _problem = "${e.headline}, so the week isn't showing.");
    } on StateError {
      // Nobody has said whose phone this is yet. The app asks before it opens,
      // so this is the moment before the answer lands — news to nobody.
      if (!mounted) return;
      setState(() => _week = null);
    }
  }

  /// Open one day's plan. The week only asks the kitchen computer again if
  /// something actually changed — closing a sheet you only looked at should
  /// not cost a round trip.
  Future<void> _plan(String day) async {
    final planner = widget.planner;
    if (planner == null) return;
    final changed = await PlanDaySheet.show(
      context,
      repository: planner,
      day: day,
    );
    if (!changed || !mounted) return;
    await reload();
    widget.onPlanned?.call();
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
    final week = _week;
    if (week == null) return const SizedBox.shrink();
    // A week with nothing on it shows nothing — Home should look exactly as it
    // did before this existed. Except when this phone can plan: the week is
    // now the way in, and a week with nothing on it is precisely when somebody
    // wants to put something on it. Hiding the days then would leave nothing
    // to tap and no way to start.
    if (week.isEmpty && widget.planner == null) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(WeekAheadSection.heading,
              style: theme.textTheme.titleSmall),
        ),
        for (final day in week.days)
          _DayRow(
            day: day,
            today: week.today,
            onTap: widget.planner == null ? null : () => _plan(day.day),
          ),
        _WeekFooter(week: week),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  final WeekDay day;
  final String today;
  final VoidCallback? onTap;

  const _DayRow({required this.day, required this.today, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = day.day == today;
    final counted = Figures.kcal(context, day.countedKcal);
    final meals = [
      for (final item in day.logged) item.label,
      for (final item in day.planned) item.title,
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: Text(
              WeekAheadSection.dayNames[day.date.weekday - 1],
              style: isToday
                  ? theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold)
                  : theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(meals.isEmpty ? '—' : meals.join(', '),
                    style: theme.textTheme.bodyMedium),
                // The gap, said on the day it belongs to. Suppressed with
                // every other figure when this person has them switched off:
                // a count of missing numbers is still a number, and somebody
                // who asked not to see calories has not asked to be told how
                // many of them are unaccounted for.
                if (day.awaiting.isNotEmpty && !Figures.off(context))
                  Text(WeekAheadSection.awaitingLine(day.awaiting.length),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.outline)),
              ],
            ),
          ),
          if (counted != null)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(counted, style: theme.textTheme.bodyMedium),
            ),
        ],
      ),
      ),
    );
  }
}

class _WeekFooter extends StatelessWidget {
  final WeekView week;

  const _WeekFooter({required this.week});

  @override
  Widget build(BuildContext context) {
    if (Figures.off(context)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final counted = Figures.kcal(context, week.countedKcal);
    if (counted == null) return const SizedBox.shrink();
    final target = week.targetKcal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // The target half is dropped entirely when there is no target,
            // rather than compared against an invented one.
            target == null
                ? '$counted this week'
                : '$counted this week of ${Figures.kcal(context, target)}',
            style: theme.textTheme.bodyMedium,
          ),
          if (week.awaitingCount > 0)
            Text(WeekAheadSection.awaitingLine(week.awaitingCount),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
        ],
      ),
    );
  }
}
