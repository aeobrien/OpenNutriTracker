import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';

class TrackedDayEntity extends Equatable {
  final DateTime day;
  final double calorieGoal;
  final double caloriesTracked;
  final double? carbsGoal;
  final double? carbsTracked;
  final double? fatGoal;
  final double? fatTracked;
  final double? proteinGoal;
  final double? proteinTracked;

  const TrackedDayEntity(
      {required this.day,
      required this.calorieGoal,
      required this.caloriesTracked,
      this.carbsGoal,
      this.carbsTracked,
      this.fatGoal,
      this.fatTracked,
      this.proteinGoal,
      this.proteinTracked});

  factory TrackedDayEntity.fromDailyStatRow(DailyStat row) {
    final dateParts = row.date.split('-');
    return TrackedDayEntity(
        day: DateTime(int.parse(dateParts[0]), int.parse(dateParts[1]),
            int.parse(dateParts[2])),
        calorieGoal: row.calorieGoal,
        caloriesTracked: row.caloriesTracked,
        carbsGoal: row.carbsGoal,
        carbsTracked: row.carbsTracked,
        fatGoal: row.fatGoal,
        fatTracked: row.fatTracked,
        proteinGoal: row.proteinGoal,
        proteinTracked: row.proteinTracked);
  }

  factory TrackedDayEntity.fromTrackedDayDBO(TrackedDayDBO trackedDayDBO) {
    return TrackedDayEntity(
        day: trackedDayDBO.day,
        calorieGoal: trackedDayDBO.calorieGoal,
        caloriesTracked: trackedDayDBO.caloriesTracked,
        carbsGoal: trackedDayDBO.carbsGoal,
        carbsTracked: trackedDayDBO.carbsTracked,
        fatGoal: trackedDayDBO.fatGoal,
        fatTracked: trackedDayDBO.fatTracked,
        proteinGoal: trackedDayDBO.proteinGoal,
        proteinTracked: trackedDayDBO.proteinTracked);
  }

  Color getCalendarDayRatingColor(BuildContext context) {
    return Theme.of(context).colorScheme.primary;
  }

  Color getRatingDayTextColor(BuildContext context) {
    return Theme.of(context).colorScheme.onSecondaryContainer;
  }

  Color getRatingDayTextBackgroundColor(BuildContext context) {
    return Theme.of(context).colorScheme.secondaryContainer;
  }

  @override
  List<Object?> get props => [
        day,
        calorieGoal,
        caloriesTracked,
        carbsGoal,
        carbsTracked,
        fatGoal,
        fatTracked,
        proteinGoal,
        proteinTracked
      ];
}
