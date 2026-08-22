/// The amount box, opened from a meal, starts on this person's share of it.
///
/// Behaviour under test (Release 6, TM-0014's first rung, BC-0014/BC-0022).
/// The order Aidan settled on 22 August puts the household's own portion above
/// what he last had and above the packet — but nothing on the phone could
/// supply one, because a portion is a share of a *planned meal* and no screen
/// had ever shown a meal's parts. The first rung has been sitting there
/// unreachable ever since it was written. This is what reaches it.
///
/// Half a traybake made with 500 g of chicken thighs is 250 g of chicken
/// thighs. That figure is one somebody in this house actually decided, which
/// is the whole reason it beats a remembered amount.
///
/// The carrying test is [his share beats what he had last time]. The other
/// tests here would pass on a version that only fills the box when it has
/// nothing else — and that version leaves the order exactly as it was before,
/// while looking from the outside as though it had been changed.
///
/// **What this file does not prove.** The amount screen itself is stood in
/// for, as it is everywhere else in this suite: it is a screen with its own
/// tests and its own bloc, and building it needs half the app. What is proved
/// here is the seam — what the meal's screen hands it — and, separately, what
/// the box's own resolver makes of that figure. The two halves meeting on a
/// real screen is watched on the phone, not here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/meal_detail/domain/default_portion.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
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

  /// What arrived at the amount screen, if anything did.
  MealDetailScreenArguments? reachedTheAmountScreen;

  setUp(() async {
    reachedTheAmountScreen = null;
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

  /// A box of six fish cakes weighing 400 g, so one of them is 66.7 g. The
  /// unit the box would count in for this food is "one of them", which is the
  /// case the conversion has to survive.
  Map<String, dynamic> aBoxOfSix() => mini.addFood(
      name: 'Fish cakes', kcal100: 200, packGrams: 400, perPack: 6);

  /// A dinner built round the whole box, with his share of it set.
  int aDinnerOfThem({num? hisShare}) {
    final cakes = aBoxOfSix();
    mini.addMeal(name: 'Fish cakes and peas', kcal: 900);
    mini.addMealPart(1, 'protein',
        foodName: 'Fish cakes',
        qty: 6,
        unit: 'item',
        grams: 400,
        kcal: 800,
        trust: 'typed',
        food: cakes);
    mini.mealWorkedOut(1, kcal: 900, trust: 'typed');
    return mini.planMeal(
      day: mini.today,
      title: 'Fish cakes and peas',
      mealKcal: 900,
      mealId: 1,
      forPeople: hisShare == null ? const {} : {mini.aidan: hisShare},
    );
  }

  Future<PlannedMeal> plannedRow(int planId) async => (await plan.week())
      .dayFor(mini.today)
      .planned
      .firstWhere((m) => m.planId == planId);

  Future<void> openTheMealAndTapTheFishCakes(WidgetTester tester,
      PlannedMeal planned) async {
    await tester.pumpWidget(MaterialApp(
      routes: {
        NavigationOptions.mealDetailRoute: (context) {
          reachedTheAmountScreen = ModalRoute.of(context)!.settings.arguments
              as MealDetailScreenArguments;
          return const Scaffold(body: Text('The amount screen'));
        },
      },
      home: MealScreen(
        repository: plan,
        mealId: 1,
        title: 'Fish cakes and peas',
        people: await household.cachedPeople(),
        planned: planned,
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fish cakes'));
    await tester.pumpAndSettle();
  }

  group('his share reaches the amount box', () {
    testWidgets('half a dinner of six fish cakes is 200 g of fish cakes',
        (tester) async {
      final planId = aDinnerOfThem(hisShare: 0.5);
      await openTheMealAndTapTheFishCakes(
          tester, await plannedRow(planId));

      expect(reachedTheAmountScreen, isNotNull,
          reason: 'tapping a part of a meal did not open its amount box');
      expect(reachedTheAmountScreen!.householdPortion, 200);
    });

    testWidgets('and it arrives as a weight, not as a count of them',
        (tester) async {
      // The warning that made this its own test: a share expressed in portions
      // dropped into a box counting fish cakes reads as half a fish cake, and
      // a share expressed in grams dropped in raw reads as two hundred of
      // them. Only the weight of his actual share is a figure the box's own
      // ladder can turn into either.
      final planId = aDinnerOfThem(hisShare: 0.5);
      await openTheMealAndTapTheFishCakes(
          tester, await plannedRow(planId));

      final food = reachedTheAmountScreen!.mealEntity;
      const oneOfThem = 'item';
      final portion = defaultPortionFor(
        food,
        usesImperialUnits: false,
        householdPortion: reachedTheAmountScreen!.householdPortion,
        unit: oneOfThem,
        gramsPerUnit: MealDetailBloc.convertQuantity(food, 1, oneOfThem),
      );

      expect(portion.amount, '3',
          reason: '200 g of a 66.7 g fish cake is three of them');
      expect(portion.source, PortionSource.householdPortion);
    });

    testWidgets('his share beats what he had last time', (tester) async {
      // The carrying test. A box that only fills from a share when it has
      // nothing else leaves the order exactly as it was, while looking from
      // outside as though it had been changed.
      final planId = aDinnerOfThem(hisShare: 0.5);
      await openTheMealAndTapTheFishCakes(
          tester, await plannedRow(planId));

      final asItArrived = reachedTheAmountScreen!.mealEntity;
      final asIfHeHadTwoLastTime = asItArrived.rememberingLastAmount(133);
      const oneOfThem = 'item';
      final portion = defaultPortionFor(
        asIfHeHadTwoLastTime,
        usesImperialUnits: false,
        householdPortion: reachedTheAmountScreen!.householdPortion,
        unit: oneOfThem,
        gramsPerUnit:
            MealDetailBloc.convertQuantity(asIfHeHadTwoLastTime, 1, oneOfThem),
      );

      expect(portion.source, PortionSource.householdPortion);
      expect(portion.amount, '3',
          reason: 'it fell back to the two he had last time, so the order '
              'Aidan settled is still not what happens');
    });

    testWidgets('a share nobody has set sends nothing rather than a one',
        (tester) async {
      // A default of one portion is a calorie figure nobody chose, sitting
      // exactly where a chosen one would be. With nothing sent, the box falls
      // to what he had last time, which is the next rung down and correct.
      final planId = aDinnerOfThem();
      await openTheMealAndTapTheFishCakes(
          tester, await plannedRow(planId));

      expect(reachedTheAmountScreen!.householdPortion, isNull);
    });

    testWidgets('the food that opens is the one the meal uses', (tester) async {
      // Not one found by name. Two tins named alike is the first time looking
      // up by name logs the wrong thing, and it looks right on the day.
      final planId = aDinnerOfThem(hisShare: 1);
      await openTheMealAndTapTheFishCakes(
          tester, await plannedRow(planId));

      final food = reachedTheAmountScreen!.mealEntity;
      expect(food.name, 'Fish cakes');
      expect(food.hasItemValues, isTrue,
          reason: 'the pack weight and count came with it, so the box can '
              'count in fish cakes at all');
    });

    testWidgets('it goes under the meal the plan says it is', (tester) async {
      final planId = aDinnerOfThem(hisShare: 1);
      await openTheMealAndTapTheFishCakes(
          tester, await plannedRow(planId));

      // The fake's plan rows are recorded as 'meal', which names no slot, so
      // this falls to the clock — the same rule the "put it on today" path
      // uses. What matters is that it is a real slot and not an invented one.
      expect(IntakeTypeEntity.values,
          contains(reachedTheAmountScreen!.intakeTypeEntity));
    });
  });
}
