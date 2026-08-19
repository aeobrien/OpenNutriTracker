/// Two people, two targets.
///
/// Behaviour under test (Release 1, promise 3): each person sets their own daily
/// calorie target, and one person changing theirs never moves the other's.
///
/// Every test here has **both people present**, because the failure this promise
/// guards against is invisible with only one. A single shared target stored
/// under a household key would pass "set it and read it back" perfectly; it only
/// gives itself away when the second person sets theirs and the first person's
/// changes underneath them. So the shape of every test below is: set one, set
/// the other, then check the *first* one again.
///
/// The two-phone group goes further and gives each person their own handset with
/// its own local store, which is the arrangement in the house. If targets were
/// being kept on the phone rather than against the person, Emily's phone would
/// show nothing after Aidan set his — and would happily overwrite him.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/presentation/household_settings_section.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository repository;

  HouseholdRepository repositoryOn(AppDatabase store) => HouseholdRepository(
        ConfigDao(store),
        HouseholdApi(baseUrl: 'http://mini', client: mini.client),
      );

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    repository = repositoryOn(db);
    await repository.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Widget settings() => MaterialApp(
        home: Scaffold(body: HouseholdSettingsSection(repository: repository)),
      );

  group('each person has their own target', () {
    test('one phone, both people, set one after the other', () async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await repository.updateSettings(mini.emily, dailyTargetKcal: 1800);

      // The second setting must not have moved the first.
      expect((await repository.settings(mini.aidan)).dailyTargetKcal, 2400);
      expect((await repository.settings(mini.emily)).dailyTargetKcal, 1800);
    });

    test('changing one again leaves the other exactly where it was', () async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await repository.updateSettings(mini.emily, dailyTargetKcal: 1800);

      await repository.updateSettings(mini.emily, dailyTargetKcal: 1650);

      expect((await repository.settings(mini.aidan)).dailyTargetKcal, 2400,
          reason: "Emily's change must not reach Aidan's target");
      expect((await repository.settings(mini.emily)).dailyTargetKcal, 1650);
    });

    test('the two are kept apart on the server, not merely locally', () async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await repository.updateSettings(mini.emily, dailyTargetKcal: 1800);

      expect(mini.settingsFor(mini.aidan)['daily_target_kcal'], 2400);
      expect(mini.settingsFor(mini.emily)['daily_target_kcal'], 1800);
    });

    test('one person having no target does not hand them the other\'s',
        () async {
      // No shared fallback: an unset target reads as unset, never as the
      // household's or the other person's.
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);

      expect((await repository.settings(mini.emily)).dailyTargetKcal, isNull);
    });

    test('the target survives a restart, still against the right person',
        () async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await repository.updateSettings(mini.emily, dailyTargetKcal: 1800);

      final afterRestart = repositoryOn(db);

      expect((await afterRestart.settings(mini.aidan)).dailyTargetKcal, 2400);
      expect((await afterRestart.settings(mini.emily)).dailyTargetKcal, 1800);
    });
  });

  group('two phones, one each', () {
    late AppDatabase emilysStore;
    late HouseholdRepository emilys;

    setUp(() async {
      emilysStore = AppDatabase.createInMemory();
      emilys = repositoryOn(emilysStore);
      await emilys.setOwner(mini.emily);
    });

    tearDown(() async => emilysStore.close());

    test('each phone sets its own person\'s target', () async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await emilys.updateSettings(mini.emily, dailyTargetKcal: 1800);

      expect((await repository.settings(mini.aidan)).dailyTargetKcal, 2400);
      expect((await emilys.settings(mini.emily)).dailyTargetKcal, 1800);
    });

    test('a change on one phone does not move the target on the other',
        () async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await emilys.updateSettings(mini.emily, dailyTargetKcal: 1800);

      await emilys.updateSettings(mini.emily, dailyTargetKcal: 1500);

      expect((await repository.settings(mini.aidan)).dailyTargetKcal, 2400);
    });

    test('each phone can read the other person\'s target without owning it',
        () async {
      // Reading is fine — the ledgers are separate, not secret. What matters is
      // that reading Emily's from Aidan's phone does not adopt it.
      await emilys.updateSettings(mini.emily, dailyTargetKcal: 1800);
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);

      expect((await repository.settings(mini.emily)).dailyTargetKcal, 1800);
      expect((await repository.settings(mini.aidan)).dailyTargetKcal, 2400);
    });
  });

  group('on the settings screen', () {
    testWidgets('shows the holder\'s own target while the other has a different'
        ' one', (tester) async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await repository.updateSettings(mini.emily, dailyTargetKcal: 1800);

      await tester.pumpWidget(settings());
      await tester.pumpAndSettle();

      expect(find.text('2400 kcal'), findsOneWidget);
      expect(find.text('1800 kcal'), findsNothing);
    });

    testWidgets('setting it here does not move the other person\'s',
        (tester) async {
      await repository.updateSettings(mini.emily, dailyTargetKcal: 1800);

      await tester.pumpWidget(settings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Daily calorie target'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '2200');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('2200 kcal'), findsOneWidget);
      expect((await repository.settings(mini.emily)).dailyTargetKcal, 1800);
    });

    testWidgets('says so plainly when nobody has set one yet', (tester) async {
      await repository.updateSettings(mini.emily, dailyTargetKcal: 1800);

      await tester.pumpWidget(settings());
      await tester.pumpAndSettle();

      // Aidan holds this phone and has not set a target; Emily's must not be
      // shown in its place.
      expect(find.text('Not set'), findsOneWidget);
      expect(find.text('1800 kcal'), findsNothing);
    });
  });
}
