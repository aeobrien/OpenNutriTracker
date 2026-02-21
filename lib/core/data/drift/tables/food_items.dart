import 'package:drift/drift.dart';

class FoodItems extends Table {
  TextColumn get id => text()();
  TextColumn get source => text().withDefault(const Constant('unknown'))();
  TextColumn get barcode => text().nullable()();
  TextColumn get name => text().nullable()();
  TextColumn get brand => text().nullable()();

  TextColumn get mealQuantity => text().nullable()();
  TextColumn get mealUnit => text().nullable()();
  RealColumn get servingQuantity => real().nullable()();
  TextColumn get servingUnit => text().nullable()();
  TextColumn get servingSize => text().nullable()();

  RealColumn get kcalPer100 => real().nullable()();
  RealColumn get proteinPer100 => real().nullable()();
  RealColumn get carbsPer100 => real().nullable()();
  RealColumn get fatPer100 => real().nullable()();
  RealColumn get fibrePer100 => real().nullable()();
  RealColumn get sugarPer100 => real().nullable()();
  RealColumn get saturatedFatPer100 => real().nullable()();

  TextColumn get thumbnailImageUrl => text().nullable()();
  TextColumn get mainImageUrl => text().nullable()();
  TextColumn get url => text().nullable()();

  IntColumn get lastUsedAt => integer().nullable()();
  RealColumn get lastUsedGrams => real().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
