import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/food_items.dart';

part 'food_item_dao.g.dart';

@DriftAccessor(tables: [FoodItems])
class FoodItemDao extends DatabaseAccessor<AppDatabase>
    with _$FoodItemDaoMixin {
  FoodItemDao(super.db);

  Future<void> upsertFoodItem(FoodItemsCompanion entry) async {
    await into(foodItems).insertOnConflictUpdate(entry);
  }

  Future<FoodItem?> getById(String id) async {
    return (select(foodItems)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<FoodItem?> getByBarcode(String barcode) async {
    return (select(foodItems)..where((t) => t.barcode.equals(barcode)))
        .getSingleOrNull();
  }

  Future<List<FoodItem>> searchByName(String query) async {
    final results = await customSelect(
      'SELECT f.* FROM food_items f INNER JOIN food_items_fts ON food_items_fts.rowid = f.rowid WHERE food_items_fts MATCH ?',
      variables: [Variable.withString(query)],
      readsFrom: {foodItems},
    ).get();

    return results.map((row) => foodItems.map(row.data)).toList();
  }

  Future<void> updateLastUsed(String id, int timestamp, double grams) async {
    await (update(foodItems)..where((t) => t.id.equals(id))).write(
      FoodItemsCompanion(
        lastUsedAt: Value(timestamp),
        lastUsedGrams: Value(grams),
      ),
    );
  }

  Future<List<FoodItem>> getAll() async {
    return select(foodItems).get();
  }
}
