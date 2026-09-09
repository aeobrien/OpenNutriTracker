import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/tables/food_items.dart';

class LogEntries extends Table {
  TextColumn get id => text()();
  IntColumn get timestamp => integer()();
  TextColumn get mealSlot => text()();
  TextColumn get foodItemId => text().nullable().references(FoodItems, #id)();
  RealColumn get amount => real()();
  TextColumn get unit => text()();

  RealColumn get snapshotKcal => real().withDefault(const Constant(0.0))();
  RealColumn get snapshotProtein => real().withDefault(const Constant(0.0))();
  RealColumn get snapshotCarbs => real().withDefault(const Constant(0.0))();
  RealColumn get snapshotFat => real().withDefault(const Constant(0.0))();

  TextColumn get entryType => text().withDefault(const Constant('food'))();
  TextColumn get quickAddLabel => text().nullable()();
  TextColumn get recipeId => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
