// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'own_row_dao.dart';

// ignore_for_file: type=lint
mixin _$OwnRowDaoMixin on DatabaseAccessor<AppDatabase> {
  $OwnRowsTable get ownRows => attachedDatabase.ownRows;
  OwnRowDaoManager get managers => OwnRowDaoManager(this);
}

class OwnRowDaoManager {
  final _$OwnRowDaoMixin _db;
  OwnRowDaoManager(this._db);
  $$OwnRowsTableTableManager get ownRows =>
      $$OwnRowsTableTableManager(_db.attachedDatabase, _db.ownRows);
}
