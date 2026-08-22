/// The four short lists a meal gets built from.
///
/// The whole reason a builder beats typing a meal's name is that the lists are
/// short, and they are short because they are what this house has actually
/// cooked rather than a catalogue of what exists. All of that judgement lives
/// on the Mac Mini, in the pairing graph it has been filling since the kitchen
/// panel was built. Nothing here ranks or filters anything; it reads.
///
/// The two tiers are kept apart rather than merged. `recommended` is what has
/// gone with this thing cooked this way; `general` is what has gone with it
/// when nobody said how it was cooked. Flattening them would lose the ordering
/// the house earned — the combinations it has had before, offered first.
library;

/// One slot's options, in the order they should be offered.
class PartOptions {
  final List<String> recommended;
  final List<String> general;

  const PartOptions({this.recommended = const [], this.general = const []});

  factory PartOptions.fromJson(Map<String, dynamic> json) => PartOptions(
        recommended: _strings(json['recommended']),
        general: _strings(json['general']),
      );

  /// Everything offered, recommended first, with nothing said twice.
  List<String> get inOrder {
    final seen = <String>{};
    return [
      for (final one in [...recommended, ...general])
        if (seen.add(one)) one,
    ];
  }

  bool get isEmpty => inOrder.isEmpty;
}

/// What the builder can offer, given what has been chosen so far.
class MealOptions {
  final List<String> proteins;
  final List<String> preps;
  final PartOptions veg;
  final PartOptions carb;

  const MealOptions({
    this.proteins = const [],
    this.preps = const [],
    this.veg = const PartOptions(),
    this.carb = const PartOptions(),
  });

  factory MealOptions.fromJson(Map<String, dynamic> json) => MealOptions(
        proteins: _strings(json['proteins']),
        preps: _strings(json['preps']),
        veg: PartOptions.fromJson(
            (json['veg'] as Map?)?.cast<String, dynamic>() ?? const {}),
        carb: PartOptions.fromJson(
            (json['carb'] as Map?)?.cast<String, dynamic>() ?? const {}),
      );
}

List<String> _strings(dynamic raw) => raw is List
    ? [
        for (final one in raw)
          if (one != null && '$one'.trim().isNotEmpty) '$one'.trim(),
      ]
    : const [];
