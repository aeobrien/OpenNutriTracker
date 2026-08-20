/// Planning the week from the phone.
///
/// Behaviour under test (Release E, TM-0019 — the phone half):
///
///  * there is one plan. A meal put on a day from the phone goes into the same
///    plan the kitchen panel keeps, through the same endpoint, and comes back
///    on the week;
///  * the way in is the day you are already looking at, not a tab of its own —
///    tapping a day on the week opens that day's plan;
///  * you pick from the meals the house already has, because a planned name
///    with no recipe behind it has no calories for the week and no ingredients
///    for the shopping list;
///  * taking a meal off never touches a ledger, and when somebody has already
///    eaten it the person is told that before it goes;
///  * and when the Mac Mini cannot be reached, the planner offers
///    nothing at all rather than queueing taps. Planning against a week you
///    cannot see is planning blind, and the other phone may have put something
///    on that day a minute ago.
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

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late WeekRepository weeks;
  late PlanRepository plans;

  HouseholdApi api() => HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    mini.today = wednesday;
    household = HouseholdRepository(ConfigDao(db), api());
    weeks = WeekRepository(api(), household);
    plans = PlanRepository(api(), household);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  /// The week with planning switched on, which is how Home mounts it.
  Widget screen({bool figuresOff = false, bool canPlan = true}) => MaterialApp(
        home: FiguresScope(
          figuresOff: figuresOff,
          child: Scaffold(
            body: WeekAheadSection(
              repository: weeks,
              start: monday,
              planner: canPlan ? plans : null,
            ),
          ),
        ),
      );

  /// Something inside the open sheet, and not the week row behind it — the
  /// week legitimately shows the same meal titles, so a bare text finder would
  /// match twice and say nothing about the sheet.
  Finder inSheet(Finder what) =>
      find.descendant(of: find.byType(PlanDaySheet), matching: what);

  /// Open one day's plan by tapping it on the week.
  Future<void> openDay(WidgetTester tester, String label) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  group('the way in', () {
    testWidgets('tapping a day on the week opens that day', (tester) async {
      await openDay(tester, 'Fri');

      expect(find.text(PlanDaySheet.heading(friday)), findsOneWidget);
    });

    testWidgets('a day with nothing on it says so rather than looking broken',
        (tester) async {
      await openDay(tester, 'Fri');

      expect(find.text(PlanDaySheet.nothingPlanned), findsOneWidget);
    });

    testWidgets('a day already planned shows what is on it', (tester) async {
      mini.planMeal(day: friday, title: 'Chilli', mealKcal: 640);

      await openDay(tester, 'Fri');

      expect(inSheet(find.text('Chilli')), findsOneWidget);
    });

    testWidgets('no planner means a day does not open at all', (tester) async {
      // Not a disabled button — nothing. A control that cannot do anything
      // should not be on the screen offering to.
      mini.planMeal(day: friday, title: 'Chilli', mealKcal: 640);
      await tester.pumpWidget(screen(canPlan: false));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      expect(find.text(PlanDaySheet.heading(friday)), findsNothing);
    });
  });

  group('putting a meal on a day', () {
    Future<void> add(WidgetTester tester, String meal) async {
      await tester.tap(find.text(PlanDaySheet.addLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text(meal));
      await tester.pumpAndSettle();
    }

    testWidgets('the choices are the meals the house already has',
        (tester) async {
      mini.addMeal(name: 'Chilli', kcal: 640);
      mini.addMeal(name: 'Porridge', kcal: 300);

      await openDay(tester, 'Fri');
      await tester.tap(find.text(PlanDaySheet.addLabel));
      await tester.pumpAndSettle();

      expect(find.text('Chilli'), findsOneWidget);
      expect(find.text('Porridge'), findsOneWidget);
    });

    testWidgets('picking one puts it on that day', (tester) async {
      mini.addMeal(name: 'Chilli', kcal: 640);

      await openDay(tester, 'Fri');
      await add(tester, 'Chilli');

      expect(mini.plan.single['day'], friday);
      expect(mini.plan.single['title'], 'Chilli');
    });

    testWidgets('it goes on the household plan, not a copy on this phone',
        (tester) async {
      mini.addMeal(name: 'Chilli', kcal: 640);

      await openDay(tester, 'Fri');
      await add(tester, 'Chilli');

      expect(mini.requests, contains('POST /household/plan/add'));
    });

    testWidgets('the meal is named as the person the app belongs to',
        (tester) async {
      // Not the handset. A phone can be handed over, and the plan should name
      // whoever made the decision.
      mini.addMeal(name: 'Chilli', kcal: 640);
      await household.people();

      await openDay(tester, 'Fri');
      await add(tester, 'Chilli');

      expect(mini.plannedBy.single, 'Aidan');
    });

    testWidgets('the day it is added to redraws without reopening it',
        (tester) async {
      mini.addMeal(name: 'Chilli', kcal: 640);

      await openDay(tester, 'Fri');
      await add(tester, 'Chilli');

      // Twice: once on the picker row, once on the day it is now on.
      expect(find.text('Chilli'), findsOneWidget);
      expect(find.text(PlanDaySheet.nothingPlanned), findsNothing);
    });

    testWidgets('a search that matches nothing says so', (tester) async {
      mini.addMeal(name: 'Chilli', kcal: 640);

      await openDay(tester, 'Fri');
      await tester.tap(find.text(PlanDaySheet.addLabel));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'lasagne');
      await tester.pumpAndSettle();

      expect(find.text(PlanDaySheet.noMeals), findsOneWidget);
      // And nothing was planned by typing a name that matches nothing.
      expect(mini.plan, isEmpty);
    });

    testWidgets('a meal with no numbers is offered and says it has none',
        (tester) async {
      // The picker must not hide it. A meal nobody has worked out is still a
      // meal you can plan; what it must not do is look as if it has a figure.
      mini.addMeal(name: 'Chilli');

      await openDay(tester, 'Fri');
      await tester.tap(find.text(PlanDaySheet.addLabel));
      await tester.pumpAndSettle();

      expect(find.text('Chilli'), findsOneWidget);
      expect(find.textContaining('a portion'), findsNothing);
    });
  });

  group('taking a meal off', () {
    testWidgets('a meal nobody has answered goes without being asked',
        (tester) async {
      mini.planMeal(day: friday, title: 'Chilli', mealKcal: 640);

      await openDay(tester, 'Fri');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(mini.plan, isEmpty);
    });

    testWidgets('a meal somebody has already eaten asks first', (tester) async {
      final planId =
          mini.planMeal(day: friday, title: 'Chilli', mealKcal: 640);
      mini.decisions[planId] = {mini.emily: 'ate'};

      await openDay(tester, 'Fri');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.text(PlanDaySheet.alreadyEaten), findsOneWidget);
      // And nothing has gone yet.
      expect(mini.plan, hasLength(1));
    });

    testWidgets('saying leave it leaves it', (tester) async {
      final planId =
          mini.planMeal(day: friday, title: 'Chilli', mealKcal: 640);
      mini.decisions[planId] = {mini.emily: 'ate'};

      await openDay(tester, 'Fri');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Leave it'));
      await tester.pumpAndSettle();

      expect(mini.plan, hasLength(1));
      expect(mini.requests.where((r) => r.contains('/remove')), isEmpty);
    });

    testWidgets('saying take it off takes it off the plan only',
        (tester) async {
      final planId =
          mini.planMeal(day: friday, title: 'Chilli', mealKcal: 640);
      mini.decisions[planId] = {mini.emily: 'ate'};
      mini.entries['e-1'] = {
        'client_id': 'e-1',
        'owner_id': mini.emily,
        'day': friday,
        'label': 'Chilli',
        'kcal': 640,
      };

      await openDay(tester, 'Fri');
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Take it off'));
      await tester.pumpAndSettle();

      expect(mini.plan, isEmpty);
      // The dinner she ate still happened. Un-planning it does not un-eat it.
      expect(mini.entries, hasLength(1));
    });
  });

  group('when the Mac Mini cannot be reached', () {
    testWidgets('the day says so rather than showing an empty plan',
        (tester) async {
      mini.planMeal(day: friday, title: 'Chilli', mealKcal: 640);
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      mini.reachable = false;

      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      expect(find.textContaining("Can't reach the Mac Mini"),
          findsOneWidget);
      expect(find.text(PlanDaySheet.nothingPlanned), findsNothing);
    });

    testWidgets('nothing can be added, and no tap is queued', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      mini.reachable = false;

      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      // Not a disabled button either — the control is not there. A decision
      // made against a week you cannot see is made blind.
      expect(find.text(PlanDaySheet.addLabel), findsNothing);
      expect(mini.plan, isEmpty);
    });
  });

  group('with figures switched off', () {
    testWidgets('the plan still works and carries no calorie figure',
        (tester) async {
      mini.addMeal(name: 'Chilli', kcal: 640);
      mini.planMeal(day: friday, title: 'Chilli', mealKcal: 640);

      await tester.pumpWidget(screen(figuresOff: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Chilli')), findsOneWidget);
      expect(find.textContaining('kcal'), findsNothing);
    });

    testWidgets('and is not told which meals have no numbers', (tester) async {
      // A count of missing calories is still a calorie figure, and somebody
      // who asked not to see calories has not asked to be told how many are
      // unaccounted for.
      mini.planMeal(day: friday, title: 'Chilli');

      await tester.pumpWidget(screen(figuresOff: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fri'));
      await tester.pumpAndSettle();

      expect(find.textContaining("don't have numbers"), findsNothing);
    });
  });
}
