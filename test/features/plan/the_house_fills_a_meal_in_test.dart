/// Filling a built meal in without searching for four things and typing four
/// numbers.
///
/// Behaviour under test. A built meal names its parts in the words somebody
/// built it in — "chicken", "pak choi", "sushi rice" — and until this existed
/// every one of them had to be searched for and given an amount by hand before
/// the meal could carry a figure at all. Four searches and four numbers is
/// enough friction that meals simply went without figures, which is the state
/// the roadmap item was written about.
///
/// The carrying test is [taking the proposals fills the meal in and it adds
/// up]. The rest check one step each; only that one checks the steps join.
///
/// The other half of this file is about honesty, and it matters more than the
/// convenience. An amount nobody has looked at must keep saying so — on the
/// row it is on, and in what the finished meal claims about itself. A meal
/// assembled entirely out of guesses that went on to say it was "worked out
/// from amounts somebody typed in" would be a false sentence produced by a
/// convenience feature, and the numbers it qualifies are quoted on other
/// screens.
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
import 'package:opennutritracker/features/plan/domain/meal_parts.dart';
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

  /// A built meal with nothing filled in and the house ready to propose two of
  /// its three parts. The third is deliberately one the house has never heard
  /// of, because that is the ordinary case and the screen has to say so.
  Future<PlannedMeal> anEmptyStirFry() async {
    final chicken = mini.addFood(name: 'Chicken breast', kcal100: 165);
    final rice = mini.addFood(name: 'Sushi rice', kcal100: 350);
    mini.addMeal(name: 'Teriyaki chicken');
    for (final component in ['chicken', 'samphire', 'sushi rice']) {
      mini.addMealPart(1, component,
          why: 'nobody has said what this is or how much of it goes in');
    }
    mini.suggestMealPart(1, 'chicken',
        role: 'protein', food: chicken, qty: 150);
    mini.suggestMealPart(1, 'samphire', role: 'veg');
    mini.suggestMealPart(1, 'sushi rice', role: 'carb', food: rice, qty: 75);
    final planId = mini.planMeal(
        day: mini.today, title: 'Teriyaki chicken', mealId: 1);
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
        title: 'Teriyaki chicken',
        people: await household.cachedPeople(),
        planned: planned,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> askForHelp(WidgetTester tester) async {
    await tester.tap(find.text(MealScreen.fillThemIn));
    await tester.pumpAndSettle();
  }

  group('being offered the answer', () {
    testWidgets('a meal with gaps offers to fill them in', (tester) async {
      await openIt(tester, await anEmptyStirFry());
      expect(find.text(MealScreen.fillThemIn), findsOneWidget);
    });

    testWidgets('and a meal with no gaps does not', (tester) async {
      final chicken = mini.addFood(name: 'Chicken breast', kcal100: 165);
      mini.addMeal(name: 'Teriyaki chicken');
      mini.addMealPart(1, 'chicken',
          foodName: 'Chicken breast',
          qty: 150,
          unit: 'g',
          grams: 150,
          kcal: 247.5,
          food: chicken);
      final planId = mini.planMeal(
          day: mini.today, title: 'Teriyaki chicken', mealId: 1);
      final planned = (await plan.week())
          .dayFor(mini.today)
          .planned
          .firstWhere((m) => m.planId == planId);
      await openIt(tester, planned);
      expect(find.text(MealScreen.fillThemIn), findsNothing,
          reason: 'a button whose answer is "nothing to do" wastes a tap');
    });

    testWidgets('asking shows what it would put in, and what it cannot',
        (tester) async {
      await openIt(tester, await anEmptyStirFry());
      await askForHelp(tester);

      expect(find.text('Chicken breast, 150 g'), findsOneWidget);
      expect(find.text('Sushi rice, 75 g'), findsOneWidget);
      // The one it has nothing for is named rather than left out: after the
      // others are taken, this is what is still holding the meal up.
      expect(find.text(MealScreen.stillToLookUp), findsOneWidget);
      expect(find.textContaining('samphire'), findsWidgets);
    });

    testWidgets('asking on its own saves nothing', (tester) async {
      await openIt(tester, await anEmptyStirFry());
      await askForHelp(tester);
      await tester.tap(find.text('Not now'));
      await tester.pumpAndSettle();

      // Every part is still the gap it was.
      expect(
          find.textContaining('nobody has said what this is'), findsNWidgets(3),
          reason: 'looking at a proposal changed the meal');
    });
  });

  group('taking them', () {
    testWidgets('taking the proposals fills the meal in and it adds up',
        (tester) async {
      await openIt(tester, await anEmptyStirFry());
      await askForHelp(tester);
      await tester.tap(find.text(MealScreen.takeThemAll));
      await tester.pumpAndSettle();

      // Two of the three gaps are closed, in the screen's own words.
      expect(find.text('Chicken breast'), findsOneWidget);
      expect(find.text('Sushi rice'), findsOneWidget);
      expect(find.textContaining('nobody has said what this is'), findsOneWidget,
          reason: 'only the component the house had nothing for should remain');
    });

    testWidgets('and every amount it filled in says it is a guess',
        (tester) async {
      await openIt(tester, await anEmptyStirFry());
      await askForHelp(tester);
      await tester.tap(find.text(MealScreen.takeThemAll));
      await tester.pumpAndSettle();

      expect(find.textContaining(MealScreen.guessedAmount), findsNWidgets(2));
    });

    testWidgets('an amount somebody typed does not say it is a guess',
        (tester) async {
      final chicken = mini.addFood(name: 'Chicken breast', kcal100: 165);
      mini.addMeal(name: 'Teriyaki chicken');
      mini.addMealPart(1, 'chicken',
          foodName: 'Chicken breast',
          qty: 150,
          unit: 'g',
          grams: 150,
          kcal: 247.5,
          food: chicken);
      final planId = mini.planMeal(
          day: mini.today, title: 'Teriyaki chicken', mealId: 1);
      await openIt(
          tester,
          (await plan.week())
              .dayFor(mini.today)
              .planned
              .firstWhere((m) => m.planId == planId));

      expect(find.textContaining(MealScreen.guessedAmount), findsNothing);
    });
  });

  group('what the meal then claims about itself', () {
    test('a figure built out of guessed helpings says so', () {
      // The wording is the point. "Worked out from its parts" is true and
      // useless here; somebody reading it would have no idea that nobody has
      // looked at a single one of the amounts under it.
      const made = MealMadeOf(mealId: 1, kcal: 520.4, trust: 'estimated');
      final line = MealScreen.trustLine(made);
      expect(line, isNotNull);
      expect(line, contains('guess'));
    });

    test('and it is not the sentence a typed-in meal gets', () {
      const guessed = MealMadeOf(mealId: 1, kcal: 520.4, trust: 'estimated');
      const typed = MealMadeOf(mealId: 1, kcal: 520.4, trust: 'typed');
      expect(MealScreen.trustLine(guessed),
          isNot(equals(MealScreen.trustLine(typed))));
    });

    test('a meal with no figure gets no sentence about one', () {
      const nothing = MealMadeOf(mealId: 1, trust: 'estimated');
      expect(MealScreen.trustLine(nothing), isNull);
    });
  });

  group('the proposal itself', () {
    test('one the house has no food for cannot be accepted', () {
      const nothing = ProposedPart(
          component: 'samphire', role: 'veg', already: false, why: 'no idea');
      expect(nothing.canBeAccepted, isFalse);
    });

    test('and neither can one somebody has already answered', () {
      final answered = ProposedPart(
        component: 'chicken',
        role: 'protein',
        already: true,
        why: 'somebody has already said what this is',
        food: null,
        qty: null,
      );
      expect(answered.canBeAccepted, isFalse,
          reason: "a proposal that can overwrite somebody's own answer "
              'eventually does');
    });
  });
}
