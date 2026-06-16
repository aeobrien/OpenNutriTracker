import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/calc/meal_grouping.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';

IntakeEntity _intake(String id, IntakeTypeEntity type) => IntakeEntity(
      id: id,
      unit: 'g',
      amount: 100.0,
      type: type,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 2, 23),
    );

void main() {
  group('MealGrouping.groupByMeal', () {
    test('returns all four slots even when input is empty', () {
      final grouped = MealGrouping.groupByMeal([]);

      expect(grouped.keys, MealGrouping.displayOrder);
      for (final slot in MealGrouping.displayOrder) {
        expect(grouped[slot], isEmpty);
      }
    });

    test('iterates slots in breakfast -> lunch -> dinner -> snack order', () {
      final grouped = MealGrouping.groupByMeal([]);

      expect(grouped.keys.toList(), [
        IntakeTypeEntity.breakfast,
        IntakeTypeEntity.lunch,
        IntakeTypeEntity.dinner,
        IntakeTypeEntity.snack,
      ]);
    });

    test('routes each entry into its meal slot', () {
      final grouped = MealGrouping.groupByMeal([
        _intake('b1', IntakeTypeEntity.breakfast),
        _intake('l1', IntakeTypeEntity.lunch),
        _intake('d1', IntakeTypeEntity.dinner),
        _intake('s1', IntakeTypeEntity.snack),
      ]);

      expect(grouped[IntakeTypeEntity.breakfast]!.single.id, 'b1');
      expect(grouped[IntakeTypeEntity.lunch]!.single.id, 'l1');
      expect(grouped[IntakeTypeEntity.dinner]!.single.id, 'd1');
      expect(grouped[IntakeTypeEntity.snack]!.single.id, 's1');
    });

    test('groups multiple entries of the same slot together', () {
      final grouped = MealGrouping.groupByMeal([
        _intake('s1', IntakeTypeEntity.snack),
        _intake('s2', IntakeTypeEntity.snack),
        _intake('b1', IntakeTypeEntity.breakfast),
      ]);

      expect(grouped[IntakeTypeEntity.snack]!.map((e) => e.id).toList(),
          ['s1', 's2']);
      expect(grouped[IntakeTypeEntity.breakfast]!.single.id, 'b1');
      expect(grouped[IntakeTypeEntity.lunch], isEmpty);
      expect(grouped[IntakeTypeEntity.dinner], isEmpty);
    });

    test('preserves relative order of entries within a slot', () {
      final grouped = MealGrouping.groupByMeal([
        _intake('b3', IntakeTypeEntity.breakfast),
        _intake('b1', IntakeTypeEntity.breakfast),
        _intake('b2', IntakeTypeEntity.breakfast),
      ]);

      expect(grouped[IntakeTypeEntity.breakfast]!.map((e) => e.id).toList(),
          ['b3', 'b1', 'b2']);
    });
  });
}
