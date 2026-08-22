/// What a meal is made of, as the phone reads it back from the house.
///
/// A meal on the plan has always been a name and a calorie figure. That is
/// enough to plan an evening around and not enough to trust: a figure with
/// nothing behind it cannot be checked, and the one that is wrong looks exactly
/// like the one that is right. The Mac Mini has recorded what each meal is made
/// of since it was built — which component, which of the house's own foods
/// stands for it, and how much goes in — and no phone code has ever asked.
///
/// Nothing here works out a weight or a calorie figure. Both arrive already
/// worked out, from the same arithmetic on the Mini that produces the meal's
/// total, so the parts on a screen and the total above them cannot disagree.
library;

import 'package:opennutritracker/features/household/domain/household_food.dart';

/// One component of a meal, and the food the house uses for it.
class MealPart {
  /// What the meal calls this slot — 'protein', 'carbohydrate', and so on.
  /// The panel's own words, not a second vocabulary invented here.
  final String component;

  /// The house's food standing in that slot, or null when nobody has chosen
  /// one. A component with no food is still a part of the meal — it is the
  /// commonest reason a meal has no total, and it is listed rather than
  /// skipped so that a screen can say so.
  final String? foodName;

  /// How much of it goes in, in [unit], as it was written down.
  final num? quantity;
  final String? unit;

  /// What that amount weighs, worked out on the Mini. Null when it could not
  /// be — a pack of something nobody has weighed.
  final num? grams;

  /// What this part contributes. Null when the weight is unknown, or when the
  /// house has the food but not its numbers. Never zero standing in for
  /// either: a part contributing nothing and a part nobody can count are
  /// different facts and a person fixes them in different places.
  final num? kcal;

  /// How much the food's own numbers can be trusted: 'weighed', 'typed',
  /// 'photo', 'guess'. A meal is only ever as good as its worst part.
  final String? trust;

  /// Why this part cannot be counted, in the house's own words, or null when
  /// it can be. This is the sentence the screen shows instead of a figure.
  final String? why;

  /// The house's food itself, whole — its pack weight, its count, its numbers
  /// — so that opening this part to log it opens the food the meal actually
  /// uses. Looking it back up by name would find the wrong tin the first time
  /// two of them are named alike. Null for a component nobody has chosen a
  /// food for.
  final HouseholdFood? food;

  const MealPart({
    required this.component,
    this.foodName,
    this.quantity,
    this.unit,
    this.grams,
    this.kcal,
    this.trust,
    this.why,
    this.food,
  });

  /// Whether this part is one of the ones holding the meal's total up.
  bool get isAGap => why != null;

  /// How much of it goes in, said the way it is written on the plan.
  ///
  /// Null rather than a stand-in phrase, so the screen decides how to say a
  /// gap. A quantity with no unit is still worth showing — "2" beside a food
  /// is more than nothing — but a unit with no quantity is not.
  String? get howMuch {
    final q = quantity;
    if (q == null) return null;
    final tidy = q == q.roundToDouble() ? q.toInt().toString() : q.toString();
    return unit == null || unit!.isEmpty ? tidy : '$tidy $unit';
  }

  factory MealPart.fromJson(Map<String, dynamic> json) => MealPart(
        component: (json['component'] as String?) ?? '',
        foodName: json['food_name'] as String?,
        quantity: json['qty'] as num?,
        unit: json['unit'] as String?,
        grams: json['grams'] as num?,
        kcal: json['kcal'] as num?,
        trust: json['trust'] as String?,
        why: json['why'] as String?,
        food: json['food'] == null
            ? null
            : HouseholdFood.fromJson(json['food'] as Map<String, dynamic>),
      );
}

/// What came of asking the house to add a meal up.
///
/// A refusal is an ordinary answer here, not a failure: a meal nobody has
/// finished describing cannot be added up, and the useful thing to say is
/// which part is missing. Treating that as an error would put a red message in
/// front of somebody whose meal is simply half-written.
class MealWorkedOut {
  final bool ok;

  /// One standard portion, when it could be worked out.
  final num? kcal;
  final String? trust;

  /// Why not, in the house's own words, and which components are holding it
  /// up — each with its own reason, because "no food chosen" and "the food
  /// has no numbers" are fixed in different places.
  final String? why;
  final List<MealPart> awaiting;

  const MealWorkedOut({
    required this.ok,
    this.kcal,
    this.trust,
    this.why,
    this.awaiting = const [],
  });

  factory MealWorkedOut.fromJson(Map<String, dynamic> json) => MealWorkedOut(
        ok: (json['ok'] as bool?) ?? false,
        kcal: (json['nutrition'] as Map<String, dynamic>?)?['calories'] as num?,
        trust: json['trust'] as String?,
        why: json['why'] as String?,
        awaiting: [
          for (final a in (json['awaiting'] as List?) ?? const [])
            MealPart(
              component: (a as Map<String, dynamic>)['component'] as String,
              why: a['why'] as String?,
            ),
        ],
      );
}

/// Everything a meal is made of, in the order the house lists it.
class MealMadeOf {
  final int mealId;
  final String? name;
  final List<MealPart> parts;

  /// The meal's own stored figure for one standard portion, or null when it
  /// has never been worked out. Null all the way through rather than zero.
  final num? kcal;

  /// The weakest trust of any part it was built from, as the Mini recorded it
  /// when the figure was stored.
  final String? trust;

  /// Where the figure came from — 'parts' when it was added up from these.
  final String? from;

  const MealMadeOf({
    required this.mealId,
    this.name,
    this.parts = const [],
    this.kcal,
    this.trust,
    this.from,
  });

  /// Whether this meal is described by parts at all. A ready meal bought in a
  /// box has none, and that is an ordinary fact about it rather than a gap —
  /// its numbers come off the packet.
  bool get isMadeOfParts => parts.isNotEmpty;

  /// The parts holding the meal's figure up. These are named on the screen,
  /// rather than leaving somebody to work out which one is missing.
  List<MealPart> get awaiting => [for (final p in parts) if (p.isAGap) p];

  /// What the parts come to, added up here. Deliberately separate from [kcal],
  /// which is what the house last stored: they agree only when the meal has
  /// been worked out since its parts last changed, and the one screen showing
  /// both is where somebody would notice that it has not been.
  ///
  /// Null when any part cannot be counted, because a total that quietly omits
  /// the broccoli is a total somebody will believe.
  num? get partsComeTo {
    if (!isMadeOfParts || awaiting.isNotEmpty) return null;
    return parts.fold<num>(0, (sum, p) => sum + (p.kcal ?? 0));
  }

  factory MealMadeOf.fromJson(int mealId, Map<String, dynamic> json) =>
      MealMadeOf(
        mealId: mealId,
        name: json['name'] as String?,
        parts: [
          for (final e in (json['made_of'] as List?) ?? const [])
            MealPart.fromJson(e as Map<String, dynamic>),
        ],
        kcal: json['kcal'] as num?,
        trust: json['trust'] as String?,
        from: json['from'] as String?,
      );
}
