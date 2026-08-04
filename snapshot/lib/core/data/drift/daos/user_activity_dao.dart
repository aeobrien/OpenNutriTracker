import 'package:drift/drift.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/tables/user_activities.dart';

part 'user_activity_dao.g.dart';

@DriftAccessor(tables: [UserActivities])
class UserActivityDao extends DatabaseAccessor<AppDatabase>
    with _$UserActivityDaoMixin {
  UserActivityDao(super.db);

  Future<void> insertActivity(UserActivitiesCompanion entry) async {
    await into(userActivities).insert(entry);
  }

  Future<void> deleteById(String id) async {
    await (delete(userActivities)..where((t) => t.id.equals(id))).go();
  }

  Future<List<UserActivity>> getByDate(DateTime date) async {
    final dayStart =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch;
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59, 999)
        .millisecondsSinceEpoch;

    return (select(userActivities)
          ..where((t) => t.date.isBetweenValues(dayStart, dayEnd)))
        .get();
  }

  Future<List<UserActivity>> getRecentlyAdded({int limit = 20}) async {
    // Get distinct activities by code, most recent first
    final rows = await customSelect(
      '''
      SELECT ua.*
      FROM user_activities ua
      INNER JOIN (
        SELECT activity_code, MAX(date) as max_date
        FROM user_activities
        GROUP BY activity_code
      ) recent ON ua.activity_code = recent.activity_code AND ua.date = recent.max_date
      ORDER BY ua.date DESC
      LIMIT ?
      ''',
      variables: [Variable.withInt(limit)],
      readsFrom: {userActivities},
    ).get();

    return rows.map((row) => userActivities.map(row.data)).toList();
  }

  Future<List<UserActivity>> getAll() async {
    return select(userActivities).get();
  }
}
