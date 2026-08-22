/// A meal's own screen — what it is made of, and whose share is whose.
///
/// Behaviour under test (Release 6, TM-0020/TM-0021, BC-0022). Until now a
/// meal on the plan was a name and a number, and the number could not be
/// checked from the phone at all: nothing on it had ever asked the house what
/// a meal was made of. A calorie figure with nothing behind it is believed
/// just as readily when it is wrong.
///
/// The carrying test is [a part nobody has chosen a food for is on the screen,
/// with the reason]. Everything else here would pass on a version that showed
/// only the parts it had numbers for — and that version is worse than no
/// screen, because it turns a half-described dinner into a confident-looking
/// list with an unexplained blank where the total should be. The whole point
/// of opening a meal is to find out why its figure is missing.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/domain/plan_week.dart';
import 'package:opennutritracker/features/plan/presentation/meal_screen.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late PlanRepository plan;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(mini.aidan);
    // Cached, because the screen reads the house from the cache rather than
    // waiting on the network to say two names it already knows.
    await household.people();
    plan = PlanRepository(api, household);
  });

  tearDown(() async => db.close());

  /// A chicken traybake on Tuesday, his half and her one.
  int aTraybakeOnTuesday({Map<int, num> shares = const {}}) {
    mini.addMeal(name: 'Chicken traybake', kcal: 620);
    mini.addMealPart(1, 'protein',
        foodName: 'Chicken thighs',
        qty: 500,
        unit: 'g',
        grams: 500,
        kcal: 885,
        trust: 'weighed');
    mini.addMealPart(1, 'carbohydrate',
        foodName: 'New potatoes',
        qty: 600,
        unit: 'g',
        grams: 600,
        kcal: 450,
        trust: 'typed');
    mini.mealWorkedOut(1, kcal: 620, trust: 'typed');
    return mini.planMeal(
        day: mini.today,
        title: 'Chicken traybake',
        mealKcal: 620,
        mealId: 1,
        forPeople: shares);
  }

  Future<PlannedMeal> plannedRow(int planId) async {
    final week = await plan.week();
    return week
        .dayFor(mini.today)
        .planned
        .firstWhere((m) => m.planId == planId);
  }

  Future<void> openIt(WidgetTester tester,
      {PlannedMeal? planned, List<HouseholdPerson>? people}) async {
    await tester.pumpWidget(MaterialApp(
      home: MealScreen(
        repository: plan,
        mealId: 1,
        title: 'Chicken traybake',
        people: people ?? await household.cachedPeople(),
        planned: planned,
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('what it is made of', () {
    testWidgets('a part nobody has chosen a food for is on the screen, '
        'with the reason', (tester) async {
      final planId = aTraybakeOnTuesday();
      mini.addMealPart(1, 'vegetables',
          why: 'nobody has said what this is or how much of it goes in');

      await openIt(tester, planned: await plannedRow(planId));

      expect(find.text('vegetables'), findsOneWidget,
          reason: 'the part holding the meal up was left off the screen, so '
              'the missing total has nothing on screen explaining it');
      expect(
          find.text('nobody has said what this is or how much of it goes in'),
          findsOneWidget);
    });

    testWidgets('each part shows what it contributes', (tester) async {
      final planId = aTraybakeOnTuesday();
      await openIt(tester, planned: await plannedRow(planId));

      expect(find.text('Chicken thighs'), findsOneWidget);
      expect(find.text('500 g'), findsOneWidget);
      expect(find.text('885 kcal'), findsOneWidget);
      expect(find.text('New potatoes'), findsOneWidget);
    });

    testWidgets('a meal out of a packet says so rather than showing nothing',
        (tester) async {
      mini.addMeal(name: 'Fish and chips', kcal: 900);
      final planId = mini.planMeal(
          day: mini.today,
          title: 'Fish and chips',
          mealKcal: 900,
          mealId: 1);

      await openIt(tester, planned: await plannedRow(planId));

      expect(find.text(MealScreen.notMadeOfParts), findsOneWidget);
    });

    testWidgets('the trust line says it in words, at the weakest part',
        (tester) async {
      mini.addMeal(name: 'Chicken traybake', kcal: 620);
      mini.addMealPart(1, 'protein',
          foodName: 'Chicken thighs', qty: 500, unit: 'g', grams: 500,
          kcal: 885, trust: 'weighed');
      mini.mealWorkedOut(1, kcal: 620, trust: 'guess');
      final planId = mini.planMeal(
          day: mini.today, title: 'Chicken traybake', mealKcal: 620, mealId: 1);

      await openIt(tester, planned: await plannedRow(planId));

      expect(find.textContaining('treat the whole figure as a guess'),
          findsOneWidget);
    });

    testWidgets('a meal never worked out has no trust line to give',
        (tester) async {
      // A caveat about a number nobody has is a sentence about nothing.
      mini.addMeal(name: 'Chicken traybake');
      mini.addMealPart(1, 'protein',
          foodName: 'Chicken thighs', qty: 500, unit: 'g', grams: 500,
          kcal: 885, trust: 'weighed');
      final planId = mini.planMeal(
          day: mini.today, title: 'Chicken traybake', mealId: 1);

      await openIt(tester, planned: await plannedRow(planId));

      expect(find.textContaining('Worked out from'), findsNothing);
    });
  });

  group('whose share', () {
    testWidgets('each person is named with their own portion beside it',
        (tester) async {
      final planId =
          aTraybakeOnTuesday(shares: {mini.aidan: 1, mini.emily: 0.5});

      await openIt(tester, planned: await plannedRow(planId));

      expect(find.text('One portion'), findsOneWidget);
      expect(find.text('0.5 of it'), findsOneWidget);
    });

    testWidgets('and what that portion actually comes to, beside it',
        (tester) async {
      // The figure and the portion on the same row is the only place the two
      // can be checked against each other.
      final planId =
          aTraybakeOnTuesday(shares: {mini.aidan: 1, mini.emily: 0.5});

      await openIt(tester, planned: await plannedRow(planId));

      expect(find.text('620 kcal'), findsOneWidget);
      expect(find.text('310 kcal'), findsOneWidget);
    });

    testWidgets('a portion nobody has set reads as nobody having said',
        (tester) async {
      // Not as none, and not as one. A default of one is a calorie figure
      // nobody chose, sitting exactly where a chosen one would be.
      final planId = aTraybakeOnTuesday(shares: {mini.aidan: 1});

      await openIt(tester, planned: await plannedRow(planId));

      expect(find.text(MealScreen.nobodyHasSaid), findsOneWidget);
      expect(find.text('620 kcal'), findsOneWidget);
      expect(find.text('310 kcal'), findsNothing);
    });

    testWidgets('a portion can be changed here, and reaches the house',
        (tester) async {
      final planId =
          aTraybakeOnTuesday(shares: {mini.aidan: 1, mini.emily: 0.5});
      await openIt(tester, planned: await plannedRow(planId));

      await tester.tap(find.text('Aidan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('0.75 of it').last);
      await tester.pumpAndSettle();

      expect(mini.portions[planId]![mini.aidan], 0.75);
      expect(find.text('0.75 of it'), findsOneWidget);
      expect(find.text('465 kcal'), findsOneWidget);
    });

    testWidgets('a meal opened away from a day says where portions are set',
        (tester) async {
      // Portions belong to a planned day, not to the meal, so a meal reached
      // from the picker has none — and shows no zeroes, which would read as
      // nobody having any.
      aTraybakeOnTuesday();

      await openIt(tester);

      expect(find.text(MealScreen.noPortionsHere), findsOneWidget);
      expect(find.text(MealScreen.nobodyHasSaid), findsNothing);
    });
  });
}
