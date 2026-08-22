/// What a meal is made of, as the phone reads it back from the house.
///
/// A meal on the plan has always been a name and a calorie figure. That is
/// enough to plan an evening around and not enough to trust: a figure with
/// nothing behind it cannot be checked, and the one that is wrong looks exactly
/// like the one that is right. The Mac Mini has recorded what each meal is made
/// of since it was built — which component, which of the house's own foods
/// stands for it, and how much goes in — and no phone code has ever asked.
library;

/// One component of a meal, and the food the house uses for it.
class MealPart {
  /// What the meal calls this slot — 'protein', 'carbohydrate', and so on.
  /// The panel's own words, not a second vocabulary invented here.
  final String component;

  /// The house's food standing in that slot.
  final String foodName;

  /// How much of it goes in, in [unit]. Null when nobody has said, which is
  /// not the same as none — a part with no quantity is why a meal's figure is
  /// still awaiting rather than wrong.
  final num? quantity;
  final String? unit;

  /// Calories per 100g of the food itself, or null when the house has the food
  /// but not its numbers.
  final num? kcal100;

  /// How much the food's own numbers can be trusted: 'weighed', 'typed',
  /// 'photo', 'guess'. A meal is only ever as good as its worst part.
  final String? trust;

  const MealPart({
    required this.component,
    required this.foodName,
    this.quantity,
    this.unit,
    this.kcal100,
    this.trust,
  });

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

  factory MealPart.fromJson(String component, Map<String, dynamic> json) =>
      MealPart(
        component: component,
        foodName: (json['food_name'] as String?) ?? '',
        quantity: json['qty'] as num?,
        unit: json['unit'] as String?,
        kcal100: json['kcal_100'] as num?,
        trust: json['trust'] as String?,
      );
}

/// Everything a meal is made of, in the order the house lists it.
class MealMadeOf {
  final int mealId;
  final List<MealPart> parts;

  const MealMadeOf({required this.mealId, this.parts = const []});

  /// Whether this meal is described by parts at all. A ready meal bought in a
  /// box has none, and that is an ordinary fact about it rather than a gap —
  /// its numbers come off the packet.
  bool get isMadeOfParts => parts.isNotEmpty;

  /// The parts nobody has said a quantity for. These are exactly the ones
  /// holding a meal's figure up, so the screen can name them rather than
  /// leaving somebody to work out which one is missing.
  List<MealPart> get awaiting =>
      [for (final p in parts) if (p.quantity == null || p.kcal100 == null) p];

  factory MealMadeOf.fromJson(int mealId, Map<String, dynamic> json) {
    final raw = (json['parts'] as Map<String, dynamic>?) ?? const {};
    return MealMadeOf(
      mealId: mealId,
      parts: [
        for (final entry in raw.entries)
          MealPart.fromJson(entry.key, entry.value as Map<String, dynamic>),
      ],
    );
  }
}
