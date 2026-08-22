/// Adding one of something, rather than working out what it weighs.
///
/// Behaviour under test (Release 4, TM-0014). The plan's own acceptance example
/// is: *pick the Waitrose chicken and stuffing pie, whose own serving is one
/// pie, and tap Add → an entry of 1 pie at that pie's stored calories.* Until
/// now the amount box only counted grams, ounces, millilitres and "servings",
/// so a person adding a pie had to know what a pie weighs — and the house
/// already knew, because it records what a pack weighs and how many are in it.
/// Those two numbers reached the phone and were dropped on the way to the sheet.
///
/// The carrying test is [one of them is not one gram of them]. A pack of four
/// 500g pies is 500 grams if you multiply by the wrong number and 125 if you
/// multiply by the right one; both are plausible figures, both look equally
/// solid on a day, and only one of them is what the person meant. Everything
/// else here is about not offering a unit the food cannot honour: a food whose
/// pack the house has never weighed must never show "pack", because a pack
/// button that quietly means grams is worse than no pack button.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/household/domain/household_food.dart';
import 'package:opennutritracker/features/meal_detail/domain/default_portion.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';

void main() {
  /// Four pies in a 500g box, at 250 kcal per 100g.
  MealEntity pies({double? packGrams = 500, int? perPack = 4}) => MealEntity(
        code: 'pies',
        name: 'Chicken and stuffing pie',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: null,
        servingSize: null,
        packGrams: packGrams,
        perPack: perPack,
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

  String unit(UnitDropdownItem u) => u.toString();

  group('what an amount in these units comes to', () {
    test('one of them is not one gram of them', () {
      final oneOfThem =
          MealDetailBloc.convertQuantity(pies(), 1, unit(UnitDropdownItem.item));

      expect(oneOfThem, 125,
          reason: 'four pies in a 500g box is a 125g pie. Multiplying by the '
              'pack instead gives 500 — a figure four times too big that looks '
              'exactly as reasonable on a day');
    });

    test('and a whole pack is the whole pack', () {
      expect(
          MealDetailBloc.convertQuantity(
              pies(), 1, unit(UnitDropdownItem.pack)),
          500);
    });

    test('two of them is two of them', () {
      expect(
          MealDetailBloc.convertQuantity(
              pies(), 2, unit(UnitDropdownItem.item)),
          250);
    });

    test('half of one is half of one', () {
      expect(
          MealDetailBloc.convertQuantity(
              pies(), 0.5, unit(UnitDropdownItem.item)),
          62.5);
    });

    test('grams are still grams', () {
      expect(
          MealDetailBloc.convertQuantity(pies(), 125, unit(UnitDropdownItem.g)),
          125);
    });
  });

  group('when the house does not know', () {
    test('a food with no pack weight cannot be counted in packs', () {
      final loose = pies(packGrams: null, perPack: null);
      expect(loose.hasPackValues, isFalse);
      expect(loose.hasItemValues, isFalse);
      expect(loose.itemGrams, isNull);
    });

    test('a pack weight with no count is a pack but not an item', () {
      final bag = pies(packGrams: 500, perPack: null);
      expect(bag.hasPackValues, isTrue);
      expect(bag.hasItemValues, isFalse,
          reason: 'the house knows what the bag weighs and not how many are in '
              'it, so "one of them" is a number nobody has');
    });

    test('a count of nothing is not a count', () {
      expect(pies(perPack: 0).hasItemValues, isFalse);
    });

    test('a pack of nothing is not a pack', () {
      expect(pies(packGrams: 0).hasPackValues, isFalse);
    });
  });

  group('what the box opens on', () {
    test('one of them, when that is the unit', () {
      final portion =
          defaultPortionFor(pies(), usesImperialUnits: false, unit: 'item');
      expect(portion.amount, '1');
      expect(portion.source, PortionSource.oneOfThem);
      expect(portion.explanation, contains('One of them'));
    });

    test('one pack, when that is the unit', () {
      final portion =
          defaultPortionFor(pies(), usesImperialUnits: false, unit: 'pack');
      expect(portion.amount, '1');
      expect(portion.source, PortionSource.wholePack);
    });

    test('never a gram figure dropped into a box that counts things', () {
      // The failure this stops: 96 grams last time, unit "item", box reads 96.
      // Ninety-six pies.
      final lastTime = MealEntity(
        code: 'pies',
        name: 'Chicken and stuffing pie',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: null,
        servingSize: null,
        packGrams: 500,
        perPack: 4,
        lastUsedGrams: 96,
        nutriments: pies().nutriments,
        source: MealSourceEntity.custom,
      );

      expect(
          defaultPortionFor(lastTime, usesImperialUnits: false, unit: 'item')
              .amount,
          '1');
    });

    test('and nothing changes for a food with no pack at all', () {
      // The old order is untouched: what they had last time still wins.
      final loose = MealEntity(
        code: 'oats',
        name: 'Oats',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: null,
        servingSize: null,
        lastUsedGrams: 40,
        nutriments: pies().nutriments,
        source: MealSourceEntity.off,
      );
      final portion = defaultPortionFor(loose, usesImperialUnits: false);
      expect(portion.amount, '40');
      expect(portion.source, PortionSource.lastTime);
    });
  });

  group('what the person reads on the control', () {
    test('the weight is part of the words, not a caption somewhere else', () {
      expect(MealDetailBottomSheet.itemLabel(125), 'one (125 g)');
      expect(MealDetailBottomSheet.packLabel(500), 'pack (500 g)');
    });

    test('a weight that is not whole keeps one decimal, not fifteen', () {
      expect(MealDetailBottomSheet.itemLabel(500 / 3), 'one (166.7 g)');
    });
  });

  group('the two numbers survive the journey from the house', () {
    test('a household food arrives knowing its pack and its count', () {
      final food = HouseholdFood.fromJson(const {
        'id': 7,
        'name': 'Chicken and stuffing pie',
        'brand': 'Waitrose',
        'kcal_100': 250,
        'pack_grams': 500,
        'per_pack': 4,
        'trust': 'checked',
        'source': 'typed',
      });

      final meal = MealEntity.fromHouseholdFood(food);
      expect(meal.packGrams, 500);
      expect(meal.perPack, 4);
      expect(meal.itemGrams, 125,
          reason: 'the house has recorded both of these all along; they used '
              'to stop here and the sheet only ever saw grams');
    });
  });
}
