/// Opening the Today screen used to ask Apple Health for the same number twice.
///
/// The screen reads how many calories the watch recorded today, and then works
/// out the day's allowance — which needs the very same figure, and went back to
/// the watch to get it. Two round trips for one number, on the slowest step of
/// opening the app.
///
/// This counts the trips, because that is the only honest way to claim it. A
/// stopwatch in a test measures the machine it runs on; a count measures the
/// thing that was actually changed.
///
/// The second test is the guard rail. There is an older version of this
/// speed-up that reads the day's allowance off the saved row and skips the
/// calculation altogether. That is faster still and it is wrong here: the saved
/// allowance does not include what the watch recorded — only hand-logged
/// exercise ever writes to it — so a walk would stop moving the ring. The test
/// below fails if anyone reintroduces that.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/health_data_source.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_gender_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_pal_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_weight_goal_entity.dart';
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
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';

void main() {
  late AppDatabase db;
  late DailyStatsDao dao;
  late _TheWatch watch;
  late HomeBloc bloc;

  const walkedOffToday = 450.0;

  DateTime today() => DateTime.now();

  String keyFor(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  setUp(() {
    db = AppDatabase.createInMemory();
    dao = DailyStatsDao(db);
    final trackedDays = TrackedDayRepository(dao);
    watch = _TheWatch(walkedOffToday);
    final health = HealthRepository(watch, dao);
    final settings = _Settings();

    // The real allowance calculation, not a stand-in — the whole question is
    // what it does and does not go and fetch for itself.
    final theAllowance = GetKcalGoalUsecase(
      _HisDetails(),
      settings,
      _NothingLoggedByHand(),
      health,
      _NoHousehold(),
    );

    bloc = HomeBloc(
      _Config(),
      _NoConfigWrites(),
      _NoIntake(),
      _NoDeletes(),
      _NoUpdates(),
      _NoActivity(),
      _NoActivityDeletes(),
      AddTrackedDayUsecase(trackedDays),
      theAllowance,
      _Macros(),
      GetTrackedDayUsecase(trackedDays),
      health,
      settings,
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  Future<HomeLoadedState> openTheApp() async {
    bloc.add(const LoadItemsEvent());
    return await bloc.stream.firstWhere((s) => s is HomeLoadedState)
        as HomeLoadedState;
  }

  test('opening it asks the watch for today once, not twice', () async {
    await openTheApp();

    expect(watch.timesAsked, 1,
        reason: 'the allowance is worked out from the figure the screen has '
            'already got, rather than fetching it again');
  });

  test('a walk still moves the ring on a day that already has a row',
      () async {
    // The day already exists, with an allowance saved on it that knows nothing
    // about the walk — which is how every saved allowance looks, because only
    // hand-logged exercise writes to it.
    await dao.upsert(DailyStatsCompanion.insert(
      date: keyFor(today()),
      calorieGoal: 1800,
    ));

    final shown = await openTheApp();

    expect(shown.totalKcalDaily, isNot(1800),
        reason: 'reading the saved allowance back would freeze the ring');
    expect(shown.totalKcalEarned, greaterThan(0),
        reason: 'the 450 the watch recorded has to be on the ring somewhere');
    expect(shown.totalKcalDaily, greaterThan(shown.totalKcalBase),
        reason: 'the day he walks is not the same as the day he does not');
  });
}

// ---------------------------------------------------------------------------
// The collaborators. Anything the screen asks for that is not answered here
// throws, so a test cannot quietly pass on a zero nobody meant.
// ---------------------------------------------------------------------------

/// Counts how many times anything goes to Apple Health for today's figure.
class _TheWatch implements HealthDataSource {
  final double _calories;
  int timesAsked = 0;

  _TheWatch(this._calories);

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<double> getActiveCaloriesToday() async {
    timesAsked++;
    return _calories;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}

class _HisDetails implements UserRepository {
  @override
  Future<UserEntity> getUserData() async => UserEntity(
        birthday: DateTime(1990, 1, 1),
        heightCM: 180,
        weightKG: 80,
        gender: UserGenderEntity.male,
        goal: UserWeightGoalEntity.maintainWeight,
        pal: UserPALEntity.lowActive,
      );

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}

/// Serves both the screen (has the health question been asked?) and the
/// allowance calculation (what has he set?), because in the app they are the
/// same object.
class _Settings implements ConfigRepository {
  @override
  Future<bool> getHasAskedHealthPermission() async => true;

  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}

class _NothingLoggedByHand implements UserActivityRepository {
  @override
  Future<List<UserActivityEntity>> getAllUserActivityByDate(
          DateTime date) async =>
      const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}

/// Nobody has claimed this phone, so the app's own calculation is in force.
class _NoHousehold implements HouseholdRepository {
  @override
  Future<int?> storedOwner() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}

class _NoConfigWrites implements AddConfigUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
      'the Home screen should not have called ${invocation.memberName}');
}

class _NoDeletes implements DeleteIntakeUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
      'the Home screen should not have called ${invocation.memberName}');
}

class _NoUpdates implements UpdateIntakeUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
      'the Home screen should not have called ${invocation.memberName}');
}

class _NoActivityDeletes implements DeleteUserActivityUsecase {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw StateError(
      'the Home screen should not have called ${invocation.memberName}');
}

class _Config implements GetConfigUsecase {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}

class _NoIntake implements GetIntakeUsecase {
  @override
  Future<List<IntakeEntity>> getTodayBreakfastIntake() async => const [];

  @override
  Future<List<IntakeEntity>> getTodayLunchIntake() async => const [];

  @override
  Future<List<IntakeEntity>> getTodayDinnerIntake() async => const [];

  @override
  Future<List<IntakeEntity>> getTodaySnackIntake() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}

class _NoActivity implements GetUserActivityUsecase {
  @override
  Future<List<UserActivityEntity>> getTodayUserActivity() async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}

class _Macros implements GetMacroGoalUsecase {
  @override
  Future<double> getCarbsGoal(double totalKcalGoal) async => 270.0;

  @override
  Future<double> getFatsGoal(double totalKcalGoal) async => 80.0;

  @override
  Future<double> getProteinsGoal(double totalKcalGoal) async => 120.0;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}
