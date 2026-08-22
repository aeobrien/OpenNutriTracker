/// One tap, two ledgers: confirming a planned meal for both people at once.
///
/// Behaviour under test (Release B, TM-0011): holding tonight's planned dinner
/// offers "For both of us". Choosing it puts the meal on the tapper's day *and*
/// on the other person's — each at their own portion, both authored by whoever
/// tapped.
///
/// The rule this file exists to hold is the second half of that sentence: **the
/// other person's portion is never sent from this phone.** The household has
/// already recorded how much of a planned meal is each person's, and the Mac
/// Mini reads it when the answer arrives. A phone that helpfully sent its own
/// number would put a made-up calorie figure on somebody else's day, looking
/// exactly as solid as a real one — which is the single thing this whole
/// subsystem is built to avoid.
///
/// The carrying test is [the other person's day gets their own portion, not
/// this one's]. Aidan is down for 1.5 portions and Emily for 0.5 of the same
/// dinner; an implementation that sent Aidan's amount for both would pass every
/// other test here and would be wrong in the way that matters.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/domain/planned_today.dart';

import '../household/fake_household_server.dart';

/// A logger that works exactly like the real one until the nth answer, which it
/// refuses.
///
/// Used for one case only: the tapper's own answer is recorded and the other
/// person's is not. That cannot be staged with a real queue — the queue is
/// deliberately hard to make fail — and the difference between "nothing was
/// recorded" and "half of it was" is the whole reason the screen has three
/// outcomes to report instead of two.
class _RefusesTheNthAnswer extends HouseholdLogger {
  final int refuseFrom;
  int calls = 0;

  _RefusesTheNthAnswer(super.repository, super.outbox,
      {required this.refuseFrom});

  @override
  Future<String> decidePlan({
    required int planId,
    required bool ate,
    String? slot,
    int? owner,
    int? author,
    DateTime? at,
  }) async {
    calls += 1;
    if (calls >= refuseFrom) throw StateError('the queue would not take it');
    return super.decidePlan(
        planId: planId, ate: ate, slot: slot, owner: owner, author: author,
        at: at);
  }
}

void main() {
  const today = '2026-08-19';

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late DayRepository days;
  late PlannedToday planned;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  /// The dinner both of them are down for, at different amounts.
  Future<void> aSharedDinner() async {
    mini.planMeal(
      day: today,
      title: 'Chicken traybake',
      mealKcal: 640,
      forPeople: {mini.aidan: 1.5, mini.emily: 0.5},
    );
    planned.takeFrom(await days.today(today));
    await planned.findTheOtherPerson();
  }

  List<Map<String, dynamic>> ledgerOf(int person) =>
      mini.entries.values.where((e) => e['owner_id'] == person).toList();

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    logger = HouseholdLogger(household, outbox);
    days = DayRepository(api(), household);
    planned = PlannedToday(logger, household);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  group('who the phone can answer for', () {
    test('the other person in the house, by name', () async {
      await aSharedDinner();
      expect(planned.theOther?.id, mini.emily);
      expect(planned.theOther?.name, isNotEmpty);
    });

    test('nobody, until somebody has said whose phone this is', () async {
      // A phone of its own, with its own storage, that nobody has claimed.
      final unclaimed = AppDatabase.createInMemory();
      final fresh = PlannedToday(
          logger, HouseholdRepository(ConfigDao(unclaimed), api()));
      await fresh.findTheOtherPerson();
      expect(fresh.theOther, isNull,
          reason: 'a phone that does not know who is holding it cannot know '
              'who the other person is either');
      await unclaimed.close();
    });

    test('nobody, when the Mac Mini has never answered', () async {
      mini.reachable = false;
      final quiet = PlannedToday(logger, household);
      await quiet.findTheOtherPerson();
      expect(quiet.theOther, isNull);
    });
  });

  group('answering for both', () {
    test('the other person\'s day gets their own portion, not this one\'s',
        () async {
      await aSharedDinner();
      final answer = await planned.decide(planned.items.single,
          ate: true, slot: 'dinner', alsoForTheOther: true);
      await outbox.drain();

      expect(answer, PlanAnswer.queued);
      expect(ledgerOf(mini.aidan).single['qty'], 1.5);
      expect(ledgerOf(mini.aidan).single['kcal'], 960);
      expect(ledgerOf(mini.emily).single['qty'], 0.5,
          reason: "Emily is down for half a portion; sending Aidan's 1.5 for "
              'her would be a made-up figure on her day');
      expect(ledgerOf(mini.emily).single['kcal'], 320);
    });

    test('both rows are authored by the person who tapped', () async {
      await aSharedDinner();
      await planned.decide(planned.items.single,
          ate: true, slot: 'dinner', alsoForTheOther: true);
      await outbox.drain();

      expect(ledgerOf(mini.emily).single['author_id'], mini.aidan,
          reason: 'Emily did not enter this; her phone should show that Aidan '
              'did');
      expect(ledgerOf(mini.emily).single['owner_id'], mini.emily);
    });

    test('the meal of the day is carried to both', () async {
      await aSharedDinner();
      await planned.decide(planned.items.single,
          ate: true, slot: 'dinner', alsoForTheOther: true);
      await outbox.drain();

      expect(ledgerOf(mini.aidan).single['slot'], 'dinner');
      expect(ledgerOf(mini.emily).single['slot'], 'dinner',
          reason: 'a dinner filed under lunch on the other phone is the same '
              'bug, one person along');
    });

    test('and the card goes off this day, once', () async {
      await aSharedDinner();
      await planned.decide(planned.items.single,
          ate: true, slot: 'dinner', alsoForTheOther: true);
      expect(planned.items, isEmpty);

      // The Mac Mini still calls it planned for Emily — she has not answered on
      // her own phone — but this phone has answered and must not ask again.
      planned.takeFrom(await days.today(today));
      expect(planned.items, isEmpty);
    });
  });

  group('answering for just me', () {
    test('leaves the other person\'s day alone', () async {
      await aSharedDinner();
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      await outbox.drain();

      expect(ledgerOf(mini.aidan), hasLength(1));
      expect(ledgerOf(mini.emily), isEmpty,
          reason: 'answering for yourself has never touched the other ledger '
              'and must not start now');
    });

    test('and neither does saying you did not have it', () async {
      await aSharedDinner();
      await planned.decide(planned.items.single, ate: false, slot: 'dinner');
      await outbox.drain();

      expect(ledgerOf(mini.aidan), isEmpty);
      expect(ledgerOf(mini.emily), isEmpty);
    });
  });

  group('when only half of it lands', () {
    test('the tapper is told their own answer stuck and the other did not',
        () async {
      final halting = _RefusesTheNthAnswer(household, outbox, refuseFrom: 2);
      planned = PlannedToday(halting, household);
      await aSharedDinner();

      final answer = await planned.decide(planned.items.single,
          ate: true, slot: 'dinner', alsoForTheOther: true);

      expect(answer, PlanAnswer.onlyMine);
      expect(planned.items, isEmpty,
          reason: 'their own answer was recorded, so the meal is settled for '
              'them and asking again would be wrong');
      await outbox.drain();
      expect(ledgerOf(mini.aidan), hasLength(1));
      expect(ledgerOf(mini.emily), isEmpty);
    });

    test('and nothing recorded at all brings the meal back', () async {
      final refusing = _RefusesTheNthAnswer(household, outbox, refuseFrom: 1);
      planned = PlannedToday(refusing, household);
      await aSharedDinner();

      final answer = await planned.decide(planned.items.single,
          ate: true, slot: 'dinner', alsoForTheOther: true);

      expect(answer, PlanAnswer.notRecorded);

      // The card leaves the screen the instant they tap, always — that is what
      // makes tapping feel like it worked. What brings it back is the next read
      // of the day, which Home does immediately on this answer. Being asked
      // again is the honest outcome when nothing was written down.
      planned.takeFrom(await days.today(today));
      expect(planned.items, hasLength(1),
          reason: 'a decision nothing recorded is worse than asking again');
    });
  });
}
