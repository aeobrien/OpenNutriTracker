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
  /// This person's share of the meal, as the household has it recorded.
  householdPortion,

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
      case PortionSource.householdPortion:
        return 'Your portion of this meal, as the household has it';
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

/// The units that count things rather than weigh them. A figure in one of these
/// boxes means "this many of them", so a gram figure dropped in raw reads as
/// ninety-six packs of biscuits.
const _countingUnits = {'serving', 'item', 'pack'};

/// Work out what the amount box should open on.
///
/// The order is Aidan's, settled on 22 August 2026 when he was asked whether
/// the household's own portion, the amount he had last time, or the packet
/// should come first, and answered "agreed" to this one:
///
///   1. **This person's portion of the meal, as the household has it.**
///      Somebody in the house sat down and said how much of this is his. That
///      beats anything worked out or remembered.
///   2. **The amount he had of this food last time.** A fact about him, where
///      the pack's serving is a stranger's idea of a portion.
///   3. **The pack** — its own stated serving, else one of them, else one whole
///      pack, whichever the box is counting in.
///
///   …and a round number underneath all three, so the box is never empty.
///
/// [householdPortion] is that first step, in grams. Nothing supplies it yet: a
/// household portion is a share of a *planned meal*, and the screen that shows
/// a meal's parts and each person's portion of it is not built. Until it is,
/// this is null on every real screen and the box starts on last time — which is
/// the same behaviour as before, and the reason it is worth having the step
/// here rather than adding it later and hoping the order comes out right.
///
/// [gramsPerUnit] is what one of whatever the box is counting in weighs — 25
/// for a 25 g serving, 125 for one of four pies in a 500 g box, 1 for grams.
/// The first two steps are gram figures and the box may not be in grams, so
/// they are divided through it. Without that, "the amount you had last time"
/// arrives in a box labelled "pack" as ninety-six packets, which is not a
/// number anybody would ever mean sitting exactly where a number they might
/// mean is expected. It is the same figure either way; only the words change.
DefaultPortion defaultPortionFor(
  MealEntity meal, {
  required bool usesImperialUnits,
  double? householdPortion,
  String? unit,
  double gramsPerUnit = 1,
}) {
  // A unit that weighs nothing cannot be divided through. It should not happen
  // — a unit is only offered for a food that has the figure behind it — so the
  // honest response is to leave the figure alone rather than invent a factor.
  final perUnit = gramsPerUnit > 0 ? gramsPerUnit : 1.0;

  if (householdPortion != null && householdPortion > 0) {
    return DefaultPortion(
        _tidy(householdPortion / perUnit), PortionSource.householdPortion);
  }

  final last = meal.lastUsedGrams;
  if (last != null && last > 0) {
    return DefaultPortion(_tidy(last / perUnit), PortionSource.lastTime);
  }

  // Nothing personal to go on, so the packet answers. One of whatever the box
  // is already counting in — and the box only ever counts in a unit this food
  // actually has, so the three cases below match the three it can be showing.
  if (unit != null && _countingUnits.contains(unit)) {
    switch (unit) {
      case 'serving':
        return const DefaultPortion('1', PortionSource.packServing);
      case 'item':
        return const DefaultPortion('1', PortionSource.oneOfThem);
      case 'pack':
        return const DefaultPortion('1', PortionSource.wholePack);
    }
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
