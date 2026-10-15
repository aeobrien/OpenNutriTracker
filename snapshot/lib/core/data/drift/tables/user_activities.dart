import 'package:drift/drift.dart';

class UserActivities extends Table {
  TextColumn get id => text()();
  IntColumn get date => integer()();
  RealColumn get duration => real()();
  RealColumn get burnedKcal => real()();
  TextColumn get activityCode => text()();
  TextColumn get activityName => text()();
  TextColumn get activityDescription => text().withDefault(const Constant(''))();
  RealColumn get activityMets => real()();
  TextColumn get activityType => text()();

  @override
  Set<Column> get primaryKey => {id};
}
