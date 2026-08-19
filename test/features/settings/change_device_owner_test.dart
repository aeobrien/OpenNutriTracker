/// Handing the phone to the other person.
///
/// Behaviour under test (Release 1, promise 2): the person a phone belongs to
/// can be changed afterwards, and both the phone and the server agree on the
/// new answer without anything being logged to the wrong person in between.
///
/// The test that carries the item is [work already queued keeps the person it
/// was logged for]. Aidan logs a meal while the Mac Mini is unreachable; the
/// phone changes hands to Emily before the queue empties; the meal must still
/// be Aidan's. If the app worked out whose it was at the moment of sending
/// rather than the moment of logging, everything else here would still pass and
/// that one test would fail — which is exactly why it is written.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/presentation/household_settings_section.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository repository;
  late Outbox outbox;
  late HouseholdLogger logger;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    repository = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    logger = HouseholdLogger(repository, outbox);
    await repository.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Widget settings() => MaterialApp(
        home: Scaffold(
          body: HouseholdSettingsSection(repository: repository),
        ),
      );

  group('changing who the phone belongs to', () {
    testWidgets('shows who it belongs to now', (tester) async {
      await tester.pumpWidget(settings());
      await tester.pumpAndSettle();

      expect(find.text('This phone belongs to'), findsOneWidget);
      expect(find.text('Aidan'), findsOneWidget);
    });

    testWidgets('lets it be changed to the other person', (tester) async {
      await tester.pumpWidget(settings());
      await tester.pumpAndSettle();

      await tester.tap(find.text('This phone belongs to'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emily').last);
      await tester.pumpAndSettle();

      expect(find.text('Emily'), findsOneWidget);
      expect(await repository.storedOwner(), mini.emily);
    });

    test('the phone and the server agree afterwards', () async {
      await repository.setOwner(mini.emily);

      expect(await repository.storedOwner(), mini.emily);
      expect(await repository.ownerAccordingToServer(), mini.emily);
      expect(await repository.ownerAgrees(), isTrue);
    });

    test('the change does not go through if the server cannot be told',
        () async {
      mini.reachable = false;

      await expectLater(
          repository.setOwner(mini.emily), throwsA(isA<HouseholdUnreachable>()));

      // Still Aidan's, on both sides — no half-changed state.
      expect(await repository.storedOwner(), mini.aidan);
      mini.reachable = true;
      expect(await repository.ownerAccordingToServer(), mini.aidan);
    });

    testWidgets('and the person is told it did not go through',
        (tester) async {
      await tester.pumpWidget(settings());
      await tester.pumpAndSettle();
      mini.reachable = false;

      await tester.tap(find.text('This phone belongs to'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emily').last);
      await tester.pumpAndSettle();

      expect(find.textContaining('still belongs to Aidan'), findsOneWidget);
    });
  });

  group('work already queued', () {
    test('keeps the person it was logged for', () async {
      // Aidan logs his dinner with no way to reach the Mini.
      mini.reachable = false;
      await logger.logFood(
          day: '2026-08-19', label: 'Risotto', kcal: 610);
      expect(await outbox.pendingCount(), 1);

      // The phone changes hands before it has been sent.
      mini.reachable = true;
      await repository.setOwner(mini.emily);
      await outbox.drain();

      final stored = mini.entries.values.single;
      expect(stored['label'], 'Risotto');
      expect(stored['owner_id'], mini.aidan,
          reason: 'the dinner was Aidan\'s when it was logged');
      expect(stored['author_id'], mini.aidan);
    });

    test('several queued items all keep their own person', () async {
      mini.reachable = false;
      await logger.logFood(day: '2026-08-19', label: 'Breakfast', kcal: 320);
      await logger.logFood(day: '2026-08-19', label: 'Lunch', kcal: 540);

      mini.reachable = true;
      await repository.setOwner(mini.emily);
      // Emily logs hers after taking the phone.
      await logger.logFood(day: '2026-08-19', label: 'Dinner', kcal: 610);
      await outbox.drain();

      final byLabel = {
        for (final e in mini.entries.values) e['label']: e['owner_id']
      };
      expect(byLabel['Breakfast'], mini.aidan);
      expect(byLabel['Lunch'], mini.aidan);
      expect(byLabel['Dinner'], mini.emily);
    });

    test('the change of hands does not touch what is already in the queue',
        () async {
      mini.reachable = false;
      final id = await logger.logFood(
          day: '2026-08-19', label: 'Risotto', kcal: 610);
      final before = (await outbox.pending()).single;

      mini.reachable = true;
      await repository.setOwner(mini.emily);
      final after = (await outbox.pending()).single;

      expect(after.clientId, id);
      expect(after.ownerId, before.ownerId);
      expect(after.authorId, before.authorId);
      expect(after.loggedAt, before.loggedAt);
    });
  });

  group('after the change', () {
    test('new work goes to the new person', () async {
      await repository.setOwner(mini.emily);
      await logger.logFood(day: '2026-08-19', label: 'Toast', kcal: 180);
      await outbox.drain();

      expect(mini.entries.values.single['owner_id'], mini.emily);
    });

    test('the new person gets their own settings, not the old one\'s',
        () async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await repository.setOwner(mini.emily);

      final emilys = await repository.settings(mini.emily);
      expect(emilys.dailyTargetKcal, isNull);
      final aidans = await repository.settings(mini.aidan);
      expect(aidans.dailyTargetKcal, 2400);
    });

    testWidgets('the settings screen shows the new person\'s own target',
        (tester) async {
      await repository.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await repository.updateSettings(mini.emily, dailyTargetKcal: 1800);
      await tester.pumpWidget(settings());
      await tester.pumpAndSettle();

      expect(find.text('2400 kcal'), findsOneWidget);

      await tester.tap(find.text('This phone belongs to'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emily').last);
      await tester.pumpAndSettle();

      expect(find.text('1800 kcal'), findsOneWidget);
      expect(find.text('2400 kcal'), findsNothing);
    });
  });
}
