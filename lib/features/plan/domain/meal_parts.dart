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

  /// Who chose this amount: 'said' when a person put it in, 'estimated' when
  /// it is still the helping the house guessed and nobody has looked at.
  ///
  /// The two look identical on screen — a number of grams beside a food — and
  /// only one of them is somebody's decision, so the screen has to be able to
  /// tell them apart. Null for a component with no part at all.
  final String? amountFrom;

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
    this.amountFrom,
    this.food,
  });

  /// Whether nobody has yet looked at how much of this goes in.
  bool get amountIsAGuess => amountFrom == 'estimated';

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
        amountFrom: json['amount_from'] as String?,
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

/// One part of a meal as the house proposes it, before anybody has agreed.
///
/// A built meal names its parts in the words somebody built it in — "chicken",
/// "pak choi", "sushi rice" — and filling those in meant searching for four
/// foods and typing four amounts before the meal could carry a figure at all.
/// A proposal is the house's answer to all of them at once: the food it thinks
/// each one means, and a guess at a normal helping.
///
/// **Nothing has been saved.** A proposal becomes a part when somebody accepts
/// it, and the amount it carries is recorded as a guess when they do, so a meal
/// filled in this way and never corrected cannot go on to claim its figure was
/// worked out from amounts somebody typed in.
class ProposedPart {
  /// The component this stands for — the meal's own word for it.
  final String component;

  /// Which part of the meal it is: 'protein', 'veg', 'carb'. What decides the
  /// size of the helping, since a normal helping of the protein and of the
  /// vegetable are different numbers.
  final String role;

  /// Whether somebody has already answered this component. Their answer stands
  /// and nothing is proposed against it.
  final bool already;

  /// The house's food this component most likely means, or null when the house
  /// has nothing like it and this one still needs looking up.
  final HouseholdFood? food;

  final num? qty;
  final String? unit;

  /// Where the amount came from — always 'estimated' on a proposal, because
  /// nobody has looked at it yet. Carried rather than assumed so that whatever
  /// accepts it passes on what it was told rather than what it expected.
  final String? amountFrom;

  /// The house's own sentence about this one: what it is proposing and why, or
  /// why it cannot propose anything.
  final String why;

  const ProposedPart({
    required this.component,
    required this.role,
    required this.already,
    required this.why,
    this.food,
    this.qty,
    this.unit,
    this.amountFrom,
  });

  /// Whether this is one somebody can accept. A component already answered and
  /// a component the house has no food for are both un-acceptable, for
  /// opposite reasons.
  bool get canBeAccepted => food != null && qty != null && !already;

  /// The proposal in the words it goes on screen in: "Chicken breast, 150 g".
  String get reads {
    final f = food?.name ?? component;
    final q = qty;
    if (q == null) return f;
    final tidy = q == q.roundToDouble() ? q.toInt().toString() : q.toString();
    return '$f, $tidy ${unit ?? 'g'}';
  }

  factory ProposedPart.fromJson(Map<String, dynamic> json) => ProposedPart(
        component: (json['component'] as String?) ?? '',
        role: (json['role'] as String?) ?? '',
        already: (json['already'] as bool?) ?? false,
        why: (json['why'] as String?) ?? '',
        qty: json['qty'] as num?,
        unit: json['unit'] as String?,
        amountFrom: json['amount_from'] as String?,
        food: json['food'] == null
            ? null
            : HouseholdFood.fromJson(json['food'] as Map<String, dynamic>),
      );
}

/// Everything the house proposes for one meal.
class MealProposals {
  /// False when the meal is not made of parts at all — a ready meal out of a
  /// packet, whose numbers are the packet's. Not an error; there is simply
  /// nothing here to propose.
  final bool ok;

  /// Why not, when [ok] is false.
  final String? why;

  final List<ProposedPart> proposed;

  const MealProposals({
    required this.ok,
    this.why,
    this.proposed = const [],
  });

  /// The ones somebody could accept in one go.
  List<ProposedPart> get acceptable =>
      [for (final p in proposed) if (p.canBeAccepted) p];

  /// The ones the house has nothing for, which still need looking up by hand.
  /// Named on screen rather than left out: these are what will still be
  /// holding the meal up after everything else has been accepted.
  List<ProposedPart> get needLookingUp =>
      [for (final p in proposed) if (p.food == null && !p.already) p];

  /// Whether there is anything here worth showing somebody.
  bool get hasAnything => proposed.isNotEmpty;

  factory MealProposals.fromJson(Map<String, dynamic> json) => MealProposals(
        ok: (json['ok'] as bool?) ?? false,
        why: json['why'] as String?,
        proposed: [
          for (final p in (json['proposed'] as List?) ?? const [])
            ProposedPart.fromJson(p as Map<String, dynamic>),
        ],
      );
}
