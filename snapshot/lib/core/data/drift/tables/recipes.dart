import 'package:drift/drift.dart';

class Recipes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get servings => real().withDefault(const Constant(1.0))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get lastUsedAt => integer().nullable()();
  BoolColumn get favourite => boolean().withDefault(const Constant(false))();

  RealColumn get kcalPerServing => real().withDefault(const Constant(0.0))();
  RealColumn get proteinPerServing => real().withDefault(const Constant(0.0))();
  RealColumn get carbsPerServing => real().withDefault(const Constant(0.0))();
  RealColumn get fatPerServing => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {id};
}
