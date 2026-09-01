/// The Plan tab, moved off the week you are standing in.
///
/// Behaviour under test — the whole of Aidan's step 11 on 1 September 2026:
///
///   "The plan page only ever shows this week. I can't see any dates at all
///   and I can only view the week that I'm currently on. There is a calendar
///   button in the top left but tapping it does nothing so I can't move
///   forward to a date after 7th September"
///
/// Three separate things in one sentence, and they are three separate faults:
///
///  * the day rows carried a weekday name and no date at all;
///  * the tab asked for no week in particular and offered no way to ask for
///    another, so the week it opened on was the only week it could ever show;
///  * and the calendar in the top-left is the app bar's title icon, a picture
///    in the slot a back button sits in — on this tab it is a calendar on a
///    screen about dates, so it reads as the way to choose one.
///
/// The page is mounted for real rather than the section underneath it,
/// because two of the three faults are the page's and not the section's.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/presentation/plan_page.dart';
import 'package:opennutritracker/features/shopping/data/shopping_repository.dart';
import 'package:opennutritracker/features/week/data/week_repository.dart';
import 'package:opennutritracker/features/week/presentation/week_ahead_section.dart';

import '../household/fake_household_server.dart';

void main() {
  // A Wednesday, so "this week" is 31 August to 6 September and the week he
  // could not reach — anything after the 7th — is one tap forward.
  const wednesday = '2026-09-02';

  late AppDatabase db;
  late FakeHouseholdServer mini;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    mini.today = wednesday;
    final household = HouseholdRepository(ConfigDao(db), api());
    await household.setOwner(mini.aidan);
    // The page reaches for these itself, the way the running app hands them to
    // it. Registering them is the price of testing the page rather than the
    // section it holds.
    locator.registerSingleton<WeekRepository>(WeekRepository(api(), household));
    locator.registerSingleton<PlanRepository>(PlanRepository(api(), household));
    locator.registerSingleton<ShoppingRepository>(ShoppingRepository(
        api(), household, ConfigDao(db), Outbox.of(db, api())));
  });

  tearDown(() async {
    await locator.reset();
    await db.close();
  });

  Widget screen() => const MaterialApp(
        home: FiguresScope(
          figuresOff: false,
          child: Scaffold(body: PlanPage()),
        ),
      );

  testWidgets('the days carry their dates, not just their names',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    // Monday the 31st through Sunday the 6th.
    expect(find.text('Mon 31'), findsOneWidget);
    expect(find.text('Sun 6'), findsOneWidget);
  });

  testWidgets('the week it opens on is named by its dates', (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    expect(find.text('31 August – 6 September'), findsOneWidget);
  });

  testWidgets('the arrow forward reaches the week after the 7th',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(PlanPage.nextWeek));
    await tester.pumpAndSettle();

    expect(find.text('7 – 13 September'), findsOneWidget);
    expect(find.text('Mon 7'), findsOneWidget);
    expect(find.text('Sun 13'), findsOneWidget);
  });

  testWidgets('and back again, both by the arrow and by the way home',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(PlanPage.nextWeek));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(PlanPage.previousWeek));
    await tester.pumpAndSettle();
    expect(find.text('31 August – 6 September'), findsOneWidget);

    // Two forward, then the one tap back to where he started.
    await tester.tap(find.byTooltip(PlanPage.nextWeek));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(PlanPage.nextWeek));
    await tester.pumpAndSettle();
    expect(find.text('14 – 20 September'), findsOneWidget);

    await tester.tap(find.text(PlanPage.thisWeek));
    await tester.pumpAndSettle();
    expect(find.text('31 August – 6 September'), findsOneWidget);
  });

  testWidgets('the way back only appears when there is somewhere to go back to',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text(PlanPage.thisWeek), findsNothing);

    await tester.tap(find.byTooltip(PlanPage.nextWeek));
    await tester.pumpAndSettle();
    expect(find.text(PlanPage.thisWeek), findsOneWidget);
  });

  testWidgets('the calendar in the top-left opens a date to choose',
      (tester) async {
    // The app bar belongs to the screen around the tab, so this stands it up
    // the way that screen does: the icon wired to the page's own state.
    final page = GlobalKey<PlanPageState>();
    await tester.pumpWidget(MaterialApp(
      home: FiguresScope(
        figuresOff: false,
        child: Scaffold(
          appBar: AppBar(
            leading: Builder(
              builder: (context) => IconButton(
                tooltip: 'Choose a week',
                icon: const Icon(Icons.calendar_month),
                onPressed: () => page.currentState?.pickWeek(),
              ),
            ),
          ),
          body: PlanPage(key: page),
        ),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Choose a week'));
    await tester.pumpAndSettle();

    expect(find.text('Which week?'), findsOneWidget);
  });

  testWidgets('a week the page moved to is the week it asks the house for',
      (tester) async {
    // Something planned on a day he said he could not reach at all.
    mini.planMeal(day: '2026-09-09', title: 'Chilli', mealKcal: 640);

    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    expect(find.text('Chilli'), findsNothing,
        reason: 'the 9th is not in the week the tab opens on');

    await tester.tap(find.byTooltip(PlanPage.nextWeek));
    await tester.pumpAndSettle();

    // Not a relabelled heading over the same seven days: the meal is there
    // because those days were fetched from the house.
    expect(find.text('Chilli'), findsOneWidget);
  });

  testWidgets('the section no longer calls every week "This week"',
      (tester) async {
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(PlanPage.nextWeek));
    await tester.pumpAndSettle();

    // The only 'This week' left is the way back, and it says what it does.
    expect(find.text(PlanPage.thisWeek), findsOneWidget);
    expect(find.byType(WeekAheadSection), findsOneWidget);
  });
}
