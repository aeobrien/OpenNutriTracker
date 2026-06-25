import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/data_source/health_data_source.dart';
import 'package:opennutritracker/core/data/data_source/physical_activity_data_source.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/recipe_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/user_activity_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/user_profile_dao.dart';
import 'package:opennutritracker/core/data/drift/migration/hive_to_drift_migrator.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/data/repository/recipe_repository.dart';
import 'package:opennutritracker/core/data/repository/physical_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/usecase/add_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/delete_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_config_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_health_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_macro_goal_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_physical_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_tracked_day_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_activity_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/get_user_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/core/utils/hive_db_provider.dart';
import 'package:opennutritracker/core/utils/ont_image_cache_manager.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/activity_detail/presentation/bloc/activity_detail_bloc.dart';
import 'package:opennutritracker/features/add_activity/presentation/bloc/activities_bloc.dart';
import 'package:opennutritracker/features/add_activity/presentation/bloc/recent_activities_bloc.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/fdc_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';
import 'package:opennutritracker/features/add_meal/data/repository/products_repository.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/add_meal_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/food_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/recent_meal_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/edit_meal/presentation/bloc/edit_meal_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/onboarding/presentation/bloc/onboarding_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';
import 'package:opennutritracker/features/scanner/presentation/scanner_bloc.dart';
import 'package:opennutritracker/features/label_scan/data/data_source/openai_data_source.dart';
import 'package:opennutritracker/features/label_scan/domain/usecase/extract_nutrition_usecase.dart';
import 'package:opennutritracker/features/label_scan/presentation/bloc/label_scan_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_list_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_builder_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/recipe_log_bloc.dart';
import 'package:opennutritracker/features/recipes/presentation/bloc/llm_recipe_bloc.dart';
import 'package:opennutritracker/features/recipes/data/data_source/claude_recipe_data_source.dart';
import 'package:opennutritracker/features/recipes/domain/usecase/resolve_ingredients_usecase.dart';
import 'package:opennutritracker/features/intake/data/mantel_sync_service.dart';
import 'package:opennutritracker/features/intake/data/mantel_push_service.dart';
import 'package:opennutritracker/features/settings/domain/usecase/export_data_usecase.dart';
import 'package:opennutritracker/features/settings/domain/usecase/import_data_usecase.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/export_import_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:logging/logging.dart';

final locator = GetIt.instance;

Future<void> initLocator() async {
  final log = Logger('Locator');

  // Init secure storage (still needed for Hive migration encryption key)
  final secureAppStorageProvider = SecureAppStorageProvider();
  final encryptionKey = await secureAppStorageProvider.getHiveEncryptionKey();

  // Create drift database
  final appDatabase = AppDatabase.create();

  // Register Hive adapters for migration (no boxes opened yet)
  final hiveDBProvider = HiveDBProvider();
  await hiveDBProvider.initHiveDB(encryptionKey);

  // Create DAOs
  final configDao = ConfigDao(appDatabase);
  final logEntryDao = LogEntryDao(appDatabase);
  final foodItemDao = FoodItemDao(appDatabase);
  final dailyStatsDao = DailyStatsDao(appDatabase);
  final userProfileDao = UserProfileDao(appDatabase);
  final userActivityDao = UserActivityDao(appDatabase);
  final recipeDao = RecipeDao(appDatabase);

  // Run Hive → drift migration if needed
  final migrator = HiveToDriftMigrator(appDatabase, configDao);
  try {
    await migrator.migrate(encryptionKey);
  } catch (e) {
    log.severe('Hive migration failed, continuing with empty database', e);
  }

  // Register DAOs for direct access
  locator.registerLazySingleton<FoodItemDao>(() => foodItemDao);
  locator.registerLazySingleton<RecipeDao>(() => recipeDao);

  // Cache manager
  locator
      .registerLazySingleton<CacheManager>(() => OntImageCacheManager.instance);

  // BLoCs
  locator.registerLazySingleton<OnboardingBloc>(
      () => OnboardingBloc(locator(), locator()));
  locator.registerLazySingleton<HomeBloc>(() => HomeBloc(
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator(),
      locator()));
  locator.registerLazySingleton(() => DiaryBloc(locator(), locator()));
  locator.registerLazySingleton(() => CalendarDayBloc(
      locator(), locator(), locator(), locator(), locator(), locator()));
  locator.registerLazySingleton<ProfileBloc>(
      () => ProfileBloc(locator(), locator(), locator(), locator(), locator()));
  locator.registerLazySingleton(() => SettingsBloc(
      locator(), locator(), locator(), locator(), locator(),
      locator(), locator()));
  locator.registerFactory(() => ExportImportBloc(locator(), locator()));

  locator.registerFactory<ActivitiesBloc>(() => ActivitiesBloc(locator()));
  locator.registerFactory<RecentActivitiesBloc>(
      () => RecentActivitiesBloc(locator()));
  locator.registerFactory<ActivityDetailBloc>(() => ActivityDetailBloc(
      locator(), locator(), locator(), locator(), locator()));
  locator.registerFactory<MealDetailBloc>(
      () => MealDetailBloc(locator(), locator(), locator(), locator()));
  locator.registerFactory<ScannerBloc>(() => ScannerBloc(locator(), locator()));
  locator.registerFactory<EditMealBloc>(() => EditMealBloc(locator()));
  locator.registerFactory<AddMealBloc>(() => AddMealBloc(locator()));
  locator
      .registerFactory<ProductsBloc>(() => ProductsBloc(locator(), locator()));
  locator.registerFactory<FoodBloc>(() => FoodBloc(locator(), locator()));
  locator.registerFactory(() => RecentMealBloc(locator(), locator()));

  // Recipe BLoCs
  locator.registerLazySingleton<RecipeListBloc>(() => RecipeListBloc(locator()));
  locator.registerFactory<RecipeBuilderBloc>(
      () => RecipeBuilderBloc(locator()));
  locator.registerFactory<RecipeLogBloc>(
      () => RecipeLogBloc(locator(), locator(), locator()));
  locator.registerLazySingleton<ResolveIngredientsUsecase>(
      () => ResolveIngredientsUsecase(foodItemDao, locator()));
  locator.registerFactory<LlmRecipeBloc>(() => LlmRecipeBloc(
      locator(), locator(), locator(), secureAppStorageProvider));

  // UseCases
  locator.registerLazySingleton<GetConfigUsecase>(
      () => GetConfigUsecase(locator()));
  locator.registerLazySingleton<AddConfigUsecase>(
      () => AddConfigUsecase(locator()));
  locator
      .registerLazySingleton<GetUserUsecase>(() => GetUserUsecase(locator()));
  locator
      .registerLazySingleton<AddUserUsecase>(() => AddUserUsecase(locator()));
  locator.registerLazySingleton<SearchProductsUseCase>(
      () => SearchProductsUseCase(locator()));
  locator.registerLazySingleton<SearchProductByBarcodeUseCase>(
      () => SearchProductByBarcodeUseCase(locator()));
  locator.registerLazySingleton<GetIntakeUsecase>(
      () => GetIntakeUsecase(locator()));
  locator.registerLazySingleton<AddIntakeUsecase>(
      () => AddIntakeUsecase(locator()));
  locator.registerLazySingleton<DeleteIntakeUsecase>(
      () => DeleteIntakeUsecase(locator()));
  locator.registerLazySingleton<UpdateIntakeUsecase>(
      () => UpdateIntakeUsecase(locator()));
  locator.registerLazySingleton<GetUserActivityUsecase>(
      () => GetUserActivityUsecase(locator()));
  locator.registerLazySingleton<AddUserActivityUsecase>(
      () => AddUserActivityUsecase(locator()));
  locator.registerLazySingleton<DeleteUserActivityUsecase>(
      () => DeleteUserActivityUsecase(locator()));
  locator.registerLazySingleton<GetPhysicalActivityUsecase>(
      () => GetPhysicalActivityUsecase(locator()));
  locator.registerLazySingleton<GetTrackedDayUsecase>(
      () => GetTrackedDayUsecase(locator()));
  locator.registerLazySingleton<AddTrackedDayUsecase>(
      () => AddTrackedDayUsecase(locator()));
  locator.registerLazySingleton(
      () => GetKcalGoalUsecase(locator(), locator(), locator(), locator()));
  locator.registerLazySingleton<GetHealthUsecase>(
      () => GetHealthUsecase(locator(), locator()));
  locator.registerLazySingleton(() => GetMacroGoalUsecase(locator()));
  locator.registerLazySingleton(
      () => ExportDataUsecase(locator(), locator(), locator(),
          foodItemDao, recipeDao));
  locator.registerLazySingleton(
      () => ImportDataUsecase(locator(), locator(), locator(),
          foodItemDao, recipeDao));

  // Repositories
  locator.registerLazySingleton(() => ConfigRepository(configDao));
  locator.registerLazySingleton<UserRepository>(
      () => UserRepository(userProfileDao));
  locator.registerLazySingleton<IntakeRepository>(
      () => IntakeRepository(logEntryDao, foodItemDao));
  locator.registerLazySingleton<ProductsRepository>(
      () => ProductsRepository(locator(), locator()));
  locator.registerLazySingleton<UserActivityRepository>(
      () => UserActivityRepository(userActivityDao));
  locator.registerLazySingleton<PhysicalActivityRepository>(
      () => PhysicalActivityRepository(locator()));
  locator.registerLazySingleton<TrackedDayRepository>(
      () => TrackedDayRepository(dailyStatsDao));
  locator.registerLazySingleton<HealthRepository>(
      () => HealthRepository(locator(), dailyStatsDao));
  locator.registerLazySingleton<RecipeRepository>(
      () => RecipeRepository(recipeDao));

  // Mantel meal sync (one-way pull of voice/chat-logged meals into the diary).
  locator.registerLazySingleton<MantelSyncService>(() =>
      MantelSyncService(locator<IntakeRepository>(), secureAppStorageProvider));
  // Mantel push (Phase B) — registers the device + syncs on a push.
  locator.registerLazySingleton<MantelPushService>(() => MantelPushService(
      locator<MantelSyncService>(),
      locator<NotificationService>(),
      secureAppStorageProvider));

  // DataSources (only non-Hive ones remain)
  locator.registerLazySingleton<PhysicalActivityDataSource>(
      () => PhysicalActivityDataSource());
  locator.registerLazySingleton<OFFDataSource>(() => OFFDataSource());
  locator.registerLazySingleton<FDCDataSource>(() => FDCDataSource());
  locator.registerLazySingleton<HealthDataSource>(() => HealthDataSource());
  locator.registerLazySingleton<OpenAiDataSource>(() => OpenAiDataSource());
  locator.registerLazySingleton<ClaudeRecipeDataSource>(
      () => ClaudeRecipeDataSource());

  // Label scan
  locator.registerLazySingleton<ExtractNutritionUsecase>(
      () => ExtractNutritionUsecase(locator(), secureAppStorageProvider));
  locator.registerFactory<LabelScanBloc>(
      () => LabelScanBloc(locator()));

  // Notification service
  locator.registerLazySingleton<NotificationService>(
      () => NotificationService());

  // Initialize config if needed
  await _initializeConfig(locator());
}

Future<void> _initializeConfig(ConfigRepository configRepository) async {
  if (!await configRepository.configInitialized()) {
    configRepository.initializeConfig();
  }
}
