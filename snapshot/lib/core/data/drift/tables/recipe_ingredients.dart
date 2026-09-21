import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/tables/food_items.dart';
import 'package:opennutritracker/core/data/drift/tables/recipes.dart';

class RecipeIngredients extends Table {
  TextColumn get id => text()();
  TextColumn get recipeId => text().references(Recipes, #id)();
  TextColumn get foodItemId => text().nullable().references(FoodItems, #id)();
  TextColumn get name => text()();
  RealColumn get grams => real()();

  RealColumn get kcalPer100 => real().withDefault(const Constant(0.0))();
  RealColumn get proteinPer100 => real().withDefault(const Constant(0.0))();
  RealColumn get carbsPer100 => real().withDefault(const Constant(0.0))();
  RealColumn get fatPer100 => real().withDefault(const Constant(0.0))();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
