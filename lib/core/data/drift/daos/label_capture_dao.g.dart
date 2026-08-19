// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'label_capture_dao.dart';

// ignore_for_file: type=lint
mixin _$LabelCaptureDaoMixin on DatabaseAccessor<AppDatabase> {
  $LabelCapturesTable get labelCaptures => attachedDatabase.labelCaptures;
  LabelCaptureDaoManager get managers => LabelCaptureDaoManager(this);
}

class LabelCaptureDaoManager {
  final _$LabelCaptureDaoMixin _db;
  LabelCaptureDaoManager(this._db);
  $$LabelCapturesTableTableManager get labelCaptures =>
      $$LabelCapturesTableTableManager(_db.attachedDatabase, _db.labelCaptures);
}
