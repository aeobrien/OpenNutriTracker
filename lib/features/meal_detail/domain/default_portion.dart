/// What the amount box starts on, and why it starts there.
library;

import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// Where the number already in the amount box came from.
///
/// The reason is carried rather than recomputed by whoever displays it, because
/// a person seeing a figure they did not type needs to know whether it is a
/// fact about this packet, a memory of what they did last time, or a stand-in
/// for nothing at all. Those three warrant very different amounts of trust and
/// the screen cannot tell them apart from the number alone.
enum PortionSource {
  /// The amount they had of this same food last time.
  lastTime,

  /// One serving, as the pack itself defines a serving.
  packServing,

  /// One of them — one pie, one biscuit — because that is the unit the box
  /// opened in.
  oneOfThem,

  /// One whole pack, because that is the unit the box opened in.
  wholePack,

  /// Nobody has said. A round number, chosen so the box is not empty.
  aStandIn,
}

/// The starting amount, and where it came from.
class DefaultPortion {
  /// As it should appear in the box — a whole number where it is one, and one
  /// decimal place where it is not. "72.5" and not "72.5000000001".
  final String amount;
  final PortionSource source;

  const DefaultPortion(this.amount, this.source);

  /// What the screen says under the box. Deliberately a full short sentence
  /// rather than a label: "Serving" beside a number does not tell anybody
  /// whether it is the pack's idea of a serving or theirs.
  String get explanation {
    switch (source) {
      case PortionSource.lastTime:
        return 'The amount you had last time';
      case PortionSource.packServing:
        return "One serving, as the pack counts a serving";
      case PortionSource.oneOfThem:
        return 'One of them, worked out from what a pack weighs';
      case PortionSource.wholePack:
        return 'One whole pack, as the house has it weighed';
      case PortionSource.aStandIn:
        return 'A starting figure — nobody has said what a portion of this is';
    }
  }
}

/// Work out what the amount box should open on.
///
/// The order is the point. What they actually had last time beats what the pack
/// says a serving is, because the pack is describing a stranger; and both beat
/// a round number, which is only there so the box is never empty.
///
/// This was an unnamed chain of `if`s inside the screen's setup. It is pulled
/// out here so that the order can be tested, and so that the reason can travel
/// with the number instead of being lost the moment it is worked out.
DefaultPortion defaultPortionFor(
  MealEntity meal, {
  required bool usesImperialUnits,
  String? unit,
}) {
  // When the box is counting things rather than weighing them, the only
  // sensible opening amount is one of them. Everything below is in grams, and a
  // gram figure dropped into a box labelled "pack" reads as ninety-six packs of
  // biscuits — a number nobody would ever mean, sitting where a number they
  // might mean is expected.
  //
  // Only the two counted units added here are handled this way. "Serving" has
  // the same mismatch and is deliberately left alone: what the box opens on for
  // an ordinary food is an open question Aidan has been asked and has not yet
  // answered, and quietly settling half of it here would be answering it for
  // him.
  if (unit == 'item') return const DefaultPortion('1', PortionSource.oneOfThem);
  if (unit == 'pack') return const DefaultPortion('1', PortionSource.wholePack);

  final last = meal.lastUsedGrams;
  if (last != null && last > 0) {
    return DefaultPortion(_tidy(last), PortionSource.lastTime);
  }
  if (meal.hasServingValues) {
    return const DefaultPortion('1', PortionSource.packServing);
  }
  return DefaultPortion(
    usesImperialUnits ? '1' : '100',
    PortionSource.aStandIn,
  );
}

String _tidy(double grams) => grams == grams.roundToDouble()
    ? grams.toInt().toString()
    : grams.toStringAsFixed(1);
