/// One owner, and only one place that decides it.
///
/// Behaviour under test (Release A, TM-0001 and TM-0031): the app used to hold
/// two separate answers to "whose phone is this". One was a name typed into a
/// settings field, and it decided whose meals were pulled down into the diary.
/// The other was the household owner, chosen from a list, and it decided what
/// the household screens showed. Nothing kept them equal, so a phone could be
/// Aidan's for one half of the app and Emily's for the other.
///
/// There is now one choice. The name is written *from* it and can no longer be
/// typed anywhere, so the two cannot disagree.
///
/// What is proved here, and why each is proved the way it is:
///
///  * choosing an owner writes the name too — watched through the writer the
///    app actually injects, not through a getter reading back a setter;
///  * changing the owner rewrites it — the drift is what the old code allowed,
///    so the second write is the point, not the first;
///  * the name is the household's own spelling, taken from the server rather
///    than assembled on the phone;
///  * the mirror never costs the decision: if the name cannot be written the
///    owner is still set, because the person has already answered and must not
///    be asked again;
///  * and there is nowhere else to set it — checked by reading the settings
///    screen's source, because a component test cannot see a field that is
///    still on a screen it does not mount.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;

  /// Every name the app was asked to write, oldest first.
  late List<String> namesWritten;

  HouseholdRepository buildRepository() => HouseholdRepository(
        ConfigDao(db),
        HouseholdApi(baseUrl: 'http://mini', client: mini.client),
        ownerNameWriter: (name) async => namesWritten.add(name),
      );

  setUp(() {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    namesWritten = [];
  });

  tearDown(() async => db.close());

  group('one choice, written everywhere it is needed', () {
    test('saying whose phone it is also writes the name the meal sync reads',
        () async {
      final repository = buildRepository();

      await repository.setOwner(mini.aidan);

      expect(await repository.storedOwner(), mini.aidan);
      expect(namesWritten, ['Aidan']);
    });

    test('handing the phone over rewrites it, so the two cannot drift apart',
        () async {
      final repository = buildRepository();

      await repository.setOwner(mini.aidan);
      await repository.setOwner(mini.emily);

      expect(await repository.storedOwner(), mini.emily);
      expect(namesWritten, ['Aidan', 'Emily']);
      // The old fault, stated as an assertion: the last name written belongs to
      // the person the phone now belongs to. Not to whoever typed last.
      expect(namesWritten.last, 'Emily');
    });

    test('the name is the household\'s own spelling, not the phone\'s guess',
        () async {
      mini.people
        ..clear()
        ..addAll([
          {'id': 1, 'name': 'Aidan'},
          {'id': 2, 'name': 'Em'},
        ]);
      final repository = buildRepository();

      await repository.setOwner(2);

      expect(namesWritten, ['Em']);
    });
  });

  group('the mirror never costs the decision', () {
    test('a repository without a name writer still sets the owner', () async {
      final repository = HouseholdRepository(
        ConfigDao(db),
        HouseholdApi(baseUrl: 'http://mini', client: mini.client),
      );

      await repository.setOwner(mini.emily);

      expect(await repository.storedOwner(), mini.emily);
    });

    test('a name the app cannot write does not undo the answer', () async {
      final repository = HouseholdRepository(
        ConfigDao(db),
        HouseholdApi(baseUrl: 'http://mini', client: mini.client),
        ownerNameWriter: (name) async => throw StateError('keychain locked'),
      );

      await repository.setOwner(mini.aidan);

      // The person answered. They are not asked again because a copy failed.
      expect(await repository.storedOwner(), mini.aidan);
      expect(await repository.needsOwnerPrompt(), isFalse);
    });

    test('a Mini that goes away mid-answer does not half-set the owner',
        () async {
      final repository = buildRepository();
      mini.reachable = false;

      await expectLater(
          repository.setOwner(mini.aidan), throwsA(isA<HouseholdUnreachable>()));

      // Nothing stored locally, so the app asks again rather than believing
      // something the server never heard.
      expect(await repository.storedOwner(), isNull);
      expect(namesWritten, isEmpty);
    });
  });

  group('there is one place to set it', () {
    test('the settings screen no longer has a field for the owner name', () {
      final source =
          File('lib/features/settings/settings_screen.dart').readAsStringSync();

      expect(source.contains('setMantelActor'), isFalse,
          reason: 'a second place to type the owner has come back');
      expect(source.contains('getMantelActor'), isFalse,
          reason: 'a second place to type the owner has come back');
      expect(source.contains('Mantel meal owner'), isFalse,
          reason: 'the old owner field has come back');
    });

    test('the owner name is written from the one choice, in the locator', () {
      final source =
          File('lib/core/utils/locator.dart').readAsStringSync();

      expect(source.contains('ownerNameWriter: secureAppStorageProvider.setMantelActor'),
          isTrue,
          reason: 'the household repository is built without the name writer, '
              'so choosing an owner would silently stop updating the name');
    });

    test('the repository is the only thing that writes the owner name', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('mantel_secure_storage.dart')) continue;
        if (entity.path.endsWith('locator.dart')) continue;
        if (entity.readAsStringSync().contains('setMantelActor')) {
          offenders.add(entity.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'something other than the one owner choice is writing the '
              'owner name: $offenders');
    });
  });
}
