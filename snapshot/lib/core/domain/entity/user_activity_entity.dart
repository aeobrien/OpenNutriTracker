import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart' as drift;
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';

class UserActivityEntity extends Equatable {
  final String id;
  final double duration;
  final double burnedKcal;
  final DateTime date;

  final PhysicalActivityEntity physicalActivityEntity;

  const UserActivityEntity(this.id, this.duration, this.burnedKcal, this.date,
      this.physicalActivityEntity);

  factory UserActivityEntity.fromActivityRow(drift.UserActivity row) {
    return UserActivityEntity(
        row.id,
        row.duration,
        row.burnedKcal,
        DateTime.fromMillisecondsSinceEpoch(row.date),
        PhysicalActivityEntity(
            row.activityCode,
            row.activityName,
            row.activityDescription,
            row.activityMets,
            const [],
            PhysicalActivityTypeEntity.values.firstWhere(
                (e) => e.name == row.activityType,
                orElse: () => PhysicalActivityTypeEntity.sport)));
  }

  factory UserActivityEntity.fromUserActivityDBO(UserActivityDBO activityDBO) {
    return UserActivityEntity(
        activityDBO.id,
        activityDBO.duration,
        activityDBO.burnedKcal,
        activityDBO.date,
        PhysicalActivityEntity.fromPhysicalActivityDBO(
            activityDBO.physicalActivityDBO));
  }

  @override
  List<Object?> get props => [id, duration, burnedKcal, date];

  static getIconData() => Icons.directions_run_outlined;
}
