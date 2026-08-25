/// Reading grams-or-millilitres off a pack size.
///
/// Aidan, 25 August, after I reported it: "Yes, fix it."
///
/// The old rule was: does the pack size contain the letter "L" anywhere? That
/// is right for "500ml" and wrong for everything else that happens to have an
/// l in it. A pound of something became millilitres. So did a tin whose pack
/// size carried the word PEELED. Nothing about the mistake is visible on the
/// screen afterwards — the food simply arrives measured in the wrong thing.
///
/// The rule now is: is there a volume unit attached to a number? That is the
/// shape every pack size on Open Food Facts takes.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_dto.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

/// A product off Open Food Facts carrying nothing but a pack size.
MealEntity _packedAs(String? quantity) =>
    MealEntity.fromOFFProduct(OFFProductDTO.fromJson({
      'quantity': quantity,
      'nutriments': <String, dynamic>{},
    }));

void main() {
  group('a pack size measured by volume is millilitres', () {
    for (final packSize in [
      '500 ml',
      '330ml',
      '75cl',
      '1 L',
      '1l',
      '1.5 litres',
      '2 x 250ml',
    ]) {
      test('"$packSize"', () {
        expect(_packedAs(packSize).mealUnit, 'ml');
        expect(_packedAs(packSize).servingUnit, 'ml',
            reason: 'both come off the same reading, so both move together');
      });
    }
  });

  group('a pack size measured by weight is grams', () {
    for (final packSize in [
      '400 g',
      '1 kg',
      '6 x 40 g',
      '250 g ℮',
      // The two that were wrong. Neither is a volume; both carry an l.
      '1 lb',
      '425 g PEELED PLUM TOMATOES',
    ]) {
      test('"$packSize"', () {
        expect(_packedAs(packSize).mealUnit, 'g');
        expect(_packedAs(packSize).servingUnit, 'g');
      });
    }
  });

  test('a product with no pack size at all still has no unit', () {
    // Not a guess of grams. A missing pack size is why the unit box on the
    // food's own screen reads "N/A (g/ml)" and asks the person, and inventing
    // a unit here would put a figure in front of them that nobody checked.
    expect(_packedAs(null).mealUnit, isNull);
    expect(_packedAs(null).servingUnit, isNull);
  });
}
