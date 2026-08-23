/// What a meal's portions start at when it first lands on a day.
///
/// BC-0021 proposed one portion each. It was never taken, and nothing in the
/// builder set a portion at all, so a newly planned meal sat there as
/// "nobody has said" — which is honest but leaves the week unable to count it
/// and leaves two people looking at a dinner neither has claimed.
///
/// Aidan, 23 August 2026: *"100% of the meal, but prompts you to update it."*
///
/// So: the whole of it goes down as the share of whoever this phone belongs
/// to, and the screen says so. Both halves are the answer — the prompt is not
/// a nicety, because a silent 100% is the thing he ruled against.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/presentation/plan_day_sheet.dart';
import 'package:opennutritracker/features/week/data/week_repository.dart';
import 'package:opennutritracker/features/week/presentation/week_ahead_section.dart';

import '../household/fake_household_server.dart';

void main() {
  const monday = '2026-08-17';
  const wednesday = '2026-08-19';
  const friday = '2026-08-21';

  AppDatabase? db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late WeekRepository weeks;
  late PlanRepository plans;

  HouseholdApi api() => HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  /// Build the app's side afresh against a phone that either knows whose it is
  /// or does not. There is no way to un-tell a phone once it has been told —
  /// which is right, and means a test about a phone that has never been told
  /// has to start from a fresh one rather than clearing the old.
  Future<void> thisPhoneBelongsTo(int? person) async {
    await db?.close();
    db = AppDatabase.createInMemory();
    household = HouseholdRepository(ConfigDao(db!), api());
    weeks = WeekRepository(api(), household);
    plans = PlanRepository(api(), household);
    if (person != null) await household.setOwner(person);
  }

  setUp(() async {
    mini = FakeHouseholdServer();
    mini.today = wednesday;
    db = null;
    await thisPhoneBelongsTo(mini.aidan);
  });

  tearDown(() async => db?.close());

  Widget screen() => MaterialApp(
        home: FiguresScope(
          figuresOff: false,
          child: Scaffold(
            body: WeekAheadSection(
                repository: weeks, start: monday, planner: plans),
          ),
        ),
      );

  Future<void> addAMealToFriday(WidgetTester tester, String meal) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fri'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(PlanDaySheet.addLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(meal));
    await tester.pumpAndSettle();
  }

  group('through the repository', () {
    test('the whole of it goes down as this phone owner\'s share', () async {
      final meal = mini.addMeal(name: 'Chilli', kcal: 640);

      final added = await plans.add(day: friday, mealId: meal['id'] as int);

      expect(mini.portions[added.planId]?[mini.aidan], 1,
          reason: 'a meal nobody has claimed cannot be counted on the week');
      expect(added.guessedShare, isTrue);
    });

    test('the other person is left unsaid rather than given a nought',
        () async {
      final meal = mini.addMeal(name: 'Chilli', kcal: 640);

      final added = await plans.add(day: friday, mealId: meal['id'] as int);

      // A nought would be this phone saying Emily is not eating it, which
      // nobody has said. Unset says nobody has said, which is true.
      expect(mini.portions[added.planId]!.containsKey(mini.emily), isFalse);
    });

    test('a phone that does not know whose it is guesses nothing', () async {
      await thisPhoneBelongsTo(null);
      final meal = mini.addMeal(name: 'Chilli', kcal: 640);

      final added = await plans.add(day: friday, mealId: meal['id'] as int);

      expect(mini.portions[added.planId] ?? const {}, isEmpty);
      expect(added.guessedShare, isFalse,
          reason: 'nothing was guessed, so there is nothing to announce');
    });

    test('the meal still lands even if the share is refused', () async {
      final meal = mini.addMeal(name: 'Chilli', kcal: 640);
      mini.refusePortions = 'that plan row is not yours';

      final added = await plans.add(day: friday, mealId: meal['id'] as int);

      expect(mini.plan.single['title'], 'Chilli',
          reason: 'the meal being on the plan is what was asked for');
      expect(added.guessedShare, isFalse);
    });
  });

  group('on the screen', () {
    testWidgets('it says the whole meal has been put down as yours',
        (tester) async {
      mini.addMeal(name: 'Chilli', kcal: 640);

      await addAMealToFriday(tester, 'Chilli');

      expect(find.text(PlanRepository.defaultedPortions), findsOneWidget);
    });

    testWidgets('and still shows what is on the day', (tester) async {
      mini.addMeal(name: 'Chilli', kcal: 640);

      await addAMealToFriday(tester, 'Chilli');

      // The prompt sits above the plan rather than in place of it. A problem
      // hides the plan, and this is not a problem.
      expect(
          find.descendant(
              of: find.byType(PlanDaySheet), matching: find.text('Chilli')),
          findsWidgets);
    });

    testWidgets('it says nothing when nothing was guessed', (tester) async {
      // A phone that has never been told whose it is cannot reach this screen
      // at all, so the way to arrive here with nothing guessed is the house
      // refusing the share. Either way the rule is the same: the prompt is a
      // report of something that happened, and nothing happened.
      mini.addMeal(name: 'Chilli', kcal: 640);
      mini.refusePortions = 'that plan row is not yours';

      await addAMealToFriday(tester, 'Chilli');

      expect(find.text(PlanRepository.defaultedPortions), findsNothing);
      expect(
          find.descendant(
              of: find.byType(PlanDaySheet), matching: find.text('Chilli')),
          findsWidgets,
          reason: 'the meal still went on the day');
    });
  });
}
