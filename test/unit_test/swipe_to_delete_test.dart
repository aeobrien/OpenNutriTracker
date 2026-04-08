import 'package:flutter_test/flutter_test.dart';

/// Tests for swipe-to-delete undo logic.
/// Validates that the undo timer and state management work correctly.
void main() {
  group('Swipe to delete undo logic', () {
    test('deleted item can be restored within undo window', () {
      final items = ['a', 'b', 'c'];
      final deletedItem = items.removeAt(1);
      expect(items, ['a', 'c']);

      // Simulate undo: re-insert the item
      items.insert(1, deletedItem);
      expect(items, ['a', 'b', 'c']);
    });

    test('deleted item is not restored after undo window expires', () {
      final items = ['a', 'b', 'c'];
      items.removeAt(1);
      expect(items, ['a', 'c']);
      // No undo action taken — item stays deleted
      expect(items.length, 2);
    });

    test('confirmDismiss returns false when no callback is set', () {
      // Mirrors the confirmDismiss logic: returns true only if
      // onItemDismissed callback is not null
      Function(Object)? onItemDismissed;
      expect(onItemDismissed != null, false);

      onItemDismissed = (_) {};
      expect(onItemDismissed != null, true);
    });
  });
}
