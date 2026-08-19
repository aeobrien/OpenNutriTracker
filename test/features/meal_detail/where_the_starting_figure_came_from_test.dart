/// The amount box opens on a number, and the screen says where it came from.
///
/// Behaviour under test — Release C, TM-0014. Half of this promise was already
/// built: the app has always preferred the amount you had last time, then the
/// pack's serving, then a round number. What it never did was say which of the
/// three you were looking at — so a figure that was a real fact about the
/// packet and a figure that was a stand-in for nothing arrived on screen
/// looking identical, and both invited the same amount of trust.
///
/// The order is tested here because it is now a named thing that can be, and
/// because getting it wrong is silent: a wrong default is still a plausible
/// number, and it goes on the day as though somebody chose it.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/domain/default_portion.dart';

void main() {
  MealEntity food({
    double? lastUsedGrams,
    double? servingQuantity,
    String? servingUnit,
  }) =>
      MealEntity(
        code: '1',
        name: 'Oat biscuits',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: servingQuantity,
        servingUnit: servingUnit,
        servingSize: null,
        lastUsedGrams: lastUsedGrams,
        nutriments: const MealNutrimentsEntity(
            energyKcal100: 450,
            carbohydrates100: null,
            fat100: null,
            proteins100: null,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null),
        source: MealSourceEntity.off,
      );

  group('which figure wins', () {
    test('what they had last time beats everything else', () {
      final portion = defaultPortionFor(
          food(lastUsedGrams: 40, servingQuantity: 25, servingUnit: 'g'),
          usesImperialUnits: false);

      expect(portion.amount, '40');
      expect(portion.source, PortionSource.lastTime);
    });

    test("the pack's serving beats a round number", () {
      final portion = defaultPortionFor(
          food(servingQuantity: 25, servingUnit: 'g'),
          usesImperialUnits: false);

      expect(portion.amount, '1');
      expect(portion.source, PortionSource.packServing);
    });

    test('a round number when nobody has said anything', () {
      final portion = defaultPortionFor(food(), usesImperialUnits: false);

      expect(portion.amount, '100');
      expect(portion.source, PortionSource.aStandIn);
    });

    test('and the round number follows the units they use', () {
      final portion = defaultPortionFor(food(), usesImperialUnits: true);

      expect(portion.amount, '1');
      expect(portion.source, PortionSource.aStandIn);
    });

    test('a last amount of nothing is not an amount', () {
      final portion = defaultPortionFor(food(lastUsedGrams: 0),
          usesImperialUnits: false);

      expect(portion.source, PortionSource.aStandIn);
    });
  });

  group('how the figure is written', () {
    test('a whole number has no decimal point tacked on it', () {
      expect(
          defaultPortionFor(food(lastUsedGrams: 72), usesImperialUnits: false)
              .amount,
          '72');
    });

    test('and one that is not whole keeps one decimal place', () {
      expect(
          defaultPortionFor(food(lastUsedGrams: 72.5),
                  usesImperialUnits: false)
              .amount,
          '72.5');
    });

    test('a long decimal is cut short rather than shown in full', () {
      expect(
          defaultPortionFor(food(lastUsedGrams: 72.4444),
                  usesImperialUnits: false)
              .amount,
          '72.4',
          reason: 'an amount box is not the place for a number nobody '
              'measured to that precision');
    });
  });

  group('what the screen says underneath', () {
    test('each reason says something different, in plain words', () {
      final said = {
        for (final s in PortionSource.values)
          DefaultPortion('1', s).explanation
      };

      expect(said, hasLength(PortionSource.values.length),
          reason: 'two reasons that read the same tell the person nothing');
      for (final sentence in said) {
        expect(sentence.trim(), isNotEmpty);
        expect(sentence, isNot(contains('_')),
            reason: 'this is shown to a person, not logged');
      }
    });

    test('a stand-in says plainly that nobody has said', () {
      expect(const DefaultPortion('100', PortionSource.aStandIn).explanation,
          contains('nobody has said'));
    });
  });
}
