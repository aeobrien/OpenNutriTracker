/// A Home screen that can be built in a test, and whose slow parts can be held
/// open on purpose.
///
/// Home is where nearly everything Aidan has reported goes wrong, and until now
/// none of it could be driven without a phone in a hand. The awkward part is
/// not the screen: it is HomeBloc, which takes thirteen collaborators, so a
/// single stand-in was never worth writing for one test. It is worth writing
/// once.
///
/// Nothing here pretends to be clever. Each stand-in answers the one question
/// the screen asks it and nothing else, so a call that was not expected fails
/// loudly rather than quietly returning a zero.
///
/// The one deliberate feature is [HeldOpen]: a piece of work that does not
/// finish until the test lets it. That is what turns "these two lines look
/// right" into "I watched the screen wait for them" — see
/// the_ring_waits_for_the_removal_test.dart.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/entity/tracked_day_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
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
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/home_page.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/intake/data/mantel_sync_service.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/said/data/microphone.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// A piece of work the test decides when to finish.
///
/// Ask for [work] and it hangs. Call [finish] and it completes. In between,
/// whatever asked for it is waiting — which is the state a race is made of and
/// the state that is otherwise impossible to sit inside.
class HeldOpen {
  final _done = Completer<void>();
  var _asked = false;

  bool get wasAsked => _asked;
  bool get isWaiting => _asked && !_done.isCompleted;

  Future<void> work() {
    _asked = true;
    return _done.future;
  }

  void finish() {
    if (!_done.isCompleted) _done.complete();
  }
}

// --- the stand-ins ---------------------------------------------------------

class FakeGetConfig extends Fake implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);
}

class FakeAddConfig extends Fake implements AddConfigUsecase {}

/// The day, as read back out of the database. Counts every read, which is how
/// "the screen redrew" is observed.
class FakeGetIntake extends Fake implements GetIntakeUsecase {
  List<IntakeEntity> breakfast;
  var reads = 0;

  FakeGetIntake({this.breakfast = const []});

  @override
  Future<List<IntakeEntity>> getTodayBreakfastIntake() async {
    reads += 1;
    return breakfast;
  }

  @override
  Future<List<IntakeEntity>> getTodayLunchIntake() async => const [];
  @override
  Future<List<IntakeEntity>> getTodayDinnerIntake() async => const [];
  @override
  Future<List<IntakeEntity>> getTodaySnackIntake() async => const [];
}

class FakeDeleteIntake extends Fake implements DeleteIntakeUsecase {
  final HeldOpen removal;
  FakeDeleteIntake(this.removal);

  @override
  Future<void> deleteIntake(IntakeEntity intakeEntity) => removal.work();
}

class FakeUpdateIntake extends Fake implements UpdateIntakeUsecase {}

class FakeGetUserActivity extends Fake implements GetUserActivityUsecase {
  List<UserActivityEntity> today;
  FakeGetUserActivity({this.today = const []});

  @override
  Future<List<UserActivityEntity>> getTodayUserActivity() async => today;
}

class FakeDeleteUserActivity extends Fake
    implements DeleteUserActivityUsecase {
  final HeldOpen removal;
  FakeDeleteUserActivity(this.removal);

  @override
  Future<void> deleteUserActivity(UserActivityEntity activityEntity) =>
      removal.work();
}

class FakeTrackedDays extends Fake implements AddTrackedDayUsecase {
  @override
  Future<void> removeDayCaloriesTracked(DateTime day, double kcal) async {}
  @override
  Future<void> removeDayMacrosTracked(DateTime day,
      {double? carbsTracked, double? fatTracked, double? proteinTracked}) async {}
  @override
  Future<void> deleteDayIfEmpty(DateTime day) async {}
  @override
  Future<void> reduceDayCalorieGoal(DateTime day, double kcal) async {}
  @override
  Future<void> reduceDayMacroGoals(DateTime day,
      {double? carbsAmount, double? fatAmount, double? proteinAmount}) async {}
}

class FakeKcalGoal extends Fake implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoal(
          {UserEntity? userEntity,
          double? totalKcalActivitiesParam,
          double? kcalUserAdjustment}) async =>
      2000;
}

class FakeMacroGoals extends Fake implements GetMacroGoalUsecase {
  @override
  Future<double> getCarbsGoal(double kcal) async => 250;
  @override
  Future<double> getFatsGoal(double kcal) async => 65;
  @override
  Future<double> getProteinsGoal(double kcal) async => 100;
}

class FakeGetTrackedDay extends Fake implements GetTrackedDayUsecase {
  @override
  Future<TrackedDayEntity?> getTrackedDay(DateTime day) async => null;
  @override
  Future<List<TrackedDayEntity>> getTrackedDaysByRange(
          DateTime start, DateTime end) async =>
      const [];
}

/// No watch, and never asked about one.
class FakeHealth extends Fake implements HealthRepository {
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<bool> requestPermission() async => false;
}

class FakeConfigRepo extends Fake implements ConfigRepository {
  @override
  Future<bool> getHasAskedHealthPermission() async => true;
}

class QuietDiaryBloc extends Fake implements DiaryBloc {
  @override
  void add(dynamic event) {}
}

class QuietCalendarDayBloc extends Fake implements CalendarDayBloc {
  @override
  void add(dynamic event) {}
}

class QuietMealDetailBloc extends Fake implements MealDetailBloc {}

/// Says nothing, but writes down what it was asked to catch up on.
///
/// The catch-up is the retry for a spoken row that never got worked out. It
/// existed for weeks with no caller at all, so what a test has to be able to
/// see is not what it does but *that Home asks it*.
class QuietSaid extends Fake implements SaidRepository {
  /// Every set of rows Home has handed over to be caught up on.
  final askedToCatchUp = <List<LoggedItem>>[];

  /// How many of them to claim settled.
  int settles = 0;

  @override
  Future<CaughtUp> catchUp(Iterable<LoggedItem> rows) async {
    askedToCatchUp.add(rows.toList());
    return CaughtUp(settled: settles, waiting: waiting);
  }

  /// A question the catch-up should hand back, as it does when a row is still
  /// waiting to be told which meal it was.
  AQuestionStillWaiting? waiting;
}

/// A day with whatever rows a test wants on it.
class FakeDayRepository extends Fake implements DayRepository {
  final List<LoggedItem> rows;

  /// When true the Mac Mini cannot be reached, which is the ordinary case this
  /// has to survive rather than an error worth showing anybody.
  final bool unreachable;

  FakeDayRepository({this.rows = const [], this.unreachable = false});

  var asked = 0;

  @override
  Future<DayView> today(String day) async {
    asked += 1;
    if (unreachable) throw HouseholdUnreachable('nothing is listening');
    return DayView(
      day: day,
      personId: 1,
      settings: const PersonSettings(personId: 1),
      logged: rows,
      planned: const [],
      exercise: const [],
    );
  }
}

class QuietMicrophone extends Fake implements Microphone {}

/// Nothing to pull and nothing to read off a watch. Both are fired from
/// initState and neither is what any of these tests is about.
class QuietMantelSync extends Fake implements MantelSyncService {
  @override
  Future<MantelSyncResult> syncPending() async =>
      const MantelSyncResult(synced: 0, skipped: 0);
}

class QuietExerciseSync extends Fake implements ExerciseSync {
  @override
  Future<String?> syncFromHealth({required String day}) async => null;
}

// --- putting one together --------------------------------------------------

/// One Home, wired to stand-ins, with the two removals held open.
class ADrivableHome {
  final HeldOpen foodRemoval;
  final HeldOpen exerciseRemoval;
  final FakeGetIntake day;
  final HomeBloc bloc;

  /// The spoken-sentence side, exposed so a test can ask what Home asked it.
  final QuietSaid said;

  /// The household's own copy of today, which is where the rows that are still
  /// being worked out live.
  final FakeDayRepository dayAtTheHouse;

  ADrivableHome._(this.foodRemoval, this.exerciseRemoval, this.day, this.bloc,
      this.said, this.dayAtTheHouse);

  factory ADrivableHome({
    List<IntakeEntity> food = const [],
    List<UserActivityEntity> exercise = const [],
    List<LoggedItem> onTheHouseholdsDay = const [],
    bool houseUnreachable = false,
  }) {
    final foodRemoval = HeldOpen();
    final exerciseRemoval = HeldOpen();
    final day = FakeGetIntake(breakfast: food);
    final bloc = HomeBloc(
      FakeGetConfig(),
      FakeAddConfig(),
      day,
      FakeDeleteIntake(foodRemoval),
      FakeUpdateIntake(),
      FakeGetUserActivity(today: exercise),
      FakeDeleteUserActivity(exerciseRemoval),
      FakeTrackedDays(),
      FakeKcalGoal(),
      FakeMacroGoals(),
      FakeGetTrackedDay(),
      FakeHealth(),
      FakeConfigRepo(),
    );
    return ADrivableHome._(
      foodRemoval,
      exerciseRemoval,
      day,
      bloc,
      QuietSaid(),
      FakeDayRepository(
          rows: onTheHouseholdsDay, unreachable: houseUnreachable),
    );
  }

  /// Register everything Home reaches for out of the locator.
  void register() {
    GetIt.instance
      ..registerSingleton<HomeBloc>(bloc)
      ..registerSingleton<DiaryBloc>(QuietDiaryBloc())
      ..registerSingleton<CalendarDayBloc>(QuietCalendarDayBloc())
      ..registerSingleton<MealDetailBloc>(QuietMealDetailBloc())
      ..registerSingleton<SaidRepository>(said)
      ..registerSingleton<DayRepository>(dayAtTheHouse)
      ..registerSingleton<Microphone>(QuietMicrophone())
      ..registerSingleton<MantelSyncService>(QuietMantelSync())
      ..registerSingleton<ExerciseSync>(QuietExerciseSync());
  }

  Widget get widget => MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        // Home lives inside the app's Scaffold in real life, and some of
        // what it builds needs one above it.
        home: const Scaffold(body: HomePage()),
      );
}

/// Give the page room.
///
/// Home is a long scrolling page and the meal lists sit below the fold. On a
/// default test screen they are never built, so a finder for a row on the day
/// finds nothing and the failure looks like the row is missing rather than
/// merely out of sight. A tall surface builds the whole page at once.
void giveTheScreenRoom(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// A row on the day, plain and countable.
IntakeEntity aRowOf(double kcal, {String id = 'row-1', String label = 'Toast'}) =>
    IntakeEntity(
      id: id,
      unit: 'serving',
      amount: 1,
      type: IntakeTypeEntity.breakfast,
      meal: MealEntity.empty(),
      dateTime: DateTime.now(),
      entryType: 'quickAdd',
      quickAddLabel: label,
      snapshotKcal: kcal,
    );
