part of 'calendar_day_bloc.dart';

abstract class CalendarDayState extends Equatable {
  const CalendarDayState();
}

class CalendarDayInitial extends CalendarDayState {
  @override
  List<Object> get props => [];
}

class CalendarDayLoading extends CalendarDayState {
  @override
  List<Object?> get props => [];
}

class CalendarDayLoaded extends CalendarDayState {
  final TrackedDayEntity? trackedDayEntity;
  final List<UserActivityEntity> userActivityList;
  final List<IntakeEntity> breakfastIntakeList;
  final List<IntakeEntity> lunchIntakeList;
  final List<IntakeEntity> dinnerIntakeList;
  final List<IntakeEntity> snackIntakeList;

  const CalendarDayLoaded(
      this.trackedDayEntity,
      this.userActivityList,
      this.breakfastIntakeList,
      this.lunchIntakeList,
      this.dinnerIntakeList,
      this.snackIntakeList);

  @override
  List<Object?> get props => [trackedDayEntity];
}

class DailyRow {
  final DateTime date;
  final double kcalIntake;
  final double kcalTarget;
  final double net;
  final bool tracked;

  const DailyRow({
    required this.date,
    required this.kcalIntake,
    required this.kcalTarget,
    required this.net,
    required this.tracked,
  });
}

class WeeklySummary {
  final double totalIntake;
  final double totalTarget;
  final double totalNet;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final double proteinTarget;
  final double carbsTarget;
  final double fatTarget;

  const WeeklySummary({
    required this.totalIntake,
    required this.totalTarget,
    required this.totalNet,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
  });
}

class CalendarWeekLoaded extends CalendarDayState {
  final WeeklySummary summary;
  final List<DailyRow> dailyRows;

  const CalendarWeekLoaded(this.summary, this.dailyRows);

  @override
  List<Object?> get props => [summary, dailyRows];
}
