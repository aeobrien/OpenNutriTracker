import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';

part 'calendar_day_event.dart';

part 'calendar_day_state.dart';

class CalendarDayBloc extends Bloc<CalendarDayEvent, CalendarDayState> {
  final GetUserActivityUsecase _getUserActivityUsecase;
  final GetIntakeUsecase _getIntakeUsecase;
  final DeleteIntakeUsecase _deleteIntakeUsecase;
  final DeleteUserActivityUsecase _deleteUserActivityUsecase;
  final GetTrackedDayUsecase _getTrackedDayUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;

  DateTime? _currentDay;

  CalendarDayBloc(
      this._getUserActivityUsecase,
      this._getIntakeUsecase,
      this._deleteIntakeUsecase,
      this._deleteUserActivityUsecase,
      this._getTrackedDayUsecase,
      this._addTrackedDayUsecase)
      : super(CalendarDayInitial()) {
    on<LoadCalendarDayEvent>((event, emit) async {
      emit(CalendarDayLoading());
      _currentDay = event.day;
      await _loadCalendarDay(event.day, emit);
    });

    on<RefreshCalendarDayEvent>((event, emit) async {
      if (_currentDay != null) {
        emit(CalendarDayLoading());
        await _loadCalendarDay(_currentDay!, emit);
      }
    });

    on<LoadCalendarWeekEvent>((event, emit) async {
      emit(CalendarDayLoading());
      await _loadCalendarWeek(event.weekStart, emit);
    });
  }

  Future<void> _loadCalendarDay(
      DateTime day, Emitter<CalendarDayState> emit) async {
    final userActivities =
        await _getUserActivityUsecase.getUserActivityByDay(day);

    final breakfastIntakeList =
        await _getIntakeUsecase.getBreakfastIntakeByDay(day);

    final lunchIntakeList = await _getIntakeUsecase.getLunchIntakeByDay(day);
    final dinnerIntakeList = await _getIntakeUsecase.getDinnerIntakeByDay(day);
    final snackIntakeList = await _getIntakeUsecase.getSnackIntakeByDay(day);

    final trackedDayEntity = await _getTrackedDayUsecase.getTrackedDay(day);

    emit(CalendarDayLoaded(
        trackedDayEntity,
        userActivities,
        breakfastIntakeList,
        lunchIntakeList,
        dinnerIntakeList,
        snackIntakeList));
  }

  Future<void> _loadCalendarWeek(
      DateTime weekStart, Emitter<CalendarDayState> emit) async {
    final weekEnd = weekStart.add(const Duration(days: 6));
    final trackedDays =
        await _getTrackedDayUsecase.getTrackedDaysByRange(weekStart, weekEnd);

    final trackedMap = <String, TrackedDayEntity>{};
    for (final td in trackedDays) {
      final key =
          '${td.day.year}-${td.day.month.toString().padLeft(2, '0')}-${td.day.day.toString().padLeft(2, '0')}';
      trackedMap[key] = td;
    }

    double totalIntake = 0;
    double totalTarget = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double proteinTarget = 0;
    double carbsTarget = 0;
    double fatTarget = 0;

    final dailyRows = <DailyRow>[];
    for (int i = 0; i < 7; i++) {
      final date = weekStart.add(Duration(days: i));
      final key =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final td = trackedMap[key];
      final tracked = td != null;
      final intake = td?.caloriesTracked ?? 0;
      final target = td?.calorieGoal ?? 0;

      totalIntake += intake;
      totalTarget += target;
      totalProtein += td?.proteinTracked ?? 0;
      totalCarbs += td?.carbsTracked ?? 0;
      totalFat += td?.fatTracked ?? 0;
      proteinTarget += td?.proteinGoal ?? 0;
      carbsTarget += td?.carbsGoal ?? 0;
      fatTarget += td?.fatGoal ?? 0;

      dailyRows.add(DailyRow(
        date: date,
        kcalIntake: intake,
        kcalTarget: target,
        net: intake - target,
        tracked: tracked,
      ));
    }

    final summary = WeeklySummary(
      totalIntake: totalIntake,
      totalTarget: totalTarget,
      totalNet: totalIntake - totalTarget,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      proteinTarget: proteinTarget,
      carbsTarget: carbsTarget,
      fatTarget: fatTarget,
    );

    emit(CalendarWeekLoaded(summary, dailyRows));
  }

  Future<void> deleteIntakeItem(
      BuildContext context, IntakeEntity intakeEntity, DateTime day) async {
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _addTrackedDayUsecase.removeDayCaloriesTracked(
        day, intakeEntity.totalKcal);
    await _addTrackedDayUsecase.removeDayMacrosTracked(day,
        carbsTracked: intakeEntity.totalCarbsGram,
        fatTracked: intakeEntity.totalFatsGram,
        proteinTracked: intakeEntity.totalProteinsGram);
  }

  Future<void> deleteUserActivityItem(BuildContext context,
      UserActivityEntity activityEntity, DateTime day) async {
    await _deleteUserActivityUsecase.deleteUserActivity(activityEntity);
    _addTrackedDayUsecase.reduceDayCalorieGoal(day, activityEntity.burnedKcal);

    final carbsAmount = MacroCalc.getTotalCarbsGoal(activityEntity.burnedKcal);
    final fatAmount = MacroCalc.getTotalFatsGoal(activityEntity.burnedKcal);
    final proteinAmount =
        MacroCalc.getTotalProteinsGoal(activityEntity.burnedKcal);

    _addTrackedDayUsecase.reduceDayMacroGoals(day,
        carbsAmount: carbsAmount,
        fatAmount: fatAmount,
        proteinAmount: proteinAmount);
    _updateDiaryPage(day);
  }

  Future<void> _updateDiaryPage(DateTime day) async {
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(LoadCalendarDayEvent(day));
  }
}
