import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/user_activity_dao.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';

class UserActivityRepository {
  final UserActivityDao _userActivityDao;
  final _log = Logger('UserActivityRepository');

  UserActivityRepository(this._userActivityDao);

  Future<void> addUserActivity(UserActivityEntity activityEntity) async {
    _log.fine('Adding user activity: ${activityEntity.id}');
    final pa = activityEntity.physicalActivityEntity;
    await _userActivityDao.insertActivity(UserActivitiesCompanion(
      id: Value(activityEntity.id),
      date: Value(activityEntity.date.millisecondsSinceEpoch),
      duration: Value(activityEntity.duration),
      burnedKcal: Value(activityEntity.burnedKcal),
      activityCode: Value(pa.code),
      activityName: Value(pa.specificActivity),
      activityDescription: Value(pa.description),
      activityMets: Value(pa.mets),
      activityType: Value(pa.type.name),
    ));
  }

  Future<void> addAllUserActivityDBOs(
      List<UserActivityDBO> userActivityDBOs) async {
    for (final dbo in userActivityDBOs) {
      final entity = UserActivityEntity.fromUserActivityDBO(dbo);
      await addUserActivity(entity);
    }
  }

  Future<void> deleteUserActivity(UserActivityEntity userActivityEntity) async {
    _log.fine('Deleting user activity: ${userActivityEntity.id}');
    await _userActivityDao.deleteById(userActivityEntity.id);
  }

  Future<List<UserActivityEntity>> getAllUserActivityByDate(
      DateTime dateTime) async {
    final rows = await _userActivityDao.getByDate(dateTime);
    return rows
        .map((row) => UserActivityEntity.fromActivityRow(row))
        .toList();
  }

  Future<List<UserActivityEntity>> getRecentUserActivity() async {
    final rows = await _userActivityDao.getRecentlyAdded();
    return rows
        .map((row) => UserActivityEntity.fromActivityRow(row))
        .toList();
  }

  // Export support: returns all user activities as UserActivityDBO-compatible JSON
  Future<List<Map<String, dynamic>>> getAllUserActivityJson() async {
    final rows = await _userActivityDao.getAll();
    return rows.map((row) {
      return {
        'id': row.id,
        'duration': row.duration,
        'burnedKcal': row.burnedKcal,
        'date': DateTime.fromMillisecondsSinceEpoch(row.date).toIso8601String(),
        'physicalActivityDBO': {
          'code': row.activityCode,
          'specificActivity': row.activityName,
          'description': row.activityDescription,
          'mets': row.activityMets,
          'tags': <String>[],
          'type': row.activityType,
        },
      };
    }).toList();
  }
}
