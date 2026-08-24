/// The day's plan sheet, and how much of the screen it takes.
///
/// Aidan, walking build 57 on 24 August: *"the sheet/modal that appears does so
/// mostly off the screen - it appears right at the very bottom of the screen,
/// and is about 1/3 of the width of the whole screen."*
///
/// A bottom sheet hands its child loose constraints, so a child that is a
/// column of short text hugs the longest line in it. The day sheet's widest
/// thing on an empty day is the word "Nothing planned", and that is about a
/// third of a phone. The sheet beneath it was the right size all along; what
/// was drawn inside it was not.
///
/// It only shows on an empty day, which is why nobody had seen it: the meal
/// picker one tap further in holds a search box, and a text field takes
/// whatever width it is offered.
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

  AppDatabase? db;
  late FakeHouseholdServer mini;
  late WeekRepository weeks;
  late PlanRepository plans;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    mini = FakeHouseholdServer();
    mini.today = wednesday;
    db = AppDatabase.createInMemory();
    final household = HouseholdRepository(ConfigDao(db!), api());
    await household.setOwner(mini.aidan);
    weeks = WeekRepository(api(), household);
    plans = PlanRepository(api(), household);
  });

  /// A phone, not the 800x600 the test binding hands out by default. Material's
  /// modal sheet caps itself at 640 wide, so on the default surface every sheet
  /// measures 640 whatever its child does, and the fault under test is
  /// invisible. His phone is nothing like 800 across.
  void aPhoneSizedScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

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

  Future<void> openFriday(WidgetTester tester) async {
    aPhoneSizedScreen(tester);
    await tester.pumpWidget(screen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fri'));
    await tester.pumpAndSettle();
  }

  testWidgets('an empty day still fills the width of the screen',
      (tester) async {
    await openFriday(tester);

    expect(find.text(PlanDaySheet.nothingPlanned), findsOneWidget,
        reason: 'the empty day is the case that hugged');
    final screenWidth = tester.view.physicalSize.width /
        tester.view.devicePixelRatio;
    expect(tester.getSize(find.byType(PlanDaySheet)).width, screenWidth,
        reason: 'it was about a third of it, at the bottom of the screen');
  });

  testWidgets('and so does a day with something on it', (tester) async {
    final meal = mini.addMeal(name: 'Chilli', kcal: 640);
    mini.planMeal(day: '2026-08-21', mealId: meal['id'] as int, title: 'Chilli');

    await openFriday(tester);

    final screenWidth = tester.view.physicalSize.width /
        tester.view.devicePixelRatio;
    expect(tester.getSize(find.byType(PlanDaySheet)).width, screenWidth);
  });
}
