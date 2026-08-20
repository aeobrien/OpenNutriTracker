import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/core/utils/calc/macro_calc.dart';
import 'package:opennutritracker/core/utils/calc/weekly_calc.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';

part 'home_event.dart';

part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;
  final GetIntakeUsecase _getIntakeUsecase;
  final DeleteIntakeUsecase _deleteIntakeUsecase;
  final UpdateIntakeUsecase _updateIntakeUsecase;
  final GetUserActivityUsecase _getUserActivityUsecase;
  final DeleteUserActivityUsecase _deleteUserActivityUsecase;
  final AddTrackedDayUsecase _addTrackedDayUseCase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final GetTrackedDayUsecase _getTrackedDayUsecase;
  final HealthRepository _healthRepository;
  final ConfigRepository _configRepository;

  final _log = Logger('HomeBloc');

  DateTime currentDay = DateTime.now();

  HomeBloc(
      this._getConfigUsecase,
      this._addConfigUsecase,
      this._getIntakeUsecase,
      this._deleteIntakeUsecase,
      this._updateIntakeUsecase,
      this._getUserActivityUsecase,
      this._deleteUserActivityUsecase,
      this._addTrackedDayUseCase,
      this._getKcalGoalUsecase,
      this._getMacroGoalUsecase,
      this._getTrackedDayUsecase,
      this._healthRepository,
      this._configRepository)
      : super(HomeInitial()) {
    on<LoadItemsEvent>((event, emit) async {
      emit(HomeLoadingState());

      currentDay = DateTime.now();
      final configData = await _getConfigUsecase.getConfig();
      final usesImperialUnits = configData.usesImperialUnits;
      final showDisclaimerDialog = !configData.hasAcceptedDisclaimer;

      final breakfastIntakeList =
          await _getIntakeUsecase.getTodayBreakfastIntake();
      final totalBreakfastKcal = getTotalKcal(breakfastIntakeList);
      final totalBreakfastCarbs = getTotalCarbs(breakfastIntakeList);
      final totalBreakfastFats = getTotalFats(breakfastIntakeList);
      final totalBreakfastProteins = getTotalProteins(breakfastIntakeList);

      final lunchIntakeList = await _getIntakeUsecase.getTodayLunchIntake();
      final totalLunchKcal = getTotalKcal(lunchIntakeList);
      final totalLunchCarbs = getTotalCarbs(lunchIntakeList);
      final totalLunchFats = getTotalFats(lunchIntakeList);
      final totalLunchProteins = getTotalProteins(lunchIntakeList);

      final dinnerIntakeList = await _getIntakeUsecase.getTodayDinnerIntake();
      final totalDinnerKcal = getTotalKcal(dinnerIntakeList);
      final totalDinnerCarbs = getTotalCarbs(dinnerIntakeList);
      final totalDinnerFats = getTotalFats(dinnerIntakeList);
      final totalDinnerProteins = getTotalProteins(dinnerIntakeList);

      final snackIntakeList = await _getIntakeUsecase.getTodaySnackIntake();
      final totalSnackKcal = getTotalKcal(snackIntakeList);
      final totalSnackCarbs = getTotalCarbs(snackIntakeList);
      final totalSnackFats = getTotalFats(snackIntakeList);
      final totalSnackProteins = getTotalProteins(snackIntakeList);

      final totalKcalIntake = totalBreakfastKcal +
          totalLunchKcal +
          totalDinnerKcal +
          totalSnackKcal;
      final totalCarbsIntake = totalBreakfastCarbs +
          totalLunchCarbs +
          totalDinnerCarbs +
          totalSnackCarbs;
      final totalFatsIntake = totalBreakfastFats +
          totalLunchFats +
          totalDinnerFats +
          totalSnackFats;
      final totalProteinsIntake = totalBreakfastProteins +
          totalLunchProteins +
          totalDinnerProteins +
          totalSnackProteins;

      final userActivities =
          await _getUserActivityUsecase.getTodayUserActivity();
      final totalKcalActivities =
          userActivities.map((activity) => activity.burnedKcal).toList().sum;

      // HealthKit permission: request once if not yet asked
      bool healthKitConnected = false;
      double activeCaloriesToday = 0.0;
      DateTime? activeCaloriesUpdatedAt;
      try {
        final hasAsked = await _configRepository.getHasAskedHealthPermission();
        if (!hasAsked) {
          final granted = await _healthRepository.requestPermission();
          if (granted) {
            // Only mark as asked if the dialog actually appeared
            await _configRepository.setHasAskedHealthPermission(true);
          }
          healthKitConnected = granted;
          _log.fine('HealthKit permission requested, granted: $granted');
        } else {
          healthKitConnected = await _healthRepository.hasPermission();
        }
        if (healthKitConnected) {
          activeCaloriesToday =
              await _healthRepository.fetchAndCacheActiveCalories();
          final cached = await _healthRepository.getCachedActiveCalories();
          activeCaloriesUpdatedAt = cached.$2;
        }
      } catch (e) {
        _log.warning('Error during HealthKit check', e);
      }

      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
      final totalCarbsGoal =
          await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
      final totalFatsGoal =
          await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
      final totalProteinsGoal =
          await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);

      final totalKcalLeft =
          CalorieGoalCalc.getDailyKcalLeft(totalKcalGoal, totalKcalIntake);

      // Compute base allowance (no exercise)
      final totalKcalBase = await _getKcalGoalUsecase.getKcalGoal(
          totalKcalActivitiesParam: 0);
      final totalKcalEarned = totalKcalGoal - totalKcalBase;

      // Compute weekly remaining
      final now = currentDay;
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final trackedDays = await _getTrackedDayUsecase.getTrackedDaysByRange(
          weekStart, now);
      double? weeklyRemaining;
      if (trackedDays.isNotEmpty) {
        final weeklyDays = trackedDays.map((td) => TrackedDay(
              target: td.calorieGoal,
              intake: td.caloriesTracked,
            )).toList();
        final summary = WeeklyCalc.aggregate(weeklyDays);
        weeklyRemaining = summary.totalRemaining;
      }

      emit(HomeLoadedState(
          showDisclaimerDialog: showDisclaimerDialog,
          totalKcalDaily: totalKcalGoal,
          totalKcalLeft: totalKcalLeft,
          totalKcalSupplied: totalKcalIntake,
          totalKcalBurned: totalKcalActivities,
          totalCarbsIntake: totalCarbsIntake,
          totalFatsIntake: totalFatsIntake,
          totalCarbsGoal: totalCarbsGoal,
          totalFatsGoal: totalFatsGoal,
          totalProteinsGoal: totalProteinsGoal,
          totalProteinsIntake: totalProteinsIntake,
          breakfastIntakeList: breakfastIntakeList,
          lunchIntakeList: lunchIntakeList,
          dinnerIntakeList: dinnerIntakeList,
          snackIntakeList: snackIntakeList,
          userActivityList: userActivities,
          usesImperialUnits: usesImperialUnits,
          totalKcalBase: totalKcalBase,
          totalKcalEarned: totalKcalEarned,
          weeklyRemaining: weeklyRemaining,
          activeCaloriesToday: activeCaloriesToday,
          activeCaloriesUpdatedAt: activeCaloriesUpdatedAt,
          healthKitConnected: healthKitConnected));
    });
  }

  double getTotalKcal(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalKcal).toList().sum;

  double getTotalCarbs(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalCarbsGram).toList().sum;

  double getTotalFats(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalFatsGram).toList().sum;

  double getTotalProteins(List<IntakeEntity> intakeList) =>
      intakeList.map((intake) => intake.totalProteinsGram).toList().sum;

  void saveConfigData(bool acceptedDisclaimer) async {
    _addConfigUsecase.setConfigDisclaimer(acceptedDisclaimer);
  }

  /// Put a correction through, and move the day's totals by exactly what
  /// changed.
  ///
  /// The difference is measured in the figures themselves and not in the
  /// amount. A row with a food behind it changes both together, but a spoken
  /// row corrected from 350 calories to 250 never changes its amount at all —
  /// counting on the amount to notice meant those corrections left the day's
  /// ring showing the old number.
  ///
  /// A row moved to the other person comes off this day entirely: it is
  /// somebody else's now, so all of it goes rather than a difference.
  Future<void> updateIntakeItem(
      String intakeId, Map<String, dynamic> fields, {int? moveTo}) async {
    final dateTime = DateTime.now();
    final before = await _getIntakeUsecase.getIntakeById(intakeId);
    if (before == null) return;
    final after = await _updateIntakeUsecase.updateIntake(intakeId, fields,
        moveTo: moveTo);

    // Take the whole of what it was off the day, then put the whole of what it
    // now is back on. Two steps rather than a signed difference so that a
    // correction which moves the calories one way and a macro the other cannot
    // land half-applied.
    await _addTrackedDayUseCase.removeDayCaloriesTracked(
        dateTime, before.totalKcal);
    await _addTrackedDayUseCase.removeDayMacrosTracked(dateTime,
        carbsTracked: before.totalCarbsGram,
        fatTracked: before.totalFatsGram,
        proteinTracked: before.totalProteinsGram);
    if (after != null) {
      await _addTrackedDayUseCase.addDayCaloriesTracked(
          dateTime, after.totalKcal);
      await _addTrackedDayUseCase.addDayMacrosTracked(dateTime,
          carbsTracked: after.totalCarbsGram,
          fatTracked: after.totalFatsGram,
          proteinTracked: after.totalProteinsGram);
    }
    _updateDiaryPage(dateTime);
  }

  Future<void> deleteIntakeItem(IntakeEntity intakeEntity) async {
    final dateTime = DateTime.now();
    await _deleteIntakeUsecase.deleteIntake(intakeEntity);
    await _addTrackedDayUseCase.removeDayCaloriesTracked(
        dateTime, intakeEntity.totalKcal);
    await _addTrackedDayUseCase.removeDayMacrosTracked(dateTime,
        carbsTracked: intakeEntity.totalCarbsGram,
        fatTracked: intakeEntity.totalFatsGram,
        proteinTracked: intakeEntity.totalProteinsGram);
    await _addTrackedDayUseCase.deleteDayIfEmpty(dateTime);

    _updateDiaryPage(dateTime);
  }

  Future<void> deleteUserActivityItem(UserActivityEntity activityEntity) async {
    final dateTime = DateTime.now();
    await _deleteUserActivityUsecase.deleteUserActivity(activityEntity);
    await _addTrackedDayUseCase.reduceDayCalorieGoal(
        dateTime, activityEntity.burnedKcal);

    final carbsAmount = MacroCalc.getTotalCarbsGoal(activityEntity.burnedKcal);
    final fatAmount = MacroCalc.getTotalFatsGoal(activityEntity.burnedKcal);
    final proteinAmount =
        MacroCalc.getTotalProteinsGoal(activityEntity.burnedKcal);

    await _addTrackedDayUseCase.reduceDayMacroGoals(dateTime,
        carbsAmount: carbsAmount,
        fatAmount: fatAmount,
        proteinAmount: proteinAmount);
    await _addTrackedDayUseCase.deleteDayIfEmpty(dateTime);
    _updateDiaryPage(dateTime);
  }

  Future<void> _updateDiaryPage(DateTime day) async {
    locator<DiaryBloc>().add(const LoadDiaryYearEvent());
    locator<CalendarDayBloc>().add(RefreshCalendarDayEvent());
  }
}
