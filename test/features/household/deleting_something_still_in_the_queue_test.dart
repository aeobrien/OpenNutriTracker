/// Deleting something the phone has not managed to send yet.
///
/// Behaviour under test — Release 7, TM-0024 / BC-0025: "deleting an entry that
/// is still queued removes it from the queue as well, so nothing is sent
/// afterwards for something already deleted".
///
/// Before this, logging something with no signal and then deleting it queued a
/// removal behind a creation. Both then went out, in order, and the phone spent
/// the trip home telling the Mac Mini about a row and then telling it to forget
/// the row. It recovered — the house answers a not-yet-arrived row with a plain
/// 404 and the phone keeps the correction — but it is a round trip spent on a
/// row nobody wants, and every step of it is a step that can fail.
///
/// The hazard the other half of this file is about: cancelling the creation
/// means the house never hears of the row at all, so undoing the delete cannot
/// ask the house to put it back. Undo has to put the *creation* back on the
/// queue instead. Without that, Undo would look completely correct on the phone
/// while the house refused it eight times over the following hour — which is
/// the exact shape of the 21 August fault this app already has one scar from.
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

import 'fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late Outbox outbox;
  late FoodLedger ledger;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    final household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    ledger = FoodLedger(HouseholdLogger(household, outbox), api);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Future<void> ate(String intakeId, {String label = 'Oat biscuits'}) =>
      ledger.add(
        intakeId: intakeId,
        day: DateTime(2026, 8, 22),
        slot: 'snack',
        label: label,
        liquid: false,
        mine: 40,
        kcalPerUnit: 4.5,
      );

  List<String> whatWentOut() => mini.requests;

  group('with no signal', () {
    test('deleting it takes the creation off the queue', () async {
      await ate('intake-abc');
      expect(await outbox.pendingCount(), 1);

      await ledger.retire('intake-abc');

      // Not one waiting to be created and one waiting to be removed. Nothing.
      expect(await outbox.pendingCount(), 0);
    });

    test('and the house is never told about it at all', () async {
      await ate('intake-abc');
      await ledger.retire('intake-abc');
      await outbox.drain();

      expect(whatWentOut().where((r) => r.contains('/household/entry')), isEmpty);
      expect(mini.entries.keys, isEmpty);
    });

    test('anything else waiting is left where it is', () async {
      await ate('intake-abc');
      await ate('intake-def');
      await ledger.retire('intake-abc');

      expect(await outbox.pendingCount(), 1);
      await outbox.drain();
      expect(mini.entries.keys, ['intake-def']);
    });

    test("the other person's share is not cancelled with it", () async {
      // It is on their day and it is theirs. FoodLedger.retire says so; this
      // is the queue agreeing.
      await ledger.add(
        intakeId: 'intake-abc',
        day: DateTime(2026, 8, 22),
        slot: 'snack',
        label: 'Oat biscuits',
        liquid: false,
        mine: 40,
        alsoFor: [FoodShare(personId: mini.emily, quantity: 60)],
        kcalPerUnit: 4.5,
      );
      await ledger.retire('intake-abc');
      await outbox.drain();

      expect(mini.entries.keys, ['intake-abc-p${mini.emily}']);
    });
  });

  group('undoing that delete', () {
    test('puts the creation back on the queue', () async {
      await ate('intake-abc');
      await ledger.retire('intake-abc');
      expect(await outbox.pendingCount(), 0);

      await ledger.putBack('intake-abc');

      // What is on it, not how many. A count of one cannot tell the creation
      // coming back from an undo queued for a row the house never had, and
      // those are the two things this is choosing between.
      final waiting = await outbox.pending();
      expect(waiting.map((i) => i.path), ['/household/entry']);
      expect(waiting.single.clientId, 'intake-abc');
    });

    test('so the row reaches the house once, as itself', () async {
      await ate('intake-abc');
      await ledger.retire('intake-abc');
      await ledger.putBack('intake-abc');
      await outbox.drain();

      // Created, and not created-then-removed-then-put-back. One row, counting.
      expect(mini.entries.keys, ['intake-abc']);
      expect(mini.entries['intake-abc']!['deleted_at'], isNull);
      expect(whatWentOut().where((r) => r.contains('/retire')), isEmpty);
      expect(whatWentOut().where((r) => r.contains('/unretire')), isEmpty);
    });

    test('with what it was, not something rebuilt', () async {
      await ate('intake-abc', label: 'Oat biscuits');
      await ledger.retire('intake-abc');
      await ledger.putBack('intake-abc');
      await outbox.drain();

      expect(mini.entries['intake-abc']!['label'], 'Oat biscuits');
      expect(mini.entries['intake-abc']!['qty'], 40);
    });

    test('and only once, however many times it is asked for', () async {
      await ate('intake-abc');
      await ledger.retire('intake-abc');
      await ledger.putBack('intake-abc');
      await ledger.putBack('intake-abc');

      expect(await outbox.pendingCount(), 1);
    });
  });

  group('once it has actually been sent', () {
    test('deleting it queues a removal, as it always did', () async {
      await ate('intake-abc');
      await outbox.drain();
      expect(mini.entries.keys, ['intake-abc']);

      await ledger.retire('intake-abc');
      await outbox.drain();

      // The house has it, so the house has to be told. Nothing to cancel.
      expect(whatWentOut().where((r) => r.contains('/retire')), hasLength(1));
      expect(mini.entries['intake-abc']!['deleted_at'], isNotNull);
    });

    test('and undoing it asks the house to put it back', () async {
      await ate('intake-abc');
      await outbox.drain();
      await ledger.retire('intake-abc');
      await outbox.drain();
      await ledger.putBack('intake-abc');
      await outbox.drain();

      expect(whatWentOut().where((r) => r.contains('/unretire')), hasLength(1));
      expect(mini.entries['intake-abc']!['deleted_at'], isNull);
    });
  });

  group('while it is actually being sent', () {
    test('the delete does not take it out from under the drain', () async {
      // Written on 22 August after a deliberate break proved nothing: removing
      // the guard that refuses to cancel during a drain left every test green.
      // It is the worst case of the lot. The drain posts the row and then takes
      // it off the queue; cancelling in between lets the house keep a row while
      // the phone throws away the only thing that could ever have removed it —
      // a dinner standing on somebody's day that neither machine says is wrong.
      await ate('intake-abc');

      mini.holdEntries = true;
      final draining = outbox.drain();
      // Let the drain reach the wire and stop there.
      await Future<void>.delayed(Duration.zero);

      await ledger.retire('intake-abc');

      mini.releaseEntries();
      await draining;
      await outbox.drain();

      // The house got the row, so the house was told to take it off again.
      expect(mini.entries.keys, ['intake-abc']);
      expect(mini.entries['intake-abc']!['deleted_at'], isNotNull);
      expect(whatWentOut().where((r) => r.contains('/retire')), hasLength(1));
    });
  });

  group('a correction waiting to go out is not a creation', () {
    test('and nothing but a creation is ever cancelled', () async {
      // Written on 22 August after a deliberate break proved nothing. Through
      // the app the two can never collide — a correction gets its own id — so
      // the path check looked like belt and braces that no test could reach.
      // It is not: it is the thing that keeps "still queued" meaning the row
      // itself rather than anything at all filed under its name. Driven
      // straight at the queue, because that is where the promise lives.
      await outbox.enqueue(
        path: '/household/entry/by-client/intake-abc/amend',
        body: const {'qty': 75},
        ownerId: mini.aidan,
        authorId: mini.aidan,
        clientId: 'intake-abc',
      );

      expect(await outbox.cancelQueuedEntry('intake-abc'), isFalse);
      expect(await outbox.pendingCount(), 1);
    });

    test('so deleting the row does not cancel it', () async {
      await ate('intake-abc');
      await outbox.drain();
      await ledger.amend('intake-abc', quantity: 75);
      expect(await outbox.pendingCount(), 1);

      await ledger.retire('intake-abc');

      // The correction and the removal, both waiting. Cancelling a correction
      // because a removal came after it would be the queue deciding what the
      // person meant.
      expect(await outbox.pendingCount(), 2);
    });
  });
}
