import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';

class ConfigRepository {
  final ConfigDao _configDao;
  final _log = Logger('ConfigRepository');

  ConfigRepository(this._configDao);

  Future<void> updateConfig(ConfigEntity configEntity) async {
    _log.fine('Updating config');
    await _configDao.setBool(
        'hasAcceptedDisclaimer', configEntity.hasAcceptedDisclaimer);
    await _configDao.setBool(
        'hasAcceptedPolicy', configEntity.hasAcceptedPolicy);
    await _configDao.setBool(
        'hasAcceptedSendAnonymousData', configEntity.hasAcceptedSendAnonymousData);
    await _configDao.setValue('selectedAppTheme', configEntity.appTheme.name);
    await _configDao.setBool(
        'usesImperialUnits', configEntity.usesImperialUnits);
  }

  Future<void> setConfigDisclaimer(bool hasAcceptedDisclaimer) async {
    await _configDao.setBool('hasAcceptedDisclaimer', hasAcceptedDisclaimer);
  }

  Future<void> setConfigHasAcceptedAnonymousData(
      bool hasAcceptedAnonymousData) async {
    await _configDao.setBool(
        'hasAcceptedSendAnonymousData', hasAcceptedAnonymousData);
  }

  Future<bool> getConfigHasAcceptedAnonymousData() async {
    return await _configDao.getBool('hasAcceptedSendAnonymousData');
  }

  Future<AppThemeEntity> getConfigAppTheme() async {
    final themeStr = await _configDao.getValue('selectedAppTheme');
    if (themeStr == null) return AppThemeEntity.system;
    return AppThemeEntity.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => AppThemeEntity.system);
  }

  Future<void> setConfigAppTheme(AppThemeEntity appTheme) async {
    await _configDao.setValue('selectedAppTheme', appTheme.name);
  }

  Future<ConfigEntity> getConfig() async {
    final all = await _configDao.getAll();
    return ConfigEntity(
      all['hasAcceptedDisclaimer'] == 'true',
      all['hasAcceptedPolicy'] == 'true',
      all['hasAcceptedSendAnonymousData'] == 'true',
      AppThemeEntity.values.firstWhere(
          (e) => e.name == (all['selectedAppTheme'] ?? 'system'),
          orElse: () => AppThemeEntity.system),
      usesImperialUnits: all['usesImperialUnits'] == 'true',
      userKcalAdjustment: all['userKcalAdjustment'] != null
          ? double.tryParse(all['userKcalAdjustment']!)
          : null,
      userCarbGoalPct: all['userCarbGoalPct'] != null
          ? double.tryParse(all['userCarbGoalPct']!)
          : null,
      userProteinGoalPct: all['userProteinGoalPct'] != null
          ? double.tryParse(all['userProteinGoalPct']!)
          : null,
      userFatGoalPct: all['userFatGoalPct'] != null
          ? double.tryParse(all['userFatGoalPct']!)
          : null,
      exerciseMultiplier: all['exerciseMultiplier'] != null
          ? double.tryParse(all['exerciseMultiplier']!)
          : null,
    );
  }

  Future<bool> configInitialized() async {
    final val = await _configDao.getValue('hasAcceptedDisclaimer');
    return val != null;
  }

  Future<void> initializeConfig() async {
    await _configDao.setBool('hasAcceptedDisclaimer', false);
    await _configDao.setBool('hasAcceptedPolicy', false);
    await _configDao.setBool('hasAcceptedSendAnonymousData', false);
    await _configDao.setValue('selectedAppTheme', 'system');
    await _configDao.setBool('usesImperialUnits', false);
  }

  Future<void> setConfigUsesImperialUnits(bool usesImperialUnits) async {
    await _configDao.setBool('usesImperialUnits', usesImperialUnits);
  }

  Future<double> getConfigKcalAdjustment() async {
    return await _configDao.getDouble('userKcalAdjustment') ?? 0;
  }

  Future<void> setConfigKcalAdjustment(double kcalAdjustment) async {
    await _configDao.setDouble('userKcalAdjustment', kcalAdjustment);
  }

  Future<void> setUserMacroPct(
      double carbs, double protein, double fat) async {
    await _configDao.setDouble('userCarbGoalPct', carbs);
    await _configDao.setDouble('userProteinGoalPct', protein);
    await _configDao.setDouble('userFatGoalPct', fat);
  }

  Future<double> getExerciseMultiplier() async {
    return await _configDao.getDouble('exerciseMultiplier') ?? 0.75;
  }

  Future<void> setExerciseMultiplier(double multiplier) async {
    await _configDao.setDouble('exerciseMultiplier', multiplier);
  }
}
