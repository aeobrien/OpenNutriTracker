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

      // Instant load: prefer cached values from the DailyStats row instead of
      // recomputing goals (which re-hits HealthKit) and re-summing intake.
      // The cached row is kept current incrementally on every add/edit/delete,
      // so when it exists it is authoritative. Falls back to computed values
      // only when no row exists yet (before the first entry of the day).
      final cachedDay = await _getTrackedDayUsecase.getTrackedDay(currentDay);

      final double totalKcalGoal;
      final double totalCarbsGoal;
      final double totalFatsGoal;
      final double totalProteinsGoal;
      final double suppliedKcal;
      final double suppliedCarbs;
      final double suppliedFats;
      final double suppliedProteins;

      if (cachedDay != null) {
        totalKcalGoal = cachedDay.calorieGoal;
        totalCarbsGoal = cachedDay.carbsGoal ??
            await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
        totalFatsGoal = cachedDay.fatGoal ??
            await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
        totalProteinsGoal = cachedDay.proteinGoal ??
            await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);
        suppliedKcal = cachedDay.caloriesTracked;
        suppliedCarbs = cachedDay.carbsTracked ?? totalCarbsIntake;
        suppliedFats = cachedDay.fatTracked ?? totalFatsIntake;
        suppliedProteins = cachedDay.proteinTracked ?? totalProteinsIntake;
      } else {
        totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
        totalCarbsGoal =
            await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
        totalFatsGoal = await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
        totalProteinsGoal =
            await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);
        suppliedKcal = totalKcalIntake;
        suppliedCarbs = totalCarbsIntake;
        suppliedFats = totalFatsIntake;
        suppliedProteins = totalProteinsIntake;
      }

      final totalKcalLeft =
          CalorieGoalCalc.getDailyKcalLeft(totalKcalGoal, suppliedKcal);

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
          totalKcalSupplied: suppliedKcal,
          totalKcalBurned: totalKcalActivities,
          totalCarbsIntake: suppliedCarbs,
          totalFatsIntake: suppliedFats,
          totalCarbsGoal: totalCarbsGoal,
          totalFatsGoal: totalFatsGoal,
          totalProteinsGoal: totalProteinsGoal,
          totalProteinsIntake: suppliedProteins,
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

    on<RefreshActiveCaloriesEvent>((event, emit) async {
      final currentState = state;
      if (currentState is! HomeLoadedState) {
        // Nothing loaded yet — let the normal load handle it.
        add(const LoadItemsEvent());
        return;
      }

      double activeCaloriesToday = currentState.activeCaloriesToday;
      DateTime? activeCaloriesUpdatedAt = currentState.activeCaloriesUpdatedAt;
      bool healthKitConnected = currentState.healthKitConnected;
      try {
        healthKitConnected = await _healthRepository.hasPermission();
        if (healthKitConnected) {
          activeCaloriesToday =
              await _healthRepository.fetchAndCacheActiveCalories();
          final cached = await _healthRepository.getCachedActiveCalories();
          activeCaloriesUpdatedAt = cached.$2;
        }
      } catch (e) {
        _log.warning('Error refreshing HealthKit active calories', e);
        return;
      }

      // Recompute allowance-derived values from the refreshed active calories.
      final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
      final totalKcalBase =
          await _getKcalGoalUsecase.getKcalGoal(totalKcalActivitiesParam: 0);
      final totalKcalEarned = totalKcalGoal - totalKcalBase;
      final totalKcalLeft = CalorieGoalCalc.getDailyKcalLeft(
          totalKcalGoal, currentState.totalKcalSupplied);
      final totalCarbsGoal =
          await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
      final totalFatsGoal =
          await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
      final totalProteinsGoal =
          await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);

      emit(HomeLoadedState(
        showDisclaimerDialog: currentState.showDisclaimerDialog,
        totalKcalDaily: totalKcalGoal,
        totalKcalLeft: totalKcalLeft,
        totalKcalSupplied: currentState.totalKcalSupplied,
        totalKcalBurned: currentState.totalKcalBurned,
        totalCarbsIntake: currentState.totalCarbsIntake,
        totalFatsIntake: currentState.totalFatsIntake,
        totalCarbsGoal: totalCarbsGoal,
        totalFatsGoal: totalFatsGoal,
        totalProteinsGoal: totalProteinsGoal,
        totalProteinsIntake: currentState.totalProteinsIntake,
        breakfastIntakeList: currentState.breakfastIntakeList,
        lunchIntakeList: currentState.lunchIntakeList,
        dinnerIntakeList: currentState.dinnerIntakeList,
        snackIntakeList: currentState.snackIntakeList,
        userActivityList: currentState.userActivityList,
        usesImperialUnits: currentState.usesImperialUnits,
        totalKcalBase: totalKcalBase,
        totalKcalEarned: totalKcalEarned,
        weeklyRemaining: currentState.weeklyRemaining,
        activeCaloriesToday: activeCaloriesToday,
        activeCaloriesUpdatedAt: activeCaloriesUpdatedAt,
        healthKitConnected: healthKitConnected,
      ));
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

  Future<void> updateIntakeItem(
      String intakeId, Map<String, dynamic> fields) async {
    final dateTime = DateTime.now();
    // Get old intake values
    final oldIntakeObject = await _getIntakeUsecase.getIntakeById(intakeId);
    assert(oldIntakeObject != null);
    final newIntakeObject =
        await _updateIntakeUsecase.updateIntake(intakeId, fields);
    assert(newIntakeObject != null);
    if (oldIntakeObject!.amount > newIntakeObject!.amount) {
      // Amounts shrunk
      await _addTrackedDayUseCase.removeDayCaloriesTracked(
          dateTime, oldIntakeObject.totalKcal - newIntakeObject.totalKcal);
      await _addTrackedDayUseCase.removeDayMacrosTracked(dateTime,
          carbsTracked:
              oldIntakeObject.totalCarbsGram - newIntakeObject.totalCarbsGram,
          fatTracked:
              oldIntakeObject.totalFatsGram - newIntakeObject.totalFatsGram,
          proteinTracked: oldIntakeObject.totalProteinsGram -
              newIntakeObject.totalProteinsGram);
    } else if (newIntakeObject.amount > oldIntakeObject.amount) {
      // Amounts gained
      await _addTrackedDayUseCase.addDayCaloriesTracked(
          dateTime, newIntakeObject.totalKcal - oldIntakeObject.totalKcal);
      await _addTrackedDayUseCase.addDayMacrosTracked(dateTime,
          carbsTracked:
              newIntakeObject.totalCarbsGram - oldIntakeObject.totalCarbsGram,
          fatTracked:
              newIntakeObject.totalFatsGram - oldIntakeObject.totalFatsGram,
          proteinTracked: newIntakeObject.totalProteinsGram -
              oldIntakeObject.totalProteinsGram);
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
