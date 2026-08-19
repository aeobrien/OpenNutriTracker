/// Exercise has one way in, and it is the app's own.
///
/// On 19 August Aidan looked for his exercise and wrote: *"Can't see an
/// 'exercise' section at all on this page, just an activity one, which doesn't
/// mention my watch (and I've burned 500+ calories today so it's not because I
/// haven't exercised). There's no button saying 'add exercise the watch
/// missed'."*
///
/// He was on the app's own screen. The button he was told to look for was on a
/// second screen this project had added, and the two kept separate records of
/// the same walk. The second screen is deleted. What is tested here is that the
/// app's own route — the one he was already using — reaches the household.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/repository/user_activity_repository.dart';
import 'package:opennutritracker/core/domain/entity/physical_activity_entity.dart';
import 'package:opennutritracker/core/domain/entity/user_activity_entity.dart';
import 'package:opennutritracker/core/domain/usecase/add_user_activity_usercase.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import '../household/fake_household_server.dart';

/// The app's own store, which already worked and is not what is under test.
class _FakeActivityStore extends Fake implements UserActivityRepository {
  final saved = <UserActivityEntity>[];
  bool refuse = false;

  @override
  Future<void> addUserActivity(UserActivityEntity activity) async {
    if (refuse) throw StateError('the local store is full');
    saved.add(activity);
  }
}

/// A watch that has whatever the test says it has.
class _FakeWatch implements ActiveCaloriesSource {
  final Map<String, double> byDay = {};
  @override
  Future<double?> activeCaloriesFor(String day) async => byDay[day];
}

void main() {
  final theDay = DateTime(2026, 8, 19, 18, 30);
  final today = ExerciseSync.dayKey(theDay);

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late Outbox outbox;
  late ExerciseSync sync;
  late _FakeWatch watch;
  late _FakeActivityStore store;
  late AddUserActivityUsecase addActivity;

  UserActivityEntity walk({String id = 'a1', double kcal = 520}) =>
      UserActivityEntity(
        id,
        45,
        kcal,
        theDay,
        const PhysicalActivityEntity(
            '17190', 'walking, brisk pace', 'a brisk walk', 5, [],
            PhysicalActivityTypeEntity.sport),
      );

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    final household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    watch = _FakeWatch();
    sync = ExerciseSync(household, HouseholdLogger(household, outbox), watch);
    store = _FakeActivityStore();
    addActivity = AddUserActivityUsecase(store, sync);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  List<Map<String, dynamic>> householdExercise() =>
      mini.exercise.values.where((e) => e['day'] == today).toList();

  group("the app's own activity screen reaches the household", () {
    test('an activity added there lands on the household day', () async {
      await addActivity.addUserActivity(walk());
      await outbox.drain();

      expect(store.saved, hasLength(1), reason: 'the app still keeps its own');
      expect(householdExercise(), hasLength(1),
          reason: 'and the household now knows about the same walk');
      expect(householdExercise().single['kcal'], 520);
    });

    test('it says it was typed in, not measured', () async {
      await addActivity.addUserActivity(walk());
      await outbox.drain();
      expect(householdExercise().single['source'], 'typed',
          reason: 'a figure a person entered and a figure a watch measured '
              'are not the same claim');
    });

    test('it carries what the activity was', () async {
      await addActivity.addUserActivity(walk());
      await outbox.drain();
      expect(householdExercise().single['note'], 'walking, brisk pace');
      expect(householdExercise().single['minutes'], 45);
    });

    test('sending it twice is still one walk', () async {
      await addActivity.addUserActivity(walk());
      await outbox.drain();
      await outbox.drain();
      expect(householdExercise(), hasLength(1));
    });

    test('two different activities are two walks', () async {
      await addActivity.addUserActivity(walk(id: 'a1', kcal: 520));
      await addActivity.addUserActivity(walk(id: 'a2', kcal: 300));
      await outbox.drain();
      expect(householdExercise(), hasLength(2));
    });
  });

  group('the household half cannot cost him the activity', () {
    test('a sleeping Mini does not lose the walk', () async {
      mini.reachable = false;
      await addActivity.addUserActivity(walk());

      expect(store.saved, hasLength(1),
          reason: 'the app kept it, which is what he sees');

      mini.reachable = true;
      await outbox.drain();
      expect(householdExercise(), hasLength(1),
          reason: 'and the queue delivered it when the house woke up');
    });

    test('a local store that refuses still fails loudly', () async {
      store.refuse = true;
      await expectLater(addActivity.addUserActivity(walk()), throwsStateError,
          reason: 'the household write is the forgiving half, not the app\'s '
              'own');
      expect(householdExercise(), isEmpty);
    });
  });

  group('the watch', () {
    test('its figure reaches the household without anyone opening a screen',
        () async {
      watch.byDay[today] = 500;
      await sync.syncFromHealth(day: today);
      await outbox.drain();

      expect(householdExercise().single['source'], 'health');
      expect(householdExercise().single['kcal'], 500);
    });

    test('opening the app again does not double the day', () async {
      watch.byDay[today] = 500;
      await sync.syncFromHealth(day: today);
      await sync.syncFromHealth(day: today);
      await outbox.drain();
      expect(householdExercise(), hasLength(1));
    });

    test('a watch with nothing to say puts nothing on the day', () async {
      await sync.syncFromHealth(day: today);
      await outbox.drain();
      expect(householdExercise(), isEmpty);
    });
  });
}
