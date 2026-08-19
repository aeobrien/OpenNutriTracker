import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';
import 'package:opennutritracker/features/today/presentation/planned_meal_row.dart';

/// One thing this person has eaten.
///
/// Solid and filled, against the planned row's faded outline. The contrast is
/// the whole design: a day is a mix of the two and it has to be readable at a
/// glance which is which.
class LoggedItemRow extends StatelessWidget {
  final LoggedItem item;

  const LoggedItemRow({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: theme.colorScheme.surfaceContainerHighest,
      child: ListTile(
        title: Text(item.title),
        subtitle: item.subtitle == null ? null : Text(item.subtitle!),
        trailing: Figures.kcalText(context, item.kcal),
      ),
    );
  }
}

extension on LoggedItem {
  String get title => label;

  String? get subtitle {
    final parts = <String>[
      if (slot != null) slot![0].toUpperCase() + slot!.substring(1),
      if (enteredBySomebodyElse) 'Entered by the other phone',
    ];
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Today, as a list.
///
/// The day reads top to bottom: where this person stands, then what they have
/// eaten, then what is still planned. Planned things sit below the eaten ones
/// and are drawn differently, so the day never implies a meal has been had when
/// it has not.
///
/// Everything here belongs to one person — the one whose phone this is. The
/// other person's day is not shown, summarised, or added in.
class TodayScreen extends StatefulWidget {
  final DayRepository repository;

  /// Exercise, by either route. Optional only so a test can render the day
  /// without one; the running app always passes it. When it is here the watch
  /// is read once each time the day is opened, and the person is offered the
  /// typed route for whatever it missed.
  final ExerciseSync? sync;

  /// Opens the form for typing exercise in. Supplied by whoever mounts the
  /// screen, so this file does not have to know how the app navigates.
  final Future<void> Function(BuildContext context, String day)? onAddExercise;

  /// The day being shown, as 'YYYY-MM-DD'. Passed in rather than read from the
  /// clock so the screen can be shown for any day and so a test is not at the
  /// mercy of what time it is run.
  final String day;

  const TodayScreen({
    super.key,
    required this.repository,
    required this.day,
    this.sync,
    this.onAddExercise,
  });

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  DayView? _day;
  String? _problem;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TodayScreen old) {
    super.didUpdateWidget(old);
    if (old.day != widget.day) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    await _readTheWatch();
    try {
      final day = await widget.repository.today(widget.day);
      if (!mounted) return;
      setState(() {
        _day = day;
        _problem = null;
        _loading = false;
      });
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        // Deliberately not an empty day: a day with nothing on it is a claim
        // that this person has eaten nothing, and that is not what happened.
        _problem = "Can't reach the kitchen computer, so today isn't showing "
            'right now. Anything you log will be sent when it comes back. '
            '(${e.message})';
        _loading = false;
      });
    }
  }

  /// Ask the watch for today's active calories before showing the day.
  ///
  /// Deliberately quiet: a watch with nothing to say, a refused permission or
  /// an unreachable Mini are all ordinary, and none of them should stop the day
  /// being shown. The sync is safe to repeat — the id is worked out from the
  /// person and the day — so opening the screen twice does not double anything.
  Future<void> _readTheWatch() async {
    final sync = widget.sync;
    if (sync == null) return;
    try {
      await sync.syncFromHealth(day: widget.day);
    } catch (_) {
      // Nothing to tell the person: the day below is what matters, and the
      // typed route is offered whether or not the watch had anything.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final day = _day;
    if (day == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_problem ?? 'Today is not available.',
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }
    return FiguresScope(
      figuresOff: day.settings.figuresOff,
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            _Standing(day: day),
            const _SectionHeading('Eaten'),
            if (day.logged.isEmpty)
              const _Quiet('Nothing logged yet today.')
            else
              for (final item in day.logged) LoggedItemRow(item: item),
            const _SectionHeading('Exercise'),
            if (day.exercise.isEmpty)
              const _Quiet('Nothing from the watch yet today.')
            else
              for (final e in day.exercise) _ExerciseRow(item: e),
            if (widget.onAddExercise != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextButton.icon(
                  onPressed: () async {
                    await widget.onAddExercise!(context, widget.day);
                    await _load();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add exercise the watch missed'),
                ),
              ),
            const _SectionHeading('Still planned'),
            if (day.planned.isEmpty)
              const _Quiet('Nothing planned for today.')
            else
              for (final item in day.planned) PlannedMealRow(item: item),
          ],
        ),
      ),
    );
  }
}

/// Where this person stands against their own target.
class _Standing extends StatelessWidget {
  final DayView day;

  const _Standing({required this.day});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (Figures.off(context)) {
      // The one who does not want figures still wants to know the day is being
      // kept. It is — underneath — and saying so is not a number.
      return const Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text('Your day is being counted.'),
      );
    }
    final remaining = day.remainingKcal;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!day.hasTarget)
            const Text('No daily target set yet.')
          else ...[
            Figures.kcalText(context, remaining,
                style: theme.textTheme.headlineMedium, suffix: ' left'),
            const SizedBox(height: 4),
            Figures.kcalText(context, day.targetKcal, prefix: 'Target '),
          ],
          const SizedBox(height: 4),
          Figures.kcalText(context, day.eatenKcal, suffix: ' eaten'),
          if (day.exerciseKcal > 0)
            Figures.kcalText(context, day.exerciseKcal,
                prefix: 'Exercise gave back '),
          if (day.plannedKcal > 0)
            Figures.kcalText(context, day.plannedKcal,
                suffix: ' still planned'),
          if (day.plannedUnknown > 0)
            Text(
                day.plannedUnknown == 1
                    ? 'One planned meal is still awaiting its calories.'
                    : '${day.plannedUnknown} planned meals are still awaiting '
                        'their calories.',
                style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  final ExerciseItem item;

  const _ExerciseRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(item.note ??
          (item.fromWatch ? 'From your watch' : 'Exercise you typed in')),
      subtitle: Text(item.fromWatch ? 'Measured' : 'Typed in'),
      trailing: Figures.kcalText(context, item.kcal, prefix: '+'),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String text;

  const _SectionHeading(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(text, style: Theme.of(context).textTheme.titleSmall),
      );
}

class _Quiet extends StatelessWidget {
  final String text;

  const _Quiet(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Text(text),
      );
}
