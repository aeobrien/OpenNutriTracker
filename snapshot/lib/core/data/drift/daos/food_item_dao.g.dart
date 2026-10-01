// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'food_item_dao.dart';

// ignore_for_file: type=lint
mixin _$FoodItemDaoMixin on DatabaseAccessor<AppDatabase> {
  $FoodItemsTable get foodItems => attachedDatabase.foodItems;
  FoodItemDaoManager get managers => FoodItemDaoManager(this);
}

class FoodItemDaoManager {
  final _$FoodItemDaoMixin _db;
  FoodItemDaoManager(this._db);
  $$FoodItemsTableTableManager get foodItems =>
      $$FoodItemsTableTableManager(_db.attachedDatabase, _db.foodItems);
}
