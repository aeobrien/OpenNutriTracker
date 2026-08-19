/// One number for the day, and it is the one he set.
///
/// Behaviour under test: the target the household holds for whoever owns this
/// phone is what the Home ring shows.
///
/// This is the first thing that went wrong when Aidan tested the app on 19
/// August. He opened Settings, set his daily calorie target to 2400, and Home
/// carried on showing the figure the app had worked out for itself during
/// setup. In his words: *"there are clearly two parts of the app conflicting
/// here."* Both numbers were real, both were stored, and nothing on the screen
/// said which one counted.
///
/// So these tests are written against the thing that draws the ring — the
/// use case every screen asks for the day's allowance — rather than against
/// the calculator underneath it. The calculator was never wrong. The fault was
/// that the ring never asked the household.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/data/repository/health_repository.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/data/repository/user_repository.dart';
import 'package:opennutritracker/core/domain/entity/app_theme_entity.dart';
import 'package:opennutritracker/core/domain/entity/config_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_entity.dart';
import 'package:opennutritracker/core/domain/usecase/get_kcal_goal_usecase.dart';
import 'package:opennutritracker/core/utils/calc/calorie_goal_calc.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';

import '../../fixture/user_entity_fixtures.dart';
import 'fake_household_server.dart';

class _FakeUserRepository extends Fake implements UserRepository {
  _FakeUserRepository(this.user);
  final UserEntity user;
  @override
  Future<UserEntity> getUserData() async => user;
}

class _FakeConfigRepository extends Fake implements ConfigRepository {
  @override
  Future<ConfigEntity> getConfig() async =>
      const ConfigEntity(true, true, false, AppThemeEntity.system,
          exerciseMultiplier: 0.75);
}

/// No activities typed in by hand.
class _FakeActivityRepository extends Fake implements UserActivityRepository {
  @override
  Future<List<UserActivityEntity>> getAllUserActivityByDate(DateTime day) async =>
      const [];
}

/// A watch that is not connected, so nothing is earned unless a test says so.
class _FakeHealthRepository extends Fake implements HealthRepository {
  _FakeHealthRepository({this.activeCalories});
  final double? activeCalories;
  @override
  Future<bool> hasPermission() async => activeCalories != null;
  @override
  Future<double> fetchAndCacheActiveCalories() async => activeCalories ?? 0;
}

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;

  final user = UserEntityFixtures.youngSedentaryMaleWantingToMaintainWeight;
  final calculated = CalorieGoalCalc.getTdee(user);

  GetKcalGoalUsecase usecaseWith({double? activeCalories}) => GetKcalGoalUsecase(
        _FakeUserRepository(user),
        _FakeConfigRepository(),
        _FakeActivityRepository(),
        _FakeHealthRepository(activeCalories: activeCalories),
        household,
      );

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(
      ConfigDao(db),
      HouseholdApi(baseUrl: 'http://mini', client: mini.client),
    );
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  group('the target he set is the target the ring shows', () {
    test('setting it in Settings moves the figure Home draws', () async {
      final before = await usecaseWith().getKcalGoal();
      expect(before, calculated,
          reason: 'with nothing set, the app\'s own calculation stands');

      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);

      final after = await usecaseWith().getKcalGoal();
      expect(after, 2400,
          reason: 'this is the number he typed and could not find on Home');
      expect(after, isNot(before));
    });

    test('changing it again moves it again', () async {
      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await household.updateSettings(mini.aidan, dailyTargetKcal: 2100);
      expect(await usecaseWith().getKcalGoal(), 2100);
    });

    test('it is this person\'s target, not the household\'s', () async {
      await household.updateSettings(mini.emily, dailyTargetKcal: 1800);
      expect(await usecaseWith().getKcalGoal(), calculated,
          reason: "Emily's target must not reach Aidan's phone");

      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      expect(await usecaseWith().getKcalGoal(), 2400);
    });
  });

  group('exercise still counts', () {
    test('a walk moves the ring on top of the target he set', () async {
      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      final withWalk = await usecaseWith(activeCalories: 500).getKcalGoal();
      expect(withWalk, 2400 + 375,
          reason: 'a typed target sets where the day starts, not whether '
              'a hard walk counts');
    });

    test('and it counts the same way it did before any target was set', () async {
      final earnedBefore = (await usecaseWith(activeCalories: 500).getKcalGoal()) -
          (await usecaseWith().getKcalGoal());
      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      final earnedAfter = (await usecaseWith(activeCalories: 500).getKcalGoal()) -
          (await usecaseWith().getKcalGoal());
      expect(earnedAfter, earnedBefore);
    });
  });

  group('when nobody has set one', () {
    test('the app\'s own calculation is still the suggestion', () async {
      expect(await usecaseWith().getKcalGoal(), calculated);
    });

    test('a target of zero is not a target', () async {
      await household.updateSettings(mini.aidan, dailyTargetKcal: 0);
      expect(await usecaseWith().getKcalGoal(), calculated,
          reason: 'nobody means to be allowed nothing; treat it as unset');
    });
  });

  group('when the Mini is unreachable', () {
    test('the ring still shows the target he set', () async {
      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      mini.reachable = false;
      expect(await usecaseWith().getKcalGoal(), 2400,
          reason: 'the main number on the main screen cannot depend on the '
              'house being awake');
    });
  });
}
