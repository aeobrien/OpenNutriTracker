/// Exercise arrives two ways, and the day knows which.
///
/// Behaviour under test (Release 1, promise 4): exercise reaches the day from
/// each person's own Watch, and can also be typed in when it did not.
///
/// Both routes are run against a stand-in Watch — one where it has a figure and
/// one where it has nothing — because the second case is the whole reason the
/// typed route exists and cannot be arranged on a real HealthKit.
///
/// The test that carries the sharper half of the promise is [it goes on the
/// owner's day, not the last person the server heard from]. Emily's phone talks
/// to the server, then Aidan types his swim in on his own phone. If the figure
/// were attributed by asking the server who it last dealt with — an easy thing
/// to build and impossible to notice with one phone — Aidan's swim would land on
/// Emily's day and every other test here would still pass.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import '../household/fake_household_server.dart';

/// A Watch that reports whatever the test says it reported, including nothing.
class FakeWatch implements ActiveCaloriesSource {
  /// Day → active calories. A day that is absent is a day the Watch has nothing
  /// for, which is the case the typed route exists to cover.
  final Map<String, double> byDay = {};

  final List<String> asked = [];

  @override
  Future<double?> activeCaloriesFor(String day) async {
    asked.add(day);
    return byDay[day];
  }
}

void main() {
  const today = '2026-08-19';

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository repository;
  late Outbox outbox;
  late HouseholdLogger logger;
  late FakeWatch watch;
  late ExerciseSync sync;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    repository = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    logger = HouseholdLogger(repository, outbox);
    watch = FakeWatch();
    sync = ExerciseSync(repository, logger, watch);
    await repository.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  List<Map<String, dynamic>> exerciseOn(int personId) => mini.exercise.values
      .where((e) => e['owner_id'] == personId)
      .toList(growable: false);

  group('from the Watch', () {
    test('a figure the Watch has reaches the day', () async {
      watch.byDay[today] = 412;

      await sync.syncFromHealth(day: today);
      await outbox.drain();

      final logged = exerciseOn(mini.aidan).single;
      expect(logged['kcal'], 412);
      expect(logged['day'], today);
      expect(logged['source'], 'health',
          reason: 'the day has to be able to say the Watch measured this');
    });

    test('it belongs to the person whose phone it is', () async {
      watch.byDay[today] = 412;

      await sync.syncFromHealth(day: today);
      await outbox.drain();

      final logged = exerciseOn(mini.aidan).single;
      expect(logged['owner_id'], mini.aidan);
      expect(logged['author_id'], mini.aidan);
      expect(exerciseOn(mini.emily), isEmpty);
    });

    test('syncing the same day again does not double it up', () async {
      watch.byDay[today] = 412;

      await sync.syncFromHealth(day: today);
      await outbox.drain();
      await sync.syncFromHealth(day: today);
      await outbox.drain();

      expect(exerciseOn(mini.aidan), hasLength(1));
    });

    test('each person\'s Watch goes on their own day', () async {
      watch.byDay[today] = 412;
      await sync.syncFromHealth(day: today);

      await repository.setOwner(mini.emily);
      watch.byDay[today] = 260;
      await sync.syncFromHealth(day: today);
      await outbox.drain();

      expect(exerciseOn(mini.aidan).single['kcal'], 412);
      expect(exerciseOn(mini.emily).single['kcal'], 260);
    });
  });

  group('when the Watch has nothing', () {
    test('nothing is invented', () async {
      // No entry for today in the fake Watch: no permission, no watch worn, no
      // samples — the app must not put a figure on the day regardless.
      final result = await sync.syncFromHealth(day: today);
      await outbox.drain();

      expect(result, isNull);
      expect(watch.asked, [today], reason: 'it was asked, and had nothing');
      expect(mini.exercise, isEmpty);
      expect(await outbox.pendingCount(), 0);
    });

    test('the figure can be typed in instead', () async {
      await sync.syncFromHealth(day: today);
      await sync.typeIn(day: today, kcal: 350, minutes: 45, note: 'Swim');
      await outbox.drain();

      final logged = exerciseOn(mini.aidan).single;
      expect(logged['kcal'], 350);
      expect(logged['minutes'], 45);
      expect(logged['note'], 'Swim');
      expect(logged['source'], 'typed',
          reason: 'a figure somebody typed is a different claim from a '
              'measured one, and the day has to keep them apart');
    });

    test('it goes on the owner\'s day, not the last person the server heard '
        'from', () async {
      // Emily's phone is the server's most recent caller.
      final emilysStore = AppDatabase.createInMemory();
      addTearDown(() async => emilysStore.close());
      final emilysApi =
          HouseholdApi(baseUrl: 'http://mini', client: mini.client);
      final emilys = HouseholdRepository(ConfigDao(emilysStore), emilysApi);
      final emilysOutbox = Outbox.of(emilysStore, emilysApi);
      await emilys.setOwner(mini.emily);
      await HouseholdLogger(emilys, emilysOutbox)
          .logExercise(day: today, source: 'typed', kcal: 500);
      await emilysOutbox.drain();

      // Aidan now types his own in, on his own phone.
      await sync.typeIn(day: today, kcal: 350, note: 'Swim');
      await outbox.drain();

      expect(exerciseOn(mini.aidan).single['kcal'], 350);
      expect(exerciseOn(mini.aidan).single['note'], 'Swim');
      expect(exerciseOn(mini.emily).single['kcal'], 500);
    });

    test('a typed figure is held and sent when the Mini is unreachable',
        () async {
      mini.reachable = false;
      await sync.typeIn(day: today, kcal: 350);
      expect(await outbox.pendingCount(), 1);

      mini.reachable = true;
      await outbox.drain();

      expect(exerciseOn(mini.aidan).single['kcal'], 350);
    });
  });

  group('both on the same day', () {
    test('the Watch\'s figure and a typed one sit side by side, each saying '
        'where it came from', () async {
      watch.byDay[today] = 412;
      await sync.syncFromHealth(day: today);
      await sync.typeIn(day: today, kcal: 350, note: 'Swim');
      await outbox.drain();

      final mine = exerciseOn(mini.aidan);
      expect(mine, hasLength(2));
      expect(mine.map((e) => e['source']).toSet(), {'health', 'typed'});
      expect(mine.fold<num>(0, (sum, e) => sum + (e['kcal'] as num)), 762);
    });

    test('typing one in does not disturb the Watch\'s', () async {
      watch.byDay[today] = 412;
      await sync.syncFromHealth(day: today);
      await sync.typeIn(day: today, kcal: 350);
      await outbox.drain();

      final fromWatch =
          exerciseOn(mini.aidan).where((e) => e['source'] == 'health').single;
      expect(fromWatch['kcal'], 412);
    });
  });
}
