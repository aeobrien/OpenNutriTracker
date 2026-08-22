/// Fixing something that was logged wrong — on the phone, and in the house.
///
/// Behaviour under test — Release D. Three things a two-person ledger cannot do
/// without, and could not do until now:
///
///  * a figure already on a day can be corrected, and the correction reaches
///    the Mac Mini rather than only this phone;
///  * a row can be moved to the other person's day, in the same save as any
///    change to its amount;
///  * removing a row here removes it there, softly.
///
/// Underneath all three is the thing that makes any of them possible: a logged
/// food now has one name that both machines use. Before this the phone had no
/// way to say *which* row it meant — it minted an id for its own diary and the
/// household minted a different one — so a correction had nowhere to land.
///
/// The tests below drive the ledger directly, for the same reason the
/// add-a-food tests do: the screens cannot be stood up without the phone's
/// whole diary behind them, and the part that carries the promise is who ends
/// up with what.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/food_shares.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import '../household/fake_household_server.dart';

void main() {
  final day = DateTime(2026, 8, 19, 19, 30);

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late FoodLedger ledger;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    ledger = FoodLedger(HouseholdLogger(household, outbox), api());
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Future<void> log(String intakeId,
      {double mine = 40, List<FoodShare> alsoFor = const []}) async {
    await ledger.add(
      intakeId: intakeId,
      day: day,
      slot: 'snack',
      label: 'Oat biscuits',
      liquid: false,
      mine: mine,
      alsoFor: alsoFor,
      kcalPerUnit: 450 / 100,
    );
    await outbox.drain();
  }

  Map<String, dynamic> theRow(String clientId) => mini.entries[clientId]!;

  int amendsSent() =>
      mini.requests.where((r) => r.contains('/amend')).length;

  group('one name, on both machines', () {
    test('the row the house keeps is called what the phone calls it', () async {
      await log('intake-abc');
      expect(mini.entries.keys, contains('intake-abc'));
    });

    test("the other person's share is nameable too, and separately", () async {
      await log('intake-abc',
          alsoFor: [FoodShare(personId: mini.emily, quantity: 60)]);
      expect(mini.entries.keys,
          containsAll(['intake-abc', 'intake-abc-p${mini.emily}']));
    });

    test('the name can be worked out from the diary row alone', () {
      expect(FoodLedger.nameFor('intake-abc'), 'intake-abc');
      expect(FoodLedger.nameFor('intake-abc', forPerson: 2), 'intake-abc-p2');
    });
  });

  group('correcting a figure', () {
    test('the new amount reaches the house', () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc', quantity: 75, kcal: 337.5);
      await outbox.drain();

      expect(theRow('intake-abc')['qty'], 75);
      expect(theRow('intake-abc')['kcal'], 337.5);
    });

    test('and says who made it', () async {
      await log('intake-abc');
      await ledger.amend('intake-abc', kcal: 999);
      await outbox.drain();

      expect(theRow('intake-abc')['amended_by'], mini.aidan);
    });

    test('a figure not being corrected is left alone', () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc', kcal: 999);
      await outbox.drain();

      expect(theRow('intake-abc')['label'], 'Oat biscuits');
      expect(theRow('intake-abc')['qty'], 40);
    });

    test('a correction waits for a sleeping house rather than being lost',
        () async {
      await log('intake-abc');
      mini.reachable = false;
      await ledger.amend('intake-abc', kcal: 999);
      await outbox.drain();
      expect(theRow('intake-abc')['kcal'], isNot(999));

      mini.reachable = true;
      await outbox.drain();
      expect(theRow('intake-abc')['kcal'], 999);
    });

    test('the same correction sent twice is sent once', () async {
      await log('intake-abc');
      await ledger.amend('intake-abc', kcal: 999);
      await outbox.drain();
      await outbox.drain();

      expect(amendsSent(), 1);
    });
  });

  group('moving it to the other person', () {
    test('the row lands on their day', () async {
      await log('intake-abc');
      await ledger.amend('intake-abc', moveTo: mini.emily);
      await outbox.drain();

      expect(theRow('intake-abc')['owner_id'], mini.emily);
    });

    test('it moves with its corrected figure, in one message', () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc',
          moveTo: mini.emily, quantity: 75, kcal: 337.5);
      await outbox.drain();

      final row = theRow('intake-abc');
      expect(row['owner_id'], mini.emily);
      expect(row['kcal'], 337.5);
      expect(amendsSent(), 1,
          reason: 'two messages could half-land and leave both totals wrong '
              'with nothing to say so');
    });

    test('not moving it leaves whose day it is alone', () async {
      await log('intake-abc');
      await ledger.amend('intake-abc', kcal: 999);
      await outbox.drain();

      expect(theRow('intake-abc')['owner_id'], mini.aidan);
    });
  });

  group('taking it off the day', () {
    test('it stops counting at the house too', () async {
      await log('intake-abc');
      await ledger.retire('intake-abc');
      await outbox.drain();

      expect(theRow('intake-abc')['deleted_at'], isNotNull);
    });

    test('the row and its numbers are kept, not deleted', () async {
      await log('intake-abc', mine: 40);
      await ledger.retire('intake-abc');
      await outbox.drain();

      final row = theRow('intake-abc');
      expect(row['label'], 'Oat biscuits');
      expect(row['qty'], 40);
    });

    test('a removal waits for a sleeping house rather than being lost',
        () async {
      await log('intake-abc');
      mini.reachable = false;
      await ledger.retire('intake-abc');
      await outbox.drain();
      expect(theRow('intake-abc')['deleted_at'], isNull);

      mini.reachable = true;
      await outbox.drain();
      expect(theRow('intake-abc')['deleted_at'], isNotNull);
    });

    test("the other person's share is left where it is", () async {
      await log('intake-abc',
          alsoFor: [FoodShare(personId: mini.emily, quantity: 60)]);
      await ledger.retire('intake-abc');
      await outbox.drain();

      expect(theRow('intake-abc')['deleted_at'], isNotNull);
      expect(theRow('intake-abc-p${mini.emily}')['deleted_at'], isNull,
          reason: "it is on Emily's day and is hers to take off — this phone "
              'does not know from the diary row alone that it exists');
    });
  });

  group('a house that has never been set up', () {
    test('nothing is sent and nothing throws', () async {
      final fresh = AppDatabase.createInMemory();
      final unclaimed = HouseholdRepository(ConfigDao(fresh), api());
      final theirs =
          FoodLedger(HouseholdLogger(unclaimed, Outbox.of(fresh, api())), api());

      await theirs.retire('intake-abc');
      await theirs.amend('intake-abc', kcal: 1);

      // Not `isEmpty`: the shared setUp above already told the Mini whose
      // phone the *other* database belongs to. What matters is that this
      // unclaimed one asked for nothing on behalf of a row it cannot place.
      expect(
          mini.requests
              .where((r) => r.contains('/household/entry/by-client/')),
          isEmpty,
          reason: 'a phone that has never been claimed has no day to correct, '
              'so a correction must go nowhere rather than to the wrong person');
      await fresh.close();
    });
  });
}
