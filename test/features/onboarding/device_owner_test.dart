/// "Whose phone is this?", asked once and remembered.
///
/// Behaviour under test (Release 1, promise 1): on first run each phone asks
/// which of the two people it belongs to, remembers the answer across a
/// restart, and the household server independently knows which phone belongs to
/// whom.
///
/// The three things being proved are deliberately proved three different ways,
/// because a test that only checked a getter returns what a setter stored would
/// pass without any of them being true:
///
///  * a fresh install *actually prompts* — the screen is rendered and the two
///    names are on it;
///  * the answer survives a restart — the repository is thrown away and rebuilt
///    over the same stored data, which is what reopening the app leaves behind;
///  * the server knows independently — it is asked, and its answer comes from
///    what it recorded earlier rather than from anything the phone sends along
///    with the question.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/presentation/whose_phone_page.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository repository;

  HouseholdRepository buildRepository() => HouseholdRepository(
        ConfigDao(db),
        HouseholdApi(baseUrl: 'http://mini', client: mini.client),
      );

  setUp(() {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    repository = buildRepository();
  });

  tearDown(() async => db.close());

  Widget gate(HouseholdRepository repo) => MaterialApp(
        home: HouseholdGate(
          repository: repo,
          child: const Scaffold(body: Text('the app')),
        ),
      );

  group('a fresh install', () {
    test('has nobody stored', () async {
      expect(await repository.storedOwner(), isNull);
      expect(await repository.needsOwnerPrompt(), isTrue);
    });

    testWidgets('asks who the phone belongs to', (tester) async {
      await tester.pumpWidget(gate(repository));
      await tester.pumpAndSettle();

      expect(find.text('Whose phone is this?'), findsOneWidget);
      expect(find.text('Aidan'), findsOneWidget);
      expect(find.text('Emily'), findsOneWidget);
      expect(find.text('the app'), findsNothing);
    });

    testWidgets('offers both people, taken from the household itself',
        (tester) async {
      // Not hard-coded in the app: the names come from the server, so a
      // household with different people would show different names.
      mini.people
        ..clear()
        ..addAll([
          {'id': 7, 'name': 'Someone Else'},
          {'id': 8, 'name': 'Another'},
        ]);
      await tester.pumpWidget(gate(repository));
      await tester.pumpAndSettle();

      expect(find.text('Someone Else'), findsOneWidget);
      expect(find.text('Another'), findsOneWidget);
    });

    testWidgets('lets the app through once an answer is given', (tester) async {
      await tester.pumpWidget(gate(repository));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emily'));
      await tester.pumpAndSettle();

      expect(find.text('the app'), findsOneWidget);
      expect(find.text('Whose phone is this?'), findsNothing);
    });
  });

  group('the answer is remembered', () {
    testWidgets('a second run does not ask again', (tester) async {
      await tester.pumpWidget(gate(repository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Emily'));
      await tester.pumpAndSettle();

      // The app is closed and opened: a new repository over the same stored
      // data, exactly as a restart leaves things.
      final afterRestart = buildRepository();
      await tester.pumpWidget(gate(afterRestart));
      await tester.pumpAndSettle();

      expect(find.text('Whose phone is this?'), findsNothing);
      expect(find.text('the app'), findsOneWidget);
    });

    test('the stored answer survives a restart', () async {
      await repository.setOwner(mini.emily);

      final afterRestart = buildRepository();

      expect(await afterRestart.storedOwner(), mini.emily);
      expect(await afterRestart.needsOwnerPrompt(), isFalse);
    });

    test('the phone keeps the same identity across a restart', () async {
      // If the phone minted a new id each launch the server would see an
      // endless parade of unknown handsets.
      final first = await repository.deviceId();
      final afterRestart = buildRepository();

      expect(await afterRestart.deviceId(), first);
    });
  });

  group('the server knows too', () {
    test('it is told, and can answer from its own records', () async {
      await repository.setOwner(mini.emily);
      final deviceId = await repository.deviceId();

      // Asked directly of the server's own store, with nothing supplied by the
      // phone beyond which handset is being asked about.
      expect(mini.deviceOwners[deviceId], mini.emily);
      expect(await repository.ownerAccordingToServer(), mini.emily);
    });

    test('the phone and the server agree', () async {
      await repository.setOwner(mini.aidan);
      expect(await repository.ownerAgrees(), isTrue);
    });

    test('the server is asked, not told, when the owner is looked up',
        () async {
      await repository.setOwner(mini.aidan);
      mini.requests.clear();

      await repository.ownerAccordingToServer();

      // A GET carries no person id. If the app were sending its own answer
      // along with the question, the server could never contradict it.
      expect(mini.requests.single, startsWith('GET /household/device/'));
    });

    test('nothing is stored locally if the server cannot be told', () async {
      // The dangerous middle state: the phone believing one thing while the
      // server believes another. Better to have asked and failed.
      mini.reachable = false;

      await expectLater(
          repository.setOwner(mini.emily), throwsA(isA<HouseholdUnreachable>()));

      expect(await repository.storedOwner(), isNull);
      expect(await repository.needsOwnerPrompt(), isTrue);
    });

    testWidgets('and the person is told so, plainly', (tester) async {
      mini.reachable = false;
      await tester.pumpWidget(gate(repository));
      await tester.pumpAndSettle();

      expect(find.textContaining("Can't reach the kitchen computer"),
          findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}
