/// What the amount box starts on, in the order Aidan settled.
///
/// Behaviour under test (TM-0014). He was asked on 22 August 2026 which of
/// three should come first — the household's own portion, the amount he had of
/// that food last time, or the packet — and answered "agreed" to this:
///
///   the household's portion, then last time, then the packet.
///
/// That is worth testing because getting it wrong is silent. Every one of the
/// four is a plausible-looking number, and whichever one lands in the box goes
/// onto the day as though somebody chose it deliberately.
///
/// The carrying test is [the household's own portion beats what he had last
/// time]. It is the step that did not exist before and the only one that can be
/// wrong without looking wrong: a portion somebody in the house sat down and
/// agreed, quietly losing to a memory of a different day.
///
/// One thing this file cannot yet prove on a screen: nothing supplies a
/// household portion. A household portion is a share of a *planned meal*, and
/// the meal's own screen — each person's portion beside the parts it is built
/// from — is not built. So the first step is exercised here and nowhere else
/// until it is.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/meal_detail/domain/default_portion.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';

void main() {
  MealEntity food({
    double? lastUsedGrams,
    double? servingQuantity,
    String? servingUnit,
    double? packGrams,
    int? perPack,
  }) =>
      MealEntity(
        code: '1',
        name: 'Chicken and stuffing pie',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: servingQuantity,
        servingUnit: servingUnit,
        servingSize: null,
        packGrams: packGrams,
        perPack: perPack,
        lastUsedGrams: lastUsedGrams,
        nutriments: const MealNutrimentsEntity(
            energyKcal100: 250,
            carbohydrates100: null,
            fat100: null,
            proteins100: null,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null),
        source: MealSourceEntity.custom,
      );

  group('the order he settled', () {
    test("the household's own portion beats what he had last time", () {
      // Somebody in the house sat down and said how much of this is his. A
      // memory of a different day does not get to overrule that.
      final portion = defaultPortionFor(
        food(lastUsedGrams: 300, servingQuantity: 25, servingUnit: 'g'),
        usesImperialUnits: false,
        householdPortion: 180,
      );

      expect(portion.amount, '180');
      expect(portion.source, PortionSource.householdPortion);
    });

    test('what he had last time beats the packet', () {
      final portion = defaultPortionFor(
        food(lastUsedGrams: 40, servingQuantity: 25, servingUnit: 'g'),
        usesImperialUnits: false,
      );

      expect(portion.amount, '40');
      expect(portion.source, PortionSource.lastTime);
    });

    test('the packet beats a round number', () {
      final portion = defaultPortionFor(
        food(servingQuantity: 25, servingUnit: 'g'),
        usesImperialUnits: false,
      );

      expect(portion.amount, '1');
      expect(portion.source, PortionSource.packServing);
    });

    test('and a round number when nobody has said anything at all', () {
      final portion = defaultPortionFor(food(), usesImperialUnits: false);

      expect(portion.amount, '100');
      expect(portion.source, PortionSource.aStandIn);
    });

    test('a portion of nothing is not a portion', () {
      // A zero is how "unset" arrives from a database, not somebody saying his
      // share of dinner is nothing.
      final portion = defaultPortionFor(food(lastUsedGrams: 40),
          usesImperialUnits: false, householdPortion: 0);

      expect(portion.source, PortionSource.lastTime);
    });
  });

  group('said in the words the box is using', () {
    test('a portion in grams shown in a box counting pies', () {
      // 250 g of a 125 g pie is two pies. The same amount either way — only
      // the word after it changes.
      final portion = defaultPortionFor(
        food(packGrams: 500, perPack: 4),
        usesImperialUnits: false,
        householdPortion: 250,
        unit: 'item',
        gramsPerUnit: 125,
      );

      expect(portion.amount, '2');
      expect(portion.source, PortionSource.householdPortion);
    });

    test('and last time, in a box counting servings', () {
      final portion = defaultPortionFor(
        food(lastUsedGrams: 40, servingQuantity: 25, servingUnit: 'g'),
        usesImperialUnits: false,
        unit: 'serving',
        gramsPerUnit: 25,
      );

      expect(portion.amount, '1.6');
      expect(portion.source, PortionSource.lastTime);
    });

    test('a unit that weighs nothing leaves the figure alone', () {
      // It should not be reachable — a unit is only offered for a food that
      // has the figure behind it. If it happens, showing the grams is the
      // smallest lie available; inventing a weight to divide by is not.
      final portion = defaultPortionFor(
        food(lastUsedGrams: 40),
        usesImperialUnits: false,
        unit: 'item',
        gramsPerUnit: 0,
      );

      expect(portion.amount, '40');
    });
  });

  group('the figure goes in and comes back out the same', () {
    // The screen composes two things: this resolver picks the starting figure,
    // and the sheet's own ladder turns whatever is typed back into grams. The
    // risk is not either one alone — it is the two disagreeing, which would
    // put a different amount on the day than the box appeared to be offering.
    // So this asks the real ladder what a unit weighs rather than being told,
    // and then checks the journey closes.
    for (final unit in ['item', 'pack', 'serving', 'g']) {
      test('a portion of 250 g, opened and read back in $unit', () {
        final pie = food(
            packGrams: 500, perPack: 4, servingQuantity: 125, servingUnit: 'g');
        final gramsPerUnit = MealDetailBloc.convertQuantity(pie, 1, unit);

        final portion = defaultPortionFor(pie,
            usesImperialUnits: false,
            householdPortion: 250,
            unit: unit,
            gramsPerUnit: gramsPerUnit);

        final backToGrams = MealDetailBloc.convertQuantity(
            pie, double.parse(portion.amount), unit);

        expect(backToGrams, closeTo(250, 0.5),
            reason: 'the box offered ${portion.amount} $unit, which is not the '
                '250 g the household said was his');
      });
    }
  });

  group('what the screen says underneath', () {
    test('each reason says something different, in plain words', () {
      final said = {
        for (final s in PortionSource.values)
          DefaultPortion('1', s).explanation
      };

      expect(said, hasLength(PortionSource.values.length),
          reason: 'two reasons that read the same tell the person nothing');
    });

    test('the household one says whose it is and where it came from', () {
      expect(
          const DefaultPortion('180', PortionSource.householdPortion)
              .explanation,
          contains('household'));
    });
  });
}
