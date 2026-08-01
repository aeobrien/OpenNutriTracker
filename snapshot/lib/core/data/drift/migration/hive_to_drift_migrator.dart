import 'dart:typed_data';

import 'package:uuid/uuid.dart';
import 'package:drift/drift.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/data_source/user_activity_dbo.dart';
import 'package:opennutritracker/core/data/dbo/config_dbo.dart';
import 'package:opennutritracker/core/data/dbo/intake_dbo.dart';
import 'package:opennutritracker/core/data/dbo/tracked_day_dbo.dart';
import 'package:opennutritracker/core/data/dbo/user_dbo.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';

class HiveToDriftMigrator {
  static const _migrationFlag = 'hive_migrated';
  final _log = Logger('HiveToDriftMigrator');

  final AppDatabase _db;
  final ConfigDao _configDao;

  HiveToDriftMigrator(this._db, this._configDao);

  Future<bool> needsMigration() async {
    final flag = await _configDao.getValue(_migrationFlag);
    return flag != 'true';
  }

  Future<void> migrate(Uint8List encryptionKey) async {
    if (!await needsMigration()) {
      _log.fine('Migration already completed, skipping');
      return;
    }

    _log.info('Starting Hive → drift migration');

    try {
      final encryptionCypher = HiveAesCipher(encryptionKey);

      // Open Hive boxes for reading
      final configBox = await Hive.openBox<ConfigDBO>(
          'ConfigBox', encryptionCipher: encryptionCypher);
      final intakeBox = await Hive.openBox<IntakeDBO>(
          'IntakeBox', encryptionCipher: encryptionCypher);
      final userActivityBox = await Hive.openBox<UserActivityDBO>(
          'UserActivityBox', encryptionCipher: encryptionCypher);
      final userBox = await Hive.openBox<UserDBO>(
          'UserBox', encryptionCipher: encryptionCypher);
      final trackedDayBox = await Hive.openBox<TrackedDayDBO>(
          'TrackedDayBox', encryptionCipher: encryptionCypher);

      await _db.transaction(() async {
        // Migrate config
        await _migrateConfig(configBox);

        // Migrate user profile
        await _migrateUser(userBox);

        // Migrate intakes (and extract food items)
        await _migrateIntakes(intakeBox);

        // Migrate tracked days
        await _migrateTrackedDays(trackedDayBox);

        // Migrate user activities
        await _migrateUserActivities(userActivityBox);

        // Set migration flag
        await _configDao.setValue(_migrationFlag, 'true');
      });

      _log.info('Hive → drift migration completed successfully');
    } catch (e, st) {
      _log.severe('Migration failed', e, st);
      // Set flag anyway to avoid re-attempting a broken migration
      // The app will work with an empty database
      await _configDao.setValue(_migrationFlag, 'true');
      rethrow;
    }
  }

  Future<void> _migrateConfig(Box<ConfigDBO> configBox) async {
    final config = configBox.get('ConfigKey');
    if (config == null) return;

    _log.fine('Migrating config');
    await _configDao.setBool('hasAcceptedDisclaimer', config.hasAcceptedDisclaimer);
    await _configDao.setBool('hasAcceptedPolicy', config.hasAcceptedPolicy);
    await _configDao.setBool(
        'hasAcceptedSendAnonymousData', config.hasAcceptedSendAnonymousData);
    await _configDao.setValue('selectedAppTheme', config.selectedAppTheme.name);
    await _configDao.setBool(
        'usesImperialUnits', config.usesImperialUnits ?? false);
    if (config.userKcalAdjustment != null) {
      await _configDao.setDouble('userKcalAdjustment', config.userKcalAdjustment!);
    }
    if (config.userCarbGoalPct != null) {
      await _configDao.setDouble('userCarbGoalPct', config.userCarbGoalPct!);
    }
    if (config.userProteinGoalPct != null) {
      await _configDao.setDouble('userProteinGoalPct', config.userProteinGoalPct!);
    }
    if (config.userFatGoalPct != null) {
      await _configDao.setDouble('userFatGoalPct', config.userFatGoalPct!);
    }
  }

  Future<void> _migrateUser(Box<UserDBO> userBox) async {
    final user = userBox.get('UserKey');
    if (user == null) return;

    _log.fine('Migrating user profile');
    await _db.into(_db.userProfile).insertOnConflictUpdate(
      UserProfileCompanion(
        id: const Value(1),
        birthday: Value(user.birthday.millisecondsSinceEpoch),
        heightCm: Value(user.heightCM),
        weightKg: Value(user.weightKG),
        gender: Value(user.gender.name),
        goal: Value(user.goal.name),
        pal: Value(user.pal.name),
      ),
    );
  }

  Future<void> _migrateIntakes(Box<IntakeDBO> intakeBox) async {
    final intakes = intakeBox.values.toList();
    _log.fine('Migrating ${intakes.length} intakes');

    final foodItemIds = <String, String>{}; // dedup key → food item id

    for (final intake in intakes) {
      final meal = intake.meal;

      // Generate a deterministic food item ID
      final dedupKey = meal.code ?? _hashKey('${meal.name}_${meal.brands}');
      final foodItemId = foodItemIds[dedupKey] ?? dedupKey;
      foodItemIds[dedupKey] = foodItemId;

      // Upsert food item
      await _db.into(_db.foodItems).insertOnConflictUpdate(
        FoodItemsCompanion(
          id: Value(foodItemId),
          source: Value(meal.source.name),
          barcode: Value(meal.code),
          name: Value(meal.name),
          brand: Value(meal.brands),
          mealQuantity: Value(meal.mealQuantity),
          mealUnit: Value(meal.mealUnit),
          servingQuantity: Value(meal.servingQuantity),
          servingUnit: Value(meal.servingUnit),
          servingSize: Value(meal.servingSize),
          kcalPer100: Value(meal.nutriments.energyKcal100),
          proteinPer100: Value(meal.nutriments.proteins100),
          carbsPer100: Value(meal.nutriments.carbohydrates100),
          fatPer100: Value(meal.nutriments.fat100),
          fibrePer100: Value(meal.nutriments.fiber100),
          sugarPer100: Value(meal.nutriments.sugars100),
          saturatedFatPer100: Value(meal.nutriments.saturatedFat100),
          thumbnailImageUrl: Value(meal.thumbnailImageUrl),
          mainImageUrl: Value(meal.mainImageUrl),
          url: Value(meal.url),
          lastUsedAt: Value(intake.dateTime.millisecondsSinceEpoch),
          lastUsedGrams: Value(intake.amount),
        ),
      );

      // Compute snapshot values
      final energyPerUnit = (meal.nutriments.energyKcal100 ?? 0) / 100;
      final proteinPerUnit = (meal.nutriments.proteins100 ?? 0) / 100;
      final carbsPerUnit = (meal.nutriments.carbohydrates100 ?? 0) / 100;
      final fatPerUnit = (meal.nutriments.fat100 ?? 0) / 100;

      // Insert log entry
      await _db.into(_db.logEntries).insert(
        LogEntriesCompanion(
          id: Value(intake.id),
          timestamp: Value(intake.dateTime.millisecondsSinceEpoch),
          mealSlot: Value(intake.type.name),
          foodItemId: Value(foodItemId),
          amount: Value(intake.amount),
          unit: Value(intake.unit),
          snapshotKcal: Value(intake.amount * energyPerUnit),
          snapshotProtein: Value(intake.amount * proteinPerUnit),
          snapshotCarbs: Value(intake.amount * carbsPerUnit),
          snapshotFat: Value(intake.amount * fatPerUnit),
        ),
      );
    }
  }

  Future<void> _migrateTrackedDays(Box<TrackedDayDBO> trackedDayBox) async {
    final trackedDays = trackedDayBox.values.toList();
    _log.fine('Migrating ${trackedDays.length} tracked days');

    for (final td in trackedDays) {
      // Use the DateTime field, NOT the locale-dependent Hive key
      final dateKey =
          '${td.day.year}-${td.day.month.toString().padLeft(2, '0')}-${td.day.day.toString().padLeft(2, '0')}';

      await _db.into(_db.dailyStats).insertOnConflictUpdate(
        DailyStatsCompanion(
          date: Value(dateKey),
          calorieGoal: Value(td.calorieGoal),
          caloriesTracked: Value(td.caloriesTracked),
          carbsGoal: Value(td.carbsGoal),
          carbsTracked: Value(td.carbsTracked),
          fatGoal: Value(td.fatGoal),
          fatTracked: Value(td.fatTracked),
          proteinGoal: Value(td.proteinGoal),
          proteinTracked: Value(td.proteinTracked),
        ),
      );
    }
  }

  Future<void> _migrateUserActivities(
      Box<UserActivityDBO> userActivityBox) async {
    final activities = userActivityBox.values.toList();
    _log.fine('Migrating ${activities.length} user activities');

    for (final activity in activities) {
      final pa = activity.physicalActivityDBO;

      await _db.into(_db.userActivities).insert(
        UserActivitiesCompanion(
          id: Value(activity.id),
          date: Value(activity.date.millisecondsSinceEpoch),
          duration: Value(activity.duration),
          burnedKcal: Value(activity.burnedKcal),
          activityCode: Value(pa.code),
          activityName: Value(pa.specificActivity),
          activityDescription: Value(pa.description),
          activityMets: Value(pa.mets),
          activityType: Value(pa.type.name),
        ),
      );
    }
  }

  static const _uuid = Uuid();
  // Fixed namespace for deterministic food item ID generation
  static const _namespace = '6ba7b810-9dad-11d1-80b4-00c04fd430c8';

  static String _hashKey(String input) {
    return _uuid.v5(_namespace, input);
  }
}
