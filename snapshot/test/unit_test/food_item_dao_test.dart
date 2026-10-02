import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';

void main() {
  late AppDatabase db;
  late FoodItemDao dao;

  setUp(() {
    db = AppDatabase.createInMemory();
    dao = FoodItemDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  FoodItemsCompanion _makeFoodItem(String id, {bool favourite = false}) {
    return FoodItemsCompanion(
      id: Value(id),
      name: Value('Food $id'),
      source: const Value('custom'),
      kcalPer100: const Value(200.0),
      proteinPer100: const Value(10.0),
      carbsPer100: const Value(25.0),
      fatPer100: const Value(8.0),
      favourite: Value(favourite),
    );
  }

  group('toggleFavourite', () {
    test('sets favourite flag to true', () async {
      await dao.upsertFoodItem(_makeFoodItem('a'));

      await dao.toggleFavourite('a', true);
      final item = await dao.getById('a');

      expect(item, isNotNull);
      expect(item!.favourite, isTrue);
    });

    test('unsets favourite flag', () async {
      await dao.upsertFoodItem(_makeFoodItem('a', favourite: true));

      await dao.toggleFavourite('a', false);
      final item = await dao.getById('a');

      expect(item, isNotNull);
      expect(item!.favourite, isFalse);
    });
  });

  group('getFavourites', () {
    test('returns only starred items', () async {
      await dao.upsertFoodItem(_makeFoodItem('a'));
      await dao.upsertFoodItem(_makeFoodItem('b'));
      await dao.upsertFoodItem(_makeFoodItem('c'));

      await dao.toggleFavourite('a', true);
      await dao.toggleFavourite('c', true);

      final favourites = await dao.getFavourites();
      final ids = favourites.map((f) => f.id).toSet();

      expect(ids, equals({'a', 'c'}));
    });

    test('returns empty list when no favourites', () async {
      await dao.upsertFoodItem(_makeFoodItem('a'));

      final favourites = await dao.getFavourites();
      expect(favourites, isEmpty);
    });
  });

  group('updateLastUsed', () {
    test('persists grams and timestamp', () async {
      await dao.upsertFoodItem(_makeFoodItem('a'));

      final now = DateTime.now().millisecondsSinceEpoch;
      await dao.updateLastUsed('a', now, 250.0);

      final item = await dao.getById('a');
      expect(item, isNotNull);
      expect(item!.lastUsedAt, equals(now));
      expect(item.lastUsedGrams, equals(250.0));
    });
  });

  group('getRecentlyUsed', () {
    test('returns items ordered by lastUsedAt descending', () async {
      await dao.upsertFoodItem(_makeFoodItem('a'));
      await dao.upsertFoodItem(_makeFoodItem('b'));
      await dao.upsertFoodItem(_makeFoodItem('c'));

      await dao.updateLastUsed('a', 1000, 100.0);
      await dao.updateLastUsed('b', 3000, 200.0);
      await dao.updateLastUsed('c', 2000, 150.0);

      final recent = await dao.getRecentlyUsed(limit: 10);
      final ids = recent.map((r) => r.id).toList();

      expect(ids, equals(['b', 'c', 'a']));
    });

    test('excludes items without lastUsedAt', () async {
      await dao.upsertFoodItem(_makeFoodItem('a'));
      await dao.upsertFoodItem(_makeFoodItem('b'));

      await dao.updateLastUsed('a', 1000, 100.0);
      // 'b' has no lastUsedAt

      final recent = await dao.getRecentlyUsed();
      final ids = recent.map((r) => r.id).toList();

      expect(ids, equals(['a']));
    });
  });
}
