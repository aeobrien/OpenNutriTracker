/// Closing the gap the meal's own screen just named.
///
/// Behaviour under test (Release 6, TM-0020/TM-0021, BC-0022's "what you
/// enter"). The meal's screen can now say *the vegetables are holding this
/// meal's figure up* — and until this existed, nothing could be done about it
/// from the phone. Every gap it found had to be closed by walking to the
/// kitchen panel. A screen that reports a problem and offers nothing is worse
/// than one that says nothing, because it teaches somebody that the report is
/// not worth reading.
///
/// The carrying test is [saying what the missing part is closes the gap and
/// the meal adds up]. Everything else here checks one step of that; only that
/// one checks that the steps join, which is the whole claim.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/domain/plan_week.dart';
import 'package:opennutritracker/features/plan/presentation/meal_screen.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdApi api;
  late HouseholdRepository household;
  late PlanRepository plan;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(mini.aidan);
    await household.people();
    plan = PlanRepository(api, household);
    GetIt.instance
      ..registerSingleton<FoodFinder>(
          FoodFinder(api, household, FoodItemDao(db)))
      ..registerSingleton<ConfigRepository>(ConfigRepository(ConfigDao(db)));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await db.close();
  });

  /// A traybake with its chicken settled and its vegetables not.
  Future<PlannedMeal> aHalfWrittenTraybake() async {
    mini.addFood(name: 'Tenderstem broccoli', kcal100: 35);
    final chicken = mini.addFood(name: 'Chicken thighs', kcal100: 177);
    mini.addMeal(name: 'Chicken traybake');
    mini.addMealPart(1, 'protein',
        foodName: 'Chicken thighs',
        qty: 500,
        unit: 'g',
        grams: 500,
        kcal: 885,
        trust: 'weighed',
        food: chicken);
    mini.addMealPart(1, 'vegetables',
        why: 'nobody has said what this is or how much of it goes in');
    final planId = mini.planMeal(
        day: mini.today, title: 'Chicken traybake', mealId: 1);
    return (await plan.week())
        .dayFor(mini.today)
        .planned
        .firstWhere((m) => m.planId == planId);
  }

  Future<void> openIt(WidgetTester tester, PlannedMeal planned) async {
    await tester.pumpWidget(MaterialApp(
      home: MealScreen(
        repository: plan,
        mealId: 1,
        title: 'Chicken traybake',
        people: await household.cachedPeople(),
        planned: planned,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> sayItIs(WidgetTester tester,
      {required String food, required String amount}) async {
    await tester.tap(find.text(food));
    await tester.pumpAndSettle();
    await tester.enterText(
        find.widgetWithText(TextField, MealScreen.howMuch), amount);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
  }

  group('filling in a part', () {
    testWidgets('the gap is what opens the way to fix it', (tester) async {
      await openIt(tester, await aHalfWrittenTraybake());

      await tester.tap(find.text('vegetables'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, MealScreen.whichFood),
          findsOneWidget);
      // And only the household's own foods are offered. A meal this house
      // cooks is made of things this house buys, and the meal's figure is only
      // ever as good as its worst part.
      expect(find.text('Tenderstem broccoli'), findsOneWidget);
    });

    testWidgets('saying what the missing part is closes the gap and the meal '
        'adds up', (tester) async {
      await openIt(tester, await aHalfWrittenTraybake());

      await tester.tap(find.text('vegetables'));
      await tester.pumpAndSettle();
      await sayItIs(tester, food: 'Tenderstem broccoli', amount: '200');

      // The gap is gone from the screen, in its own words.
      expect(find.textContaining('nobody has said what this is'), findsNothing,
          reason: 'the part was recorded and the screen still calls it a gap');
      expect(find.text('Tenderstem broccoli'), findsOneWidget);
      expect(find.text('200 g'), findsOneWidget);

      // And the thing the gap was blocking now works.
      await tester.tap(find.text(MealScreen.workItOut));
      await tester.pumpAndSettle();
      expect(mini.mealFigures[1]!['kcal'], 955,
          reason: '885 for the chicken plus 70 for 200 g of broccoli');
    });

    testWidgets('a part already settled can be corrected', (tester) async {
      // Somebody weighs the chicken properly. The boxes open on what it was,
      // so a 500 becoming a 400 is one character rather than a re-entry.
      await openIt(tester, await aHalfWrittenTraybake());

      await tester.tap(find.byTooltip(MealScreen.changeIt));
      await tester.pumpAndSettle();
      expect(find.text('500'), findsOneWidget,
          reason: 'the amount it already was is not in the box, so a small '
              'correction means typing the whole thing again');
      expect(find.widgetWithText(TextField, MealScreen.whichFood), findsNothing,
          reason: 'somebody weighing the chicken properly is made to find the '
              'chicken again before they can say what it weighed');

      await tester.enterText(
          find.widgetWithText(TextField, MealScreen.howMuch), '400');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('400 g'), findsOneWidget);
      expect(find.text('500 g'), findsNothing);
    });

    testWidgets('an amount that is not a number cannot be saved',
        (tester) async {
      // The house refuses a part with no amount, so offering the button would
      // only produce a refusal after the typing.
      await openIt(tester, await aHalfWrittenTraybake());
      await tester.tap(find.text('vegetables'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tenderstem broccoli'));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, MealScreen.howMuch), 'a handful');
      await tester.pumpAndSettle();

      expect(
          tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
              .onPressed,
          isNull);
    });

    testWidgets('backing out of the sheet changes nothing', (tester) async {
      await openIt(tester, await aHalfWrittenTraybake());
      await tester.tap(find.text('vegetables'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tenderstem broccoli'));
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.text('Save'))).pop();
      await tester.pumpAndSettle();

      expect(find.textContaining('nobody has said what this is'),
          findsOneWidget);
    });
  });
}
