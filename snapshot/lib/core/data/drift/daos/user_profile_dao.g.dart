// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_dao.dart';

// ignore_for_file: type=lint
mixin _$UserProfileDaoMixin on DatabaseAccessor<AppDatabase> {
  $UserProfileTable get userProfile => attachedDatabase.userProfile;
  UserProfileDaoManager get managers => UserProfileDaoManager(this);
}

class UserProfileDaoManager {
  final _$UserProfileDaoMixin _db;
  UserProfileDaoManager(this._db);
  $$UserProfileTableTableManager get userProfile =>
      $$UserProfileTableTableManager(_db.attachedDatabase, _db.userProfile);
}
