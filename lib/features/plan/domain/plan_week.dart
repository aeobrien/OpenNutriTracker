/// The household's planned week, as the phone sees it when it is about to
/// change it.
///
/// Deliberately not the same thing as a person's week. A person's week answers
/// *what am I eating and what does it come to*; this answers *what is the
/// house planning* — the same rows, carrying everybody's share and everybody's
/// answer. You read the first; you edit the second.
library;

/// One meal on the plan.
class PlannedMeal {
  final int planId;
  final String date;
  final String title;
  final String? kind;
  final int? mealId;

  /// Calories for one standard portion, or null when the meal's numbers have
  /// not been worked out. Null all the way through rather than a zero: a meal
  /// awaiting its figures has to read as awaiting them.
  final num? mealKcal;
  final String? mealKcalTrust;

  /// How much of this meal each person is down for, keyed by person id. A
  /// missing or null value means nobody has said — which is not the same as
  /// none, and the two are kept apart everywhere they are shown.
  final Map<int, num?> portions;

  /// What each person has said about this meal: 'ate', 'skipped', or absent
  /// for not yet answered.
  final Map<int, String?> decided;

  const PlannedMeal({
    required this.planId,
    required this.date,
    required this.title,
    this.kind,
    this.mealId,
    this.mealKcal,
    this.mealKcalTrust,
    this.portions = const {},
    this.decided = const {},
  });

  /// Whether anybody has already answered for this meal.
  ///
  /// This is the one fact the planner has to check before offering to take a
  /// meal off: removing a meal one of them has already eaten and logged does
  /// not un-eat it, so the plan and the day would then disagree about the same
  /// dinner with nothing on screen saying why.
  bool get anybodyAnswered => decided.values.any((s) => s != null);

  static Map<int, T?> _byPerson<T>(Map<String, dynamic>? raw) {
    if (raw == null) return const {};
    final out = <int, T?>{};
    raw.forEach((key, value) {
      final id = int.tryParse(key);
      // The server keys these by person id as a string, because that is what
      // JSON would make of an integer key anyway. A key that is not a number
      // is not a person, so it is dropped rather than guessed at.
      if (id != null) out[id] = value as T?;
    });
    return out;
  }

  factory PlannedMeal.fromJson(Map<String, dynamic> json) => PlannedMeal(
        planId: json['plan_id'] as int,
        date: json['date'] as String,
        title: json['title'] as String,
        kind: json['kind'] as String?,
        mealId: json['meal_id'] as int?,
        mealKcal: json['meal_kcal'] as num?,
        mealKcalTrust: json['meal_kcal_trust'] as String?,
        portions:
            _byPerson<num>(json['portions'] as Map<String, dynamic>?),
        decided:
            _byPerson<String>(json['decided'] as Map<String, dynamic>?),
      );
}

/// One day of the household's plan.
class PlanDay {
  final String day;
  final bool past;
  final List<PlannedMeal> planned;

  const PlanDay({
    required this.day,
    this.past = false,
    this.planned = const [],
  });

  DateTime get date => DateTime.parse(day);

  factory PlanDay.fromJson(Map<String, dynamic> json) => PlanDay(
        day: json['day'] as String,
        past: (json['past'] as bool?) ?? false,
        planned: ((json['planned'] as List?) ?? const [])
            .map((e) => PlannedMeal.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Seven days of the household's plan.
class PlanWeek {
  final String start;
  final String end;
  final String today;
  final List<PlanDay> days;

  const PlanWeek({
    required this.start,
    required this.end,
    required this.today,
    this.days = const [],
  });

  /// The day matching [day], or an empty one. An empty day is a real answer —
  /// nothing is planned — so it is returned rather than thrown over.
  PlanDay dayFor(String day) => days.firstWhere(
        (d) => d.day == day,
        orElse: () => PlanDay(day: day, past: day.compareTo(today) < 0),
      );

  factory PlanWeek.fromJson(Map<String, dynamic> json) => PlanWeek(
        start: json['start'] as String,
        end: json['end'] as String,
        today: json['today'] as String,
        days: ((json['days'] as List?) ?? const [])
            .map((e) => PlanDay.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// One of the house's meals, as the picker shows it.
class MealChoice {
  final int id;
  final String name;
  final String? kind;
  final num? kcal;
  final String? kcalTrust;
  final String? lastEaten;
  final bool favourite;

  const MealChoice({
    required this.id,
    required this.name,
    this.kind,
    this.kcal,
    this.kcalTrust,
    this.lastEaten,
    this.favourite = false,
  });

  factory MealChoice.fromJson(Map<String, dynamic> json) => MealChoice(
        id: json['id'] as int,
        name: json['name'] as String,
        kind: json['kind'] as String?,
        kcal: json['kcal'] as num?,
        kcalTrust: json['kcal_trust'] as String?,
        lastEaten: json['last_eaten'] as String?,
        favourite: (json['favourite'] as bool?) ?? false,
      );
}
