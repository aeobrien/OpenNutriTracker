import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/meal_slot_calc.dart';

void main() {
  group('MealSlotCalc', () {
    test('breakfast range (6-10)', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 7, 30)), 'breakfast');
    });

    test('lunch range (10-14)', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 12, 0)), 'lunch');
    });

    test('dinner range (17-21)', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 19, 0)), 'dinner');
    });

    test('snack for afternoon gap (14-17)', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 15, 0)), 'snack');
    });

    test('snack for late night (22+)', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 23, 0)), 'snack');
    });

    test('snack for early morning (before 6)', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 4, 0)), 'snack');
    });

    test('boundary: hour 6 is breakfast', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 6, 0)), 'breakfast');
    });

    test('boundary: hour 10 is lunch (not breakfast)', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 10, 0)), 'lunch');
    });

    test('boundary: hour 17 is dinner', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 17, 0)), 'dinner');
    });

    test('boundary: hour 21 is snack (not dinner)', () {
      expect(MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 21, 0)), 'snack');
    });

    test('custom ranges', () {
      final customRanges = {
        'brunch': const MealSlotRange(9, 13),
        'dinner': const MealSlotRange(18, 22),
      };
      expect(
          MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 10, 0),
              ranges: customRanges),
          'brunch');
      expect(
          MealSlotCalc.suggestSlot(DateTime(2025, 1, 1, 15, 0),
              ranges: customRanges),
          'snack');
    });
  });
}
