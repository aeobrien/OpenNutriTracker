// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_activity_dao.dart';

// ignore_for_file: type=lint
mixin _$UserActivityDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserActivitiesTable get userActivities => attachedDatabase.userActivities;
  UserActivityDaoManager get managers => UserActivityDaoManager(this);
}

class UserActivityDaoManager {
  final _$UserActivityDaoMixin _db;
  UserActivityDaoManager(this._db);
  $$UserActivitiesTableTableManager get userActivities =>
      $$UserActivitiesTableTableManager(
        _db.attachedDatabase,
        _db.userActivities,
      );
}
