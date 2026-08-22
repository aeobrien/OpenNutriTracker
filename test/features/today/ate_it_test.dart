/// One tap to say you ate what was planned — and one to say you didn't.
///
/// Behaviour under test (Release B, TM-0010 and TM-0012): tonight's planned
/// dinner sits on Home as a ghost entry. Tapping it says you ate it and it
/// becomes a real entry on this person's ledger, with their own portion of the
/// meal. Holding it offers the other answer. Either answer takes it off the day
/// and neither touches the other person's.
///
/// What is proved here, and why each is worth a test:
///
///  * the ghost goes as soon as they answer, before the Mac Mini has heard,
///    because the answer is on the queue and being asked to confirm your dinner
///    twice is worse than a moment's optimism;
///  * and it does not come back when the day is read again before the queue has
///    drained — the server still calls the meal planned at that point, and that
///    is exactly the moment a person would be asked a second time;
///  * a sleeping Mini loses nothing — the tap survives and lands when the queue
///    next drains;
///  * "didn't have it" is a real answer and not a dismissal, so nothing appears
///    on the day afterwards and the household records the refusal;
///  * and the figure that lands is this person's share, not the meal's.
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

void main() {
  const today = '2026-08-19';

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late DayRepository days;
  late PlannedToday planned;
  late int traybake;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    logger = HouseholdLogger(household, outbox);
    days = DayRepository(api(), household);
    planned = PlannedToday(logger);
    await household.setOwner(mini.aidan);
    traybake = mini.planMeal(
      day: today,
      title: 'Chicken traybake',
      mealKcal: 640,
      forPeople: {mini.aidan: 1.5, mini.emily: 0.5},
    );
  });

  tearDown(() async => db.close());

  /// Read the day the way Home does, and hand it to the ghost list.
  Future<void> readTheDay() async => planned.takeFrom(await days.today(today));

  List<Map<String, dynamic>> ledgerOf(int person) =>
      mini.entries.values.where((e) => e['owner_id'] == person).toList();

  List<String> titlesOnTheDay() => [for (final p in planned.items) p.title];

  group('what is waiting on the day', () {
    test('tonight\'s dinner is there to answer', () async {
      await readTheDay();
      expect(titlesOnTheDay(), ['Chicken traybake']);
    });

    test('with this person\'s share of it, not the meal\'s', () async {
      await readTheDay();
      // 640 a portion, and he is down for one and a half of them.
      expect(planned.items.single.kcal, 960);
      expect(planned.items.single.portions, 1.5);
    });
  });

  group('ate it', () {
    test('puts the meal on this person\'s ledger', () async {
      await readTheDay();
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      await outbox.drain();

      final mine = ledgerOf(mini.aidan);
      expect(mine, hasLength(1));
      expect(mine.first['label'], 'Chicken traybake');
    });

    test('with this person\'s share of it, not the meal\'s', () async {
      await readTheDay();
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      await outbox.drain();

      expect(ledgerOf(mini.aidan).first['kcal'], 960);
      expect(ledgerOf(mini.aidan).first['qty'], 1.5);
    });

    test(
      'and the ghost goes straight away, before the Mini has heard',
      () async {
        await readTheDay();
        await planned.decide(planned.items.single, ate: true, slot: 'dinner');

        // Nothing has been sent yet — the queue has not been drained.
        expect(mini.entries, isEmpty);
        expect(
          titlesOnTheDay(),
          isEmpty,
          reason: 'a meal they have answered must not keep asking',
        );
      },
    );

    test('it does not come back when the day is asked again', () async {
      await readTheDay();
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');

      // Home re-reads the day for all sorts of reasons before the queue
      // drains, and at that moment the Mac Mini still calls this planned.
      await readTheDay();

      expect(titlesOnTheDay(), isEmpty);
    });

    test('nothing lands on the other person\'s ledger', () async {
      await readTheDay();
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      await outbox.drain();

      expect(ledgerOf(mini.emily), isEmpty);
    });

    test('under the meal of the day the card was sitting in', () async {
      // The plan is one meal against a date and does not know it is dinner.
      // The strip the ghost was drawn in does, and it has to say so, or the
      // Mac Mini falls back to the clock — which put a confirmed dinner under
      // Lunch on 22 August because that is when the tap happened.
      await readTheDay();
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      await outbox.drain();

      expect(ledgerOf(mini.aidan).first['slot'], 'dinner');
    });

    test('and the other person still has it to decide', () async {
      await readTheDay();
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      await outbox.drain();

      expect(mini.plannedFor(mini.emily, today), hasLength(1));
      expect(mini.decisionFor(traybake, mini.emily), isNull);
    });
  });

  group("didn't have it", () {
    test('takes it off the day', () async {
      await readTheDay();
      await planned.decide(planned.items.single, ate: false, slot: 'dinner');
      expect(titlesOnTheDay(), isEmpty);
    });

    test('and puts nothing at all on the ledger', () async {
      await readTheDay();
      await planned.decide(planned.items.single, ate: false, slot: 'dinner');
      await outbox.drain();

      expect(ledgerOf(mini.aidan), isEmpty);
      expect(mini.decisionFor(traybake, mini.aidan), 'skipped');
    });
  });

  group('a Mini that is asleep', () {
    test('does not lose the answer', () async {
      await readTheDay();
      mini.reachable = false;

      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      expect(await outbox.pendingCount(), 1);

      mini.reachable = true;
      await outbox.drain();

      expect(ledgerOf(mini.aidan), hasLength(1));
      expect(await outbox.pendingCount(), 0);
    });

    test('and the ghost still goes, because the answer was given', () async {
      await readTheDay();
      mini.reachable = false;
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      expect(titlesOnTheDay(), isEmpty);
    });
  });

  group('a phone that sends twice', () {
    test('still only eats it once', () async {
      await readTheDay();
      await planned.decide(planned.items.single, ate: true, slot: 'dinner');
      await outbox.drain();
      await outbox.drain();

      expect(ledgerOf(mini.aidan), hasLength(1));
    });
  });
}
