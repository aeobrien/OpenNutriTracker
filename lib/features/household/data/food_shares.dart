/// Who a food being logged was for, and how much of it each of them had.
///
/// One rule holds this file together: **each person's figures are worked out
/// from their own amount, and never from the other person's.** The tempting
/// shortcut — total the whole thing once and split it — is wrong the moment
/// the two of them had different amounts, and it is wrong silently, because
/// half of a number is always a plausible-looking number.
library;

/// One person's share of a food being logged.
class FoodShare {
  /// Whose day it counts against.
  final int personId;

  /// How much of it they had, in the unit the portion sheet has already
  /// converted to — grams for a solid, millilitres for a liquid.
  final double quantity;

  const FoodShare({required this.personId, required this.quantity});

  @override
  bool operator ==(Object other) =>
      other is FoodShare &&
      other.personId == personId &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(personId, quantity);

  @override
  String toString() => 'FoodShare($personId, $quantity)';
}

/// What one share actually puts on that person's ledger.
class FoodShareEntry {
  final int personId;
  final double quantity;
  final double? kcal;
  final double? protein;
  final double? fat;
  final double? carbs;

  const FoodShareEntry({
    required this.personId,
    required this.quantity,
    this.kcal,
    this.protein,
    this.fat,
    this.carbs,
  });

  @override
  bool operator ==(Object other) =>
      other is FoodShareEntry &&
      other.personId == personId &&
      other.quantity == quantity &&
      other.kcal == kcal &&
      other.protein == protein &&
      other.fat == fat &&
      other.carbs == carbs;

  @override
  int get hashCode =>
      Object.hash(personId, quantity, kcal, protein, fat, carbs);

  @override
  String toString() => 'FoodShareEntry($personId, $quantity, $kcal)';
}

/// Work out one person's own figures from one person's own amount.
///
/// A figure the food does not carry stays missing. It must not become zero:
/// zero is a claim that the food has none of that, and "we do not know" is a
/// different thing which the ledger is entitled to be told apart from it.
FoodShareEntry portionFor(
  FoodShare share, {
  num? kcalPerUnit,
  num? proteinPerUnit,
  num? fatPerUnit,
  num? carbsPerUnit,
}) {
  double? at(num? perUnit) {
    if (perUnit == null) return null;
    return double.parse((perUnit * share.quantity).toStringAsFixed(1));
  }

  return FoodShareEntry(
    personId: share.personId,
    quantity: share.quantity,
    kcal: at(kcalPerUnit),
    protein: at(proteinPerUnit),
    fat: at(fatPerUnit),
    carbs: at(carbsPerUnit),
  );
}
