import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/data_source/health_data_source.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/daily_stats_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/data/repository/tracked_day_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
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
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

/// The day he opens the app, walks 450 calories off, and logs no food at all.
///
/// Until this test was written that day kept nothing. The watch's figure was
/// written against today's row in the app's own database, today had no row
/// because a row is only ever created by logging something, and an UPDATE that
/// matches no rows is not an error — it is a success that changed nothing. The
/// figure went nowhere and said so to no one.
///
/// The test drives the Home screen the way opening the app drives it, and then
/// asks the database what it kept. It does not name the method that was
/// changed, on purpose: it has to be a test the old code could run and fail,
/// not one the old code could not compile.
const theDaysTargetValue = 2400.0;

void main() {
  late AppDatabase db;
  late DailyStatsDao dao;
  late HomeBloc bloc;

  const watchSaysToday = 450.0;

  DateTime today() => DateTime.now();

  String keyFor(DateTime day) =>
      '${day.year}-${day.month.toString().padLeft(2, '0')}-'
      '${day.day.toString().padLeft(2, '0')}';

  setUp(() {
    db = AppDatabase.createInMemory();
    dao = DailyStatsDao(db);
    final trackedDays = TrackedDayRepository(dao);
    bloc = HomeBloc(
      _Config(),
      _NoConfigWrites(),
      _NoIntake(),
      _NoDeletes(),
      _NoUpdates(),
      _NoActivity(),
      _NoActivityDeletes(),
      AddTrackedDayUsecase(trackedDays),
      _Target(),
      _Macros(),
      GetTrackedDayUsecase(trackedDays),
      HealthRepository(_WatchSaying(watchSaysToday), dao),
      _AlreadyAsked(),
    );
  });

  tearDown(() async {
    await bloc.close();
    await db.close();
  });

  Future<void> openTheApp() async {
    bloc.add(const LoadItemsEvent());
    await bloc.stream.firstWhere((state) => state is HomeLoadedState);
  }

  group('opening the app on a day nothing has been logged on', () {
    test('keeps the calories the watch recorded', () async {
      expect(await dao.getByDate(today()), isNull,
          reason: 'the day starts with no row at all — that is the setup');

      await openTheApp();

      final (kept, stamped) = await dao.getActiveCalories(keyFor(today()));
      expect(kept, watchSaysToday);
      expect(stamped, isNotNull,
          reason: 'a figure with no time on it cannot be shown as current');
    });

    test('gives the day the target it would have got from a first meal',
        () async {
      await openTheApp();

      final row = await dao.getByDate(today());
      expect(row, isNotNull);
      expect(row!.calorieGoal, theDaysTargetValue,
          reason: 'a day created with a placeholder target would keep it: '
              'every path that logs food sets the target only when the day '
              'has no row yet');
      expect(row.caloriesTracked, 0.0);
    });

    test('does not touch a day that already has a row', () async {
      await dao.upsert(DailyStatsCompanion.insert(
        date: keyFor(today()),
        calorieGoal: 1800,
      ));
      await dao.addTrackedValues(today(), kcal: 650);

      await openTheApp();

      final row = await dao.getByDate(today());
      expect(row!.calorieGoal, 1800, reason: 'the day already had its target');
      expect(row.caloriesTracked, 650.0, reason: 'and its food');
      final (kept, _) = await dao.getActiveCalories(keyFor(today()));
      expect(kept, watchSaysToday);
    });
  });
}

// ---------------------------------------------------------------------------
// The collaborators. Only what the Home screen actually asks for is answered;
// anything else throws rather than returning a quiet zero, so a test that
// passes for the wrong reason cannot.
// ---------------------------------------------------------------------------

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

class _AlreadyAsked implements ConfigRepository {
  @override
  Future<bool> getHasAskedHealthPermission() async => true;

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

class _Target implements GetKcalGoalUsecase {
  @override
  Future<double> getKcalGoal(
      {UserEntity? userEntity,
      double? totalKcalActivitiesParam,
      double? kcalUserAdjustment}) async {
    // The base allowance is asked for with the exercise taken out.
    return totalKcalActivitiesParam == 0 ? 1950.0 : theDaysTargetValue;
  }

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

class _WatchSaying implements HealthDataSource {
  final double _calories;

  _WatchSaying(this._calories);

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<double> getActiveCaloriesToday() async => _calories;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('unexpected ${invocation.memberName}');
}
