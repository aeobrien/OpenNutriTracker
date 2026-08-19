import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

/// A meal on the week with no figure against it, and why.
///
/// The reason is carried, not just the count, because the two reasons are
/// fixed in two different places: one is the meal's own numbers, which anybody
/// can work out once; the other is this person saying how much of it is
/// theirs, which only they can. A single "unknown" would send them to the
/// wrong screen.
class AwaitingMeal {
  final int planId;
  final String title;
  final String why;

  const AwaitingMeal({
    required this.planId,
    required this.title,
    required this.why,
  });

  factory AwaitingMeal.fromJson(Map<String, dynamic> json) => AwaitingMeal(
        planId: json['plan_id'] as int,
        title: json['title'] as String,
        why: json['why'] as String,
      );
}

/// One day of the week, as one person's.
///
/// A day already gone carries what was eaten and nothing else. What was
/// planned for last Tuesday and never answered is not food anybody ate, and
/// the server does not send it — so a week that has happened stops moving.
class WeekDay {
  final String day;
  final bool past;
  final List<LoggedItem> logged;
  final List<PlannedItem> planned;
  final num eatenKcal;
  final num plannedKcal;
  final num exerciseKcal;
  final List<AwaitingMeal> awaiting;

  const WeekDay({
    required this.day,
    required this.past,
    this.logged = const [],
    this.planned = const [],
    this.eatenKcal = 0,
    this.plannedKcal = 0,
    this.exerciseKcal = 0,
    this.awaiting = const [],
  });

  /// Everything on this day that there is a figure for. Deliberately not
  /// "the day's calories": the meals in [awaiting] are part of the day and are
  /// not in here, and the screen has to say both.
  num get countedKcal => eatenKcal + plannedKcal;

  bool get isEmpty => logged.isEmpty && planned.isEmpty && awaiting.isEmpty;

  /// Which weekday this is, as one letter of the week's own strip. Worked out
  /// from the date the server sent rather than the phone's clock.
  DateTime get date => DateTime.parse(day);

  factory WeekDay.fromJson(Map<String, dynamic> json) => WeekDay(
        day: json['day'] as String,
        past: (json['past'] as bool?) ?? false,
        logged: ((json['entries'] as List?) ?? const [])
            .map((e) => LoggedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        planned: ((json['planned'] as List?) ?? const [])
            .map((e) => PlannedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        eatenKcal: (json['eaten_kcal'] as num?) ?? 0,
        plannedKcal: (json['planned_kcal'] as num?) ?? 0,
        exerciseKcal: (json['exercise_kcal'] as num?) ?? 0,
        awaiting: ((json['awaiting'] as List?) ?? const [])
            .map((e) => AwaitingMeal.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One person's week: seven days, and what they add up to so far.
///
/// The week is one person's and not the household's. The plan is shared; how
/// much of each meal is theirs is not, so the same Friday dinner is a
/// different number on each of their weeks. Assembled on the server in one
/// pass so the days and the total cannot disagree.
class WeekView {
  final String start;
  final String today;
  final int personId;
  final PersonSettings settings;
  final List<WeekDay> days;

  /// Eaten plus still-to-come across the week, counting only what there is a
  /// figure for.
  final num countedKcal;

  /// How many meals in the week have no figure. Never folded into
  /// [countedKcal] — that is the whole point of carrying it separately.
  final int awaitingCount;

  /// Seven days of this person's target, or null when they have not set one.
  /// Null rather than an invented allowance: a real total measured against a
  /// made-up goal is a number that means nothing.
  final int? targetKcal;

  const WeekView({
    required this.start,
    required this.today,
    required this.personId,
    required this.settings,
    this.days = const [],
    this.countedKcal = 0,
    this.awaitingCount = 0,
    this.targetKcal,
  });

  bool get hasTarget => targetKcal != null;

  bool get isEmpty => days.every((d) => d.isEmpty);

  /// Every meal on the week still waiting for a figure, in day order.
  List<AwaitingMeal> get awaiting =>
      [for (final day in days) ...day.awaiting];

  factory WeekView.fromJson(Map<String, dynamic> json) => WeekView(
        start: json['start'] as String,
        today: json['today'] as String,
        personId: json['person_id'] as int,
        settings:
            PersonSettings.fromJson(json['settings'] as Map<String, dynamic>),
        days: ((json['days'] as List?) ?? const [])
            .map((e) => WeekDay.fromJson(e as Map<String, dynamic>))
            .toList(),
        countedKcal: (json['counted_kcal'] as num?) ?? 0,
        awaitingCount: (json['awaiting_count'] as int?) ?? 0,
        targetKcal: json['target_kcal'] as int?,
      );
}
