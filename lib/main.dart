import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/intake/data/mantel_push_service.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/presentation/main_screen.dart';
import 'package:opennutritracker/core/presentation/widgets/image_full_screen.dart';
import 'package:opennutritracker/core/styles/color_schemes.dart';
import 'package:opennutritracker/core/styles/fonts.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/logger_config.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/core/utils/theme_mode_provider.dart';
import 'package:opennutritracker/features/activity_detail/activity_detail_screen.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_screen.dart';
import 'package:opennutritracker/features/add_activity/presentation/add_activity_screen.dart';
import 'package:opennutritracker/features/edit_meal/presentation/edit_meal_screen.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/outbox_sender.dart';
import 'package:opennutritracker/features/household/presentation/household_scope.dart';
import 'package:opennutritracker/features/label_scan/data/guided_capture.dart';
import 'package:opennutritracker/features/label_scan/data/household_label_reader.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';
import 'package:opennutritracker/features/label_scan/presentation/guided_capture_screen.dart';
import 'package:opennutritracker/features/today/presentation/today_page.dart';
import 'package:opennutritracker/features/onboarding/onboarding_screen.dart';
import 'package:opennutritracker/features/quick_add/presentation/quick_add_screen.dart';
import 'package:opennutritracker/features/label_scan/presentation/label_scan_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/recipe_log_screen.dart';
import 'package:opennutritracker/features/recipes/presentation/llm_recipe_screen.dart';
import 'package:opennutritracker/features/scanner/scanner_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:provider/provider.dart';

/// FCM background handler — runs in its own isolate, so it just brings Firebase
/// up. The actual diary update happens on the next foreground/app-open sync
/// (Phase A is the reliable backstop); the visible banner comes from the push
/// payload itself when the app is backgrounded.
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LoggerConfig.intiLogger();
  await initLocator();
  final isUserInitialized = await locator<UserRepository>().hasUserData();
  final configRepo = locator<ConfigRepository>();
  final savedAppTheme = await configRepo.getConfigAppTheme();
  final log = Logger('main');

  final notificationService = locator<NotificationService>();
  await notificationService.init();

  // Mantel push (Phase B). Guarded: if Firebase isn't configured yet (no
  // GoogleService-Info.plist), the app still runs — Phase-A open-app sync works.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await locator<MantelPushService>().init();
  } catch (e) {
    log.warning('Mantel push setup skipped (Firebase not configured?): $e');
  }

  log.info('Starting App ...');
  runAppWithChangeNotifiers(isUserInitialized, savedAppTheme);
}

void runAppWithChangeNotifiers(
        bool userInitialized, AppThemeEntity savedAppTheme) =>
    runApp(ChangeNotifierProvider(
        create: (_) => ThemeModeProvider(appTheme: savedAppTheme),
        child: OpenNutriTrackerApp(userInitialized: userInitialized)));

class OpenNutriTrackerApp extends StatefulWidget {
  final bool userInitialized;

  const OpenNutriTrackerApp({super.key, required this.userInitialized});

  @override
  State<OpenNutriTrackerApp> createState() => _OpenNutriTrackerAppState();
}

class _OpenNutriTrackerAppState extends State<OpenNutriTrackerApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    locator<NotificationService>().setNavigatorKey(_navigatorKey);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      onGenerateTitle: (context) => S.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
          useMaterial3: true,
          colorScheme: lightColorScheme,
          textTheme: appTextTheme),
      darkTheme: ThemeData(
          useMaterial3: true,
          colorScheme: darkColorScheme,
          textTheme: appTextTheme),
      themeMode: Provider.of<ThemeModeProvider>(context).themeMode,
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      // Wrapped around every screen, not around one of them: the figures switch
      // has to sit above anything that could show a calorie figure, and the
      // "whose phone is this" question has to be answered before any screen can
      // write to a ledger.
      builder: (context, child) => HouseholdScope(
        repository: locator<HouseholdRepository>(),
        // Started here, above every screen: anything held while the Mini was
        // unreachable is sent when the app opens and again when it comes back
        // to the front, whatever the person is looking at.
        sender: locator<OutboxSender>(),
        child: child ?? const SizedBox.shrink(),
      ),
      initialRoute: widget.userInitialized
          ? NavigationOptions.mainRoute
          : NavigationOptions.onboardingRoute,
      routes: {
        NavigationOptions.mainRoute: (context) => const MainScreen(),
        NavigationOptions.onboardingRoute: (context) =>
            const OnboardingScreen(),
        NavigationOptions.settingsRoute: (context) => const SettingsScreen(),
        NavigationOptions.addMealRoute: (context) => const AddMealScreen(),
        NavigationOptions.scannerRoute: (context) => const ScannerScreen(),
        NavigationOptions.mealDetailRoute: (context) =>
            const MealDetailScreen(),
        NavigationOptions.editMealRoute: (context) => const EditMealScreen(),
        NavigationOptions.addActivityRoute: (context) =>
            const AddActivityScreen(),
        NavigationOptions.activityDetailRoute: (context) =>
            const ActivityDetailScreen(),
        NavigationOptions.imageFullScreenRoute: (context) =>
            const ImageFullScreen(),
        NavigationOptions.quickAddRoute: (context) =>
            const QuickAddScreen(),
        NavigationOptions.labelScanRoute: (context) =>
            const LabelScanScreen(),
        NavigationOptions.recipeLogRoute: (context) =>
            const RecipeLogScreen(),
        NavigationOptions.llmRecipeRoute: (context) =>
            const LlmRecipeScreen(),
        NavigationOptions.todayRoute: (context) => const Scaffold(
              body: SafeArea(child: TodayPage()),
            ),
        // Photographing a packet: three shots in order, resumable.
        NavigationOptions.labelCaptureRoute: (context) => GuidedCaptureScreen(
              capture: locator<GuidedCapture>(),
              reader: locator<HouseholdLabelReader>(),
              logger: locator<HouseholdLogger>(),
            ),
        // The same form, opened empty — a packet typed in by hand.
        //
        // The form is a section, not a page: it is a bare Column so the guided
        // capture flow can drop it into its own layout. A route has to supply
        // what a page needs — a Material ancestor for the fields, somewhere to
        // scroll, and a way back — or seven text fields land on nothing.
        NavigationOptions.addFoodByHandRoute: (context) => Scaffold(
              appBar: AppBar(title: const Text('Add a food by hand')),
              body: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: ConfirmFoodScreen(logger: locator<HouseholdLogger>()),
                ),
              ),
            ),
      },
    );
  }
}
