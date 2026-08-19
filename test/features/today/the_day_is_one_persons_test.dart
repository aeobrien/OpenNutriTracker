/// The day is one person's, and it is honest about what it does not know.
///
/// These promises used to be tested against a screen called Today, which no
/// longer exists — Aidan pointed out that Home already was the day, and the
/// second tab went. The promises did not go with it, so they are tested here
/// against the day the household actually assembles.
///
/// What moved where, so nothing is lost quietly:
///
///  * *what has been eaten* and *where this person stands* → Home's own list
///    and ring, with the target covered by `one_target_test.dart`.
///  * *what is still planned* and *planned is not eaten* → the planned section,
///    covered by `planned_meal_row_test.dart`.
///  * *whose day it is*, *no invented target*, and *unknown is not nothing* →
///    here, because they are properties of the day itself rather than of any
///    one screen.
///
/// One promise from the deleted screen has **not** been rehomed: a row saying
/// "entered by the other phone" when the other person logged something on your
/// behalf. Home's list does not carry that mark. It is recorded rather than
/// pretended away.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';

import '../household/fake_household_server.dart';

void main() {
  const today = '2026-08-19';

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late DayRepository days;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    logger = HouseholdLogger(household, outbox);
    days = DayRepository(api, household);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  group("it is this person's day and nobody else's", () {
    test("the other person's food is not on it", () async {
      await logger.logFood(day: today, label: 'Cheese sandwich', kcal: 480);
      await outbox.drain();
      await logger.logFood(
          day: today,
          label: "Emily's soup",
          kcal: 300,
          owner: mini.emily,
          author: mini.emily);
      await outbox.drain();

      final day = await days.today(today);

      expect(day.logged.map((e) => e.label), contains('Cheese sandwich'));
      expect(day.logged.map((e) => e.label), isNot(contains("Emily's soup")));
      expect(day.eatenKcal, 480,
          reason: "the other person's lunch must not land on his total");
    });

    test("the target is this person's own", () async {
      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      await household.updateSettings(mini.emily, dailyTargetKcal: 1800);
      expect((await days.today(today)).targetKcal, 2400);
    });

    test('each person sees their own share of the same meal', () async {
      mini.planMeal(
        day: today,
        title: 'Chicken traybake',
        mealKcal: 640,
        forPeople: {mini.aidan: 1.5, mini.emily: 0.5},
      );
      expect((await days.forPerson(mini.aidan, today)).planned.single.portions,
          1.5);
      expect((await days.forPerson(mini.emily, today)).planned.single.portions,
          0.5);
    });
  });

  group('a day with nothing on it', () {
    test('is empty, and says so rather than reading as a day gone well',
        () async {
      final day = await days.today(today);
      expect(day.isEmpty, isTrue);
      expect(day.eatenKcal, 0);
    });

    test('does not invent a target', () async {
      final day = await days.today(today);
      expect(day.hasTarget, isFalse);
      expect(day.targetKcal, isNull);
      expect(day.remainingKcal, isNull,
          reason: 'a remaining figure with no target is a goal invented for '
              'somebody who never set one');
    });
  });

  group('honest gaps', () {
    test('a planned meal with no numbers is counted as unknown, not as zero',
        () async {
      mini.planMeal(
        day: today,
        title: 'Something from the freezer',
        mealKcal: null,
        forPeople: {mini.aidan: 1},
      );
      final day = await days.today(today);
      expect(day.planned.single.kcal, isNull,
          reason: 'zero would read as a free meal');
      expect(day.plannedUnknown, 1,
          reason: 'the day has to be able to say what it could not add up');
    });

    test('the total still to come leaves the unknown out of itself', () async {
      mini.planMeal(
          day: today, title: 'Traybake', mealKcal: 640, forPeople: {mini.aidan: 1});
      mini.planMeal(
          day: today, title: 'Freezer thing', mealKcal: null, forPeople: {mini.aidan: 1});
      final day = await days.today(today);
      expect(day.plannedKcal, 640);
      expect(day.plannedUnknown, 1);
    });
  });

  group('when the Mini cannot be reached', () {
    test('asking for the day fails rather than answering with an empty one',
        () async {
      mini.reachable = false;
      await expectLater(days.today(today), throwsA(isA<HouseholdUnreachable>()),
          reason: 'an empty day is a claim that this person ate nothing');
    });
  });
}
