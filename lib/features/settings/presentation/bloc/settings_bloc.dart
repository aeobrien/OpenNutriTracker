import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';

part 'settings_event.dart';

part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final log = Logger('SettingsBloc');

  final GetConfigUsecase _getConfigUsecase;
  final AddConfigUsecase _addConfigUsecase;
  final AddTrackedDayUsecase _addTrackedDayUsecase;
  final GetKcalGoalUsecase _getKcalGoalUsecase;
  final GetMacroGoalUsecase _getMacroGoalUsecase;
  final UserRepository _userRepository;
  final ConfigRepository _configRepository;

  SettingsBloc(
      this._getConfigUsecase,
      this._addConfigUsecase,
      this._addTrackedDayUsecase,
      this._getKcalGoalUsecase,
      this._getMacroGoalUsecase,
      this._userRepository,
      this._configRepository)
      : super(SettingsInitial()) {
    on<LoadSettingsEvent>((event, emit) async {
      emit(SettingsLoadingState());

      final userConfig = await _getConfigUsecase.getConfig();
      final appVersion = await AppConst.getVersionNumber();
      final usesImperialUnits = userConfig.usesImperialUnits;

      emit(SettingsLoadedState(
          appVersion,
          userConfig.hasAcceptedSendAnonymousData,
          userConfig.appTheme,
          usesImperialUnits));
    });
  }

  void setHasAcceptedAnonymousData(bool hasAcceptedAnonymousData) {
    _addConfigUsecase
        .setConfigHasAcceptedAnonymousData(hasAcceptedAnonymousData);
  }

  void setAppTheme(AppThemeEntity appTheme) async {
    await _addConfigUsecase.setConfigAppTheme(appTheme);
  }

  void setUsesImperialUnits(bool usesImperialUnits) {
    _addConfigUsecase.setConfigUsesImperialUnits(usesImperialUnits);
  }

  Future<double> getKcalAdjustment() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userKcalAdjustment ?? 0;
  }

  Future<double?> getUserCarbGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userCarbGoalPct;
  }

  Future<double?> getUserProteinGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userProteinGoalPct;
  }

  Future<double?> getUserFatGoalPct() async {
    final config = await _getConfigUsecase.getConfig();
    return config.userFatGoalPct;
  }

  void setKcalAdjustment(double kcalAdjustment) {
    _addConfigUsecase.setConfigKcalAdjustment(kcalAdjustment);
  }
  void setMacroGoals(
      double carbGoalPct, double proteinGoalPct, double fatGoalPct) {
    _addConfigUsecase.setConfigMacroGoalPct(carbGoalPct.toInt() / 100,
        proteinGoalPct.toInt() / 100, fatGoalPct.toInt() / 100);
  }

  Future<double> getTdee() async {
    final user = await _userRepository.getUserData();
    return CalorieGoalCalc.getTdee(user);
  }

  Future<double> getGoalAdjustment() async {
    final user = await _userRepository.getUserData();
    return CalorieGoalCalc.getKcalGoalAdjustment(user.goal);
  }

  Future<String> getMacroMode() async {
    return await _configRepository.getMacroMode();
  }

  Future<void> setMacroMode(String mode) async {
    await _configRepository.setMacroMode(mode);
  }

  Future<double?> getFixedProteinGrams() async {
    return await _configRepository.getFixedProteinGrams();
  }

  Future<double?> getFixedCarbsGrams() async {
    return await _configRepository.getFixedCarbsGrams();
  }

  Future<double?> getFixedFatGrams() async {
    return await _configRepository.getFixedFatGrams();
  }

  Future<void> setFixedMacroGrams(
      double protein, double carbs, double fat) async {
    await _configRepository.setFixedProteinGrams(protein);
    await _configRepository.setFixedCarbsGrams(carbs);
    await _configRepository.setFixedFatGrams(fat);
  }

  void updateTrackedDay(DateTime day) async {
    final day = DateTime.now();
    final totalKcalGoal = await _getKcalGoalUsecase.getKcalGoal();
    final totalCarbsGoal =
        await _getMacroGoalUsecase.getCarbsGoal(totalKcalGoal);
    final totalFatGoal = await _getMacroGoalUsecase.getFatsGoal(totalKcalGoal);
    final totalProteinGoal =
        await _getMacroGoalUsecase.getProteinsGoal(totalKcalGoal);

    final hasTrackedDay = await _addTrackedDayUsecase.hasTrackedDay(day);

    if (hasTrackedDay) {
      await _addTrackedDayUsecase.updateDayCalorieGoal(day, totalKcalGoal);
      await _addTrackedDayUsecase.updateDayMacroGoals(day,
          carbsGoal: totalCarbsGoal,
          fatGoal: totalFatGoal,
          proteinGoal: totalProteinGoal);
    }
  }
}

enum SystemDropDownType { metric, imperial }
