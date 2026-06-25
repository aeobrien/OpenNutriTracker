import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/intake/data/dto/mantel_intake_dto.dart';

void main() {
  group('MantelIntakeDto.fromJson', () {
    test('maps all fields, tolerating numeric strings and nulls', () {
      final dto = MantelIntakeDto.fromJson({
        'id': 'abc-123',
        'label': 'Salmon & broccoli',
        'description': 'i had salmon and broccoli',
        'kcal': 370,
        'protein': '28', // string number from JSON
        'carbs': null, // missing -> 0
        'fat': 12.5,
        'meal_slot': 'dinner',
        'eaten_at': '2026-06-25T18:00:00Z',
        'tz': 'Europe/London',
        'source': 'recipe',
        'confidence': 0.9,
      });

      expect(dto.id, 'abc-123');
      expect(dto.label, 'Salmon & broccoli');
      expect(dto.kcal, 370);
      expect(dto.protein, 28);
      expect(dto.carbs, 0);
      expect(dto.fat, 12.5);
      expect(dto.source, 'recipe');
      expect(dto.confidence, 0.9);
    });

    test('missing macros default to zero', () {
      final dto = MantelIntakeDto.fromJson({
        'id': 'x',
        'label': 'Toast',
        'eaten_at': '2026-06-25T08:00:00Z',
      });
      expect(dto.kcal, 0);
      expect(dto.protein, 0);
      expect(dto.carbs, 0);
      expect(dto.fat, 0);
      expect(dto.confidence, isNull);
    });
  });

  group('meal-slot mapping', () {
    MantelIntakeDto withSlot(String? slot) => MantelIntakeDto(
          id: 'i',
          label: 'L',
          eatenAt: '2026-06-25T12:00:00Z',
          mealSlot: slot,
        );

    test('known slots pass through', () {
      expect(withSlot('breakfast').foodTrackerMealSlot, 'breakfast');
      expect(withSlot('lunch').foodTrackerMealSlot, 'lunch');
      expect(withSlot('dinner').foodTrackerMealSlot, 'dinner');
      expect(withSlot('snack').foodTrackerMealSlot, 'snack');
    });

    test('case/whitespace tolerated', () {
      expect(withSlot(' Dinner ').foodTrackerMealSlot, 'dinner');
    });

    test('unknown / null falls back to snack', () {
      expect(withSlot(null).foodTrackerMealSlot, 'snack');
      expect(withSlot('').foodTrackerMealSlot, 'snack');
      expect(withSlot('brunch').foodTrackerMealSlot, 'snack');
    });
  });

  group('eatenAtLocal', () {
    test('parses an ISO-8601 UTC instant', () {
      final dto = MantelIntakeDto(
        id: 'i',
        label: 'L',
        eatenAt: '2026-06-25T18:00:00Z',
      );
      // Same instant, expressed locally.
      expect(dto.eatenAtLocal.toUtc(),
          DateTime.utc(2026, 6, 25, 18, 0, 0));
    });

    test('falls back to now on an unparseable timestamp', () {
      final dto = MantelIntakeDto(id: 'i', label: 'L', eatenAt: 'not-a-date');
      // Should not throw and should be close to now.
      final diff = DateTime.now().difference(dto.eatenAtLocal).abs();
      expect(diff.inMinutes, lessThan(1));
    });
  });
}
