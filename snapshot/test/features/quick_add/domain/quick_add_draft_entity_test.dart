import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/quick_add/domain/entity/quick_add_draft_entity.dart';

void main() {
  group('isEmpty', () {
    test('is true for a brand-new draft (only default slot)', () {
      expect(const QuickAddDraftEntity().isEmpty, isTrue);
    });

    test('is true when fields contain only whitespace', () {
      const draft = QuickAddDraftEntity(kcal: '  ', label: '\t');
      expect(draft.isEmpty, isTrue);
    });

    test('is false when calories are entered', () {
      const draft = QuickAddDraftEntity(kcal: '250');
      expect(draft.isEmpty, isFalse);
    });

    test('is false when only a label is entered', () {
      const draft = QuickAddDraftEntity(label: 'Coffee');
      expect(draft.isEmpty, isFalse);
    });
  });

  group('encode/decode round-trip', () {
    test('preserves all fields', () {
      const draft = QuickAddDraftEntity(
        kcal: '250',
        protein: '10',
        carbs: '30',
        fat: '5',
        label: 'Cereal',
        mealSlot: 'breakfast',
      );

      final restored = QuickAddDraftEntity.decode(draft.encode());

      expect(restored, equals(draft));
    });
  });

  group('decode error handling', () {
    test('returns null for null input', () {
      expect(QuickAddDraftEntity.decode(null), isNull);
    });

    test('returns null for empty string', () {
      expect(QuickAddDraftEntity.decode(''), isNull);
    });

    test('returns null for malformed JSON', () {
      expect(QuickAddDraftEntity.decode('not json {'), isNull);
    });

    test('returns null for a JSON value that is not an object', () {
      expect(QuickAddDraftEntity.decode('[1, 2, 3]'), isNull);
    });

    test('defaults missing fields rather than throwing', () {
      final restored = QuickAddDraftEntity.decode('{"kcal":"100"}');
      expect(restored, isNotNull);
      expect(restored!.kcal, equals('100'));
      expect(restored.protein, equals(''));
      expect(restored.mealSlot, equals('snack'));
    });
  });
}
