/// Reading, on the phone, what a row said before somebody changed it.
///
/// Behaviour under test — Release 7, TM-0023 / BC-0024. The Mac Mini has kept
/// every superseded version of a row since 22 August 2026, and until now no
/// phone could ask for one. The card's own reason for wanting it: a correction
/// is only safe to make if the thing it replaced is still readable, and "I did
/// not eat that" is itself sometimes a mistake.
///
/// These drive the ledger rather than a screen, for the same reason the other
/// correction tests do: the screens cannot be stood up without the phone's
/// whole diary behind them, and the promise that matters here is what comes
/// back and whether it can be put back.
///
/// The house they run against writes each version down the way the real server
/// does — before overwriting the row, inside the same change. A fake that let a
/// test hand it a ready-made history would prove the parsing and nothing about
/// whether a correction actually leaves a trace.
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
import 'package:opennutritracker/features/household/domain/what_it_was.dart';

import '../household/fake_household_server.dart';

void main() {
  final day = DateTime(2026, 8, 22, 19, 30);

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
      {double mine = 40,
      String label = 'Oat biscuits',
      List<FoodShare> alsoFor = const []}) async {
    await ledger.add(
      intakeId: intakeId,
      day: day,
      slot: 'snack',
      label: label,
      liquid: false,
      mine: mine,
      alsoFor: alsoFor,
      kcalPerUnit: 450 / 100,
    );
    await outbox.drain();
  }

  Map<String, dynamic> theRow(String clientId) => mini.entries[clientId]!;

  group('a row nobody has touched', () {
    test('has no history, and that is an answer rather than a gap', () async {
      await log('intake-abc');
      expect(await ledger.historyOf('intake-abc'), isEmpty);
    });
  });

  group('after a correction', () {
    test('what it said before is what comes back', () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc', quantity: 75, kcal: 337.5);
      await outbox.drain();

      final history = await ledger.historyOf('intake-abc');
      expect(history, hasLength(1));
      expect(history.first.snapshot['qty'], 40);
      expect(history.first.what, 'corrected');
    });

    test('the row itself carries the new figure, not the old one', () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc', quantity: 75, kcal: 337.5);
      await outbox.drain();

      expect(theRow('intake-abc')['qty'], 75);
      expect((await ledger.historyOf('intake-abc')).first.snapshot['qty'], 40);
    });

    test('it says who made the correction', () async {
      await log('intake-abc');
      await ledger.amend('intake-abc', kcal: 999);
      await outbox.drain();

      expect((await ledger.historyOf('intake-abc')).first.changedBy,
          mini.aidan);
    });

    test('two corrections leave two versions, newest first', () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc', quantity: 75);
      await outbox.drain();
      await ledger.amend('intake-abc', quantity: 90);
      await outbox.drain();

      final history = await ledger.historyOf('intake-abc');
      expect(history.map((v) => v.snapshot['qty']), [75, 40]);
      expect(history.map((v) => v.version), [1, 0]);
    });

    test('the whole row is kept, not only the field that changed', () async {
      await log('intake-abc', mine: 40, label: 'Oat biscuits');
      await ledger.amend('intake-abc', quantity: 75);
      await outbox.drain();

      // The amendment said nothing about the label, and the kept version still
      // has it. A list of changes would not.
      expect((await ledger.historyOf('intake-abc')).first.label,
          'Oat biscuits');
    });
  });

  group('taking it off and putting it back', () {
    test('a removal is in the history, in the house\'s own words', () async {
      await log('intake-abc');
      await ledger.retire('intake-abc');
      await outbox.drain();

      expect((await ledger.historyOf('intake-abc')).first.what, 'taken off');
    });

    test('and so is undoing it', () async {
      await log('intake-abc');
      await ledger.retire('intake-abc');
      await outbox.drain();
      await ledger.putBack('intake-abc');
      await outbox.drain();

      final history = await ledger.historyOf('intake-abc');
      expect(history.map((v) => v.what), ['put back', 'taken off']);
    });

    test('taking off something already off the day leaves no trace', () async {
      await log('intake-abc');
      await ledger.retire('intake-abc');
      await outbox.drain();
      await ledger.retire('intake-abc');
      await outbox.drain();

      // Two taps, one removal. The second changed nothing, so it says nothing.
      expect(await ledger.historyOf('intake-abc'), hasLength(1));
    });
  });

  group('putting a version back', () {
    test('the fields to send are worked out by the house', () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc', quantity: 75, kcal: 337.5);
      await outbox.drain();

      final was = (await ledger.historyOf('intake-abc')).first;
      expect(was.putBack['qty'], 40);
      expect(was.putBack.containsKey('label'), isTrue);
      // Not a field a correction may touch, so not offered back.
      expect(was.putBack.containsKey('version'), isFalse);
      expect(was.putBack.containsKey('state'), isFalse);
    });

    test('sending them back restores what it said', () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc', quantity: 75, kcal: 337.5);
      await outbox.drain();

      final was = (await ledger.historyOf('intake-abc')).first;
      await ledger.amend('intake-abc',
          quantity: (was.putBack['qty'] as num).toDouble(),
          kcal: was.putBack['kcal'] as num?);
      await outbox.drain();

      expect(theRow('intake-abc')['qty'], 40);
    });

    test('restoring is itself a correction, so it leaves its own trace',
        () async {
      await log('intake-abc', mine: 40);
      await ledger.amend('intake-abc', quantity: 75);
      await outbox.drain();
      await ledger.amend('intake-abc', quantity: 40);
      await outbox.drain();

      // Three states, two changes, and nothing rewritten. Putting a version
      // back is going forward to it, not going back — which is what stops a
      // restore quietly erasing the correction it undid.
      final history = await ledger.historyOf('intake-abc');
      expect(history.map((v) => v.snapshot['qty']), [75, 40]);
      expect(theRow('intake-abc')['qty'], 40);
    });
  });

  group('a move to the other person', () {
    test('shows in the history as the day it was on before', () async {
      await log('intake-abc');
      await ledger.amend('intake-abc', moveTo: mini.emily);
      await outbox.drain();

      final was = (await ledger.historyOf('intake-abc')).first;
      expect(was.owner, mini.aidan);
      expect(theRow('intake-abc')['owner_id'], mini.emily);
    });

    test('and says so, so putting it back is not a surprise', () async {
      await log('intake-abc');
      await ledger.amend('intake-abc', moveTo: mini.emily);
      await outbox.drain();

      final was = (await ledger.historyOf('intake-abc')).first;
      expect(was.movesItTo(mini.emily), isTrue);
      expect(was.movesItTo(mini.aidan), isFalse);
    });
  });

  group("the other person's share is its own row", () {
    test('with its own history', () async {
      await log('intake-abc',
          alsoFor: [FoodShare(personId: mini.emily, quantity: 60)]);
      await ledger.amend('intake-abc', quantity: 75);
      await outbox.drain();

      // The share was not touched, so it has nothing to say.
      expect(await ledger.historyOf('intake-abc'), hasLength(1));
      expect(mini.versions['intake-abc-p${mini.emily}'], isNull);
    });
  });

  group('reading a version', () {
    test('is one line a person can recognise it by', () {
      const was = WhatItWas(version: 0, what: 'corrected', snapshot: {
        'label': 'Oat biscuits',
        'qty': 40,
        'unit': 'g',
        'kcal': 180,
      });
      expect(was.line, 'Oat biscuits, 40 g, 180 kcal');
    });

    test('a row with no amount says nothing about one', () {
      const was = WhatItWas(version: 0, what: 'corrected', snapshot: {
        'label': 'Lunch out',
        'kcal': 600,
      });
      expect(was.line, 'Lunch out, 600 kcal');
      expect(was.amount, '');
    });

    test('a part amount keeps its fraction', () {
      const was = WhatItWas(version: 0, what: 'corrected', snapshot: {
        'label': 'Pie',
        'qty': 0.8,
        'unit': 'of them',
      });
      expect(was.amount, '0.8 of them');
    });

    test('an empty row says so rather than showing a blank', () {
      const was = WhatItWas(version: 0, what: 'corrected');
      expect(was.line, 'an entry with nothing on it');
    });
  });

  group('when the house cannot be reached', () {
    test('asking throws rather than answering "never corrected"', () async {
      await log('intake-abc');
      await ledger.amend('intake-abc', quantity: 75);
      await outbox.drain();

      mini.reachable = false;
      // The difference between "this was never corrected" and "I could not
      // ask" is the difference between a fact about the row and a fact about
      // the network. Showing the second as the first would tell somebody their
      // correction was never made.
      expect(() => ledger.historyOf('intake-abc'),
          throwsA(isA<HouseholdUnreachable>()));
    });
  });
}
