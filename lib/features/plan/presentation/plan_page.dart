import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/shopping/data/shopping_repository.dart';
import 'package:opennutritracker/features/week/data/week_repository.dart';
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
/// It holds no state and decides nothing. The week is the screen; this is the
/// door.
class PlanPage extends StatefulWidget {
  const PlanPage({super.key});

  static const label = 'Plan';

  @override
  State<PlanPage> createState() => _PlanPageState();
}

class _PlanPageState extends State<PlanPage> {
  final _week = GlobalKey<WeekAheadSectionState>();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 48),
      child: WeekAheadSection(
        key: _week,
        repository: locator<WeekRepository>(),
        // Both passed, so a day opens onto controls that work. The section
        // leaves them out of the screen entirely when they are missing, which
        // on a tab whose whole purpose is planning would be a blank week with
        // no way to say so.

        planner: locator<PlanRepository>(),
        shopping: locator<ShoppingRepository>(),
        onPlanned: () => _week.currentState?.reload(),
      ),
    );
  }
}
