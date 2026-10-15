import 'package:drift/drift.dart';

class UserProfile extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  IntColumn get birthday => integer()();
  RealColumn get heightCm => real()();
  RealColumn get weightKg => real()();
  TextColumn get gender => text()();
  TextColumn get goal => text()();
  TextColumn get pal => text()();

  @override
  Set<Column> get primaryKey => {id};
}
