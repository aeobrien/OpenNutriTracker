import 'package:opennutritracker/features/household/domain/household_person.dart';

/// Something this person has eaten. Already on the ledger; the figure on it is
/// the snapshot taken when it was logged, not a live lookup.
class LoggedItem {
  final String label;
  final num? kcal;
  final String? slot;
  final int ownerId;
  final int authorId;

  const LoggedItem({
    required this.label,
    required this.ownerId,
    required this.authorId,
    this.kcal,
    this.slot,
  });

  /// True when the other person put this on the day. Worth saying out loud on
  /// the row, because "who entered it" is a different question from "whose it
  /// is" and one of them explains a surprise.
  bool get enteredBySomebodyElse => authorId != ownerId;

  factory LoggedItem.fromJson(Map<String, dynamic> json) => LoggedItem(
        label: json['label'] as String,
        kcal: json['kcal'] as num?,
        slot: json['slot'] as String?,
        ownerId: json['owner_id'] as int,
        authorId: json['author_id'] as int,
      );
}

/// A meal the household has planned for this day, as this person's share of it.
///
/// Not on the ledger. Nothing here has been eaten, and this release does not
/// let it be confirmed — it sits on the day so the person can see what is
/// coming, which is the whole reason planned and logged have to look different.
class PlannedItem {
  final int planId;
  final String title;

  /// How many standard portions of the meal are this person's. Null when
  /// nobody has said, which is shown as unsaid rather than assumed to be one.
  final num? portions;

  /// This person's share in calories. Null when the portion is unknown or the
  /// meal's own numbers are — never zero, which would read as a free meal.
  final num? kcal;

  /// Whether the meal itself has numbers. Separates "we don't know the meal"
  /// from "nobody said how much of it is yours", which need different words.
  final bool mealKcalKnown;

  const PlannedItem({
    required this.planId,
    required this.title,
    this.portions,
    this.kcal,
    this.mealKcalKnown = false,
  });

  bool get portionKnown => portions != null;

  factory PlannedItem.fromJson(Map<String, dynamic> json) => PlannedItem(
        planId: json['plan_id'] as int,
        title: json['title'] as String,
        portions: json['portions'] as num?,
        kcal: json['kcal'] as num?,
        mealKcalKnown: (json['meal_kcal_known'] as bool?) ?? false,
      );
}

/// Exercise on the day, and where it came from.
class ExerciseItem {
  final num kcal;
  final String source; // 'health' | 'typed'
  final num? minutes;
  final String? note;

  const ExerciseItem({
    required this.kcal,
    required this.source,
    this.minutes,
    this.note,
  });

  bool get fromWatch => source == 'health';

  factory ExerciseItem.fromJson(Map<String, dynamic> json) => ExerciseItem(
        kcal: json['kcal'] as num,
        source: json['source'] as String,
        minutes: json['minutes'] as num?,
        note: json['note'] as String?,
      );
}

/// One person's day, whole: what they ate, what is still planned, the exercise
/// that moved it the other way, and where that leaves them against their own
/// target.
///
/// Assembled on the server and read here rather than being stitched together on
/// the phone, so the two handsets and the kitchen panel cannot drift into
/// telling different stories about the same day.
class DayView {
  final String day;
  final int personId;
  final PersonSettings settings;
  final List<LoggedItem> logged;
  final List<PlannedItem> planned;
  final List<ExerciseItem> exercise;
  final num eatenKcal;
  final num exerciseKcal;
  final num plannedKcal;

  /// How many planned meals could not be given a figure. Carried so the day can
  /// say "and two meals we don't have numbers for" instead of quietly adding
  /// nothing and looking complete.
  final int plannedUnknown;

  const DayView({
    required this.day,
    required this.personId,
    required this.settings,
    this.logged = const [],
    this.planned = const [],
    this.exercise = const [],
    this.eatenKcal = 0,
    this.exerciseKcal = 0,
    this.plannedKcal = 0,
    this.plannedUnknown = 0,
  });

  int? get targetKcal => settings.dailyTargetKcal;

  bool get hasTarget => settings.dailyTargetKcal != null;

  /// What is left of the target after what has been eaten, with exercise added
  /// back. Null when this person has not set a target — there is nothing to be
  /// left of, and inventing a default would be inventing a goal for them.
  num? get remainingKcal {
    final target = settings.dailyTargetKcal;
    if (target == null) return null;
    return target - eatenKcal + exerciseKcal;
  }

  bool get isEmpty => logged.isEmpty && planned.isEmpty && exercise.isEmpty;

  factory DayView.fromJson(Map<String, dynamic> json) => DayView(
        day: json['day'] as String,
        personId: json['person_id'] as int,
        settings:
            PersonSettings.fromJson(json['settings'] as Map<String, dynamic>),
        logged: ((json['entries'] as List?) ?? const [])
            .map((e) => LoggedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        planned: ((json['planned'] as List?) ?? const [])
            .map((e) => PlannedItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        exercise: ((json['exercise'] as List?) ?? const [])
            .map((e) => ExerciseItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        eatenKcal: (json['eaten_kcal'] as num?) ?? 0,
        exerciseKcal: (json['exercise_kcal'] as num?) ?? 0,
        plannedKcal: (json['planned_kcal'] as num?) ?? 0,
        plannedUnknown: (json['planned_unknown'] as int?) ?? 0,
      );
}
