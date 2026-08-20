/// The week ahead, on the screen this person already looks at.
///
/// Behaviour under test (Release E, TM-0008 — the phone half):
///
///  * the week is a view and nothing else: it shows what has been eaten and
///    what is planned, and it changes nothing;
///  * a day with a meal nobody has worked the calories out for reads as a
///    figure *and* a sentence saying what is not in it — never as the figure
///    alone, which would look finished;
///  * the two reasons a meal has no figure are said differently, because they
///    are fixed in two different places;
///  * a week against no target is not compared against an invented one;
///  * and with figures switched off, the week keeps its meals and loses every
///    number — including the count of missing ones, which is still a number.
///
/// The section is driven through its repository against a fake kitchen
/// computer, the same way the planned-meals section is: what matters is what
/// a person ends up looking at, and the assembly happens on the server.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
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

  HouseholdApi api() => HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    mini.today = wednesday;
    household = HouseholdRepository(ConfigDao(db), api());
    weeks = WeekRepository(api(), household);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Widget screen({bool figuresOff = false}) => MaterialApp(
        home: FiguresScope(
          figuresOff: figuresOff,
          child: Scaffold(
            body: WeekAheadSection(repository: weeks, start: monday),
          ),
        ),
      );

  void ate(String day, num kcal, {String label = 'Porridge'}) {
    mini.entries['e${mini.entries.length + 1}'] = {
      'owner_id': mini.aidan,
      'author_id': mini.aidan,
      'day': day,
      'label': label,
      'kcal': kcal,
    };
  }

  group('what the week shows', () {
    testWidgets('a week with nothing on it draws nothing at all',
        (tester) async {
      // Not a heading with an empty space under it. A person with no plan and
      // no diary should see Home exactly as it was before this existed.
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text(WeekAheadSection.heading), findsNothing);
    });

    testWidgets('a week with something on it has a heading and seven days',
        (tester) async {
      ate(monday, 500);
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text(WeekAheadSection.heading), findsOneWidget);
      for (final name in WeekAheadSection.dayNames) {
        expect(find.text(name), findsOneWidget);
      }
    });

    testWidgets('what was eaten is named on its day', (tester) async {
      ate(monday, 500, label: 'Porridge');
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Porridge'), findsOneWidget);
    });

    testWidgets('and so is what is still planned', (tester) async {
      mini.planMeal(
          day: friday,
          title: 'Chicken traybake',
          mealKcal: 600,
          forPeople: {mini.aidan: 1});
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Chicken traybake'), findsOneWidget);
    });

    testWidgets('a day already gone shows what was eaten and not what was not',
        (tester) async {
      // A meal planned for Monday and never answered is not food anybody ate.
      ate(monday, 500, label: 'Porridge');
      mini.planMeal(day: monday, title: 'Never happened', mealKcal: 600);
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Porridge'), findsOneWidget);
      expect(find.text('Never happened'), findsNothing);
    });

    testWidgets('the week total is eaten and planned together', (tester) async {
      ate(monday, 400);
      mini.planMeal(
          day: friday, title: 'Chilli', mealKcal: 600, forPeople: {mini.aidan: 1});
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.textContaining('1000 kcal this week'), findsOneWidget);
    });
  });

  group('what the week does not know', () {
    testWidgets('a meal with no calories is said out loud, not counted as zero',
        (tester) async {
      ate(monday, 400);
      mini.planMeal(day: friday, title: 'Chilli', forPeople: {mini.aidan: 1});
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      // The figure is what is known, and the sentence is what is not. Both.
      expect(find.textContaining('400 kcal this week'), findsOneWidget);
      expect(find.text(WeekAheadSection.awaitingLine(1)), findsWidgets);
    });

    testWidgets('a meal nobody has taken a share of counts the same way',
        (tester) async {
      mini.planMeal(day: friday, title: 'Chilli', mealKcal: 600);
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text(WeekAheadSection.awaitingLine(1)), findsWidgets);
    });

    testWidgets('two of them read as two, not as one', (tester) async {
      mini.planMeal(day: friday, title: 'Chilli');
      mini.planMeal(day: friday, title: 'Soup');
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text(WeekAheadSection.awaitingLine(2)), findsWidgets);
    });

    testWidgets('the sentence is on the day it belongs to', (tester) async {
      mini.planMeal(day: friday, title: 'Chilli');
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      // Once on the Friday row, once in the week's own footer.
      expect(find.text(WeekAheadSection.awaitingLine(1)), findsNWidgets(2));
    });
  });

  group('the allowance', () {
    testWidgets('a week is measured against seven days of the target',
        (tester) async {
      mini.settingsFor(mini.aidan)['daily_target_kcal'] = 2000;
      ate(monday, 400);
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.textContaining('of 14000 kcal'), findsOneWidget);
    });

    testWidgets('and against nothing at all when there is no target',
        (tester) async {
      // Inventing an allowance would be inventing a goal for somebody.
      ate(monday, 400);
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('400 kcal this week'), findsOneWidget);
      expect(find.textContaining(' of '), findsNothing);
    });
  });

  group('with figures switched off', () {
    testWidgets('the meals stay', (tester) async {
      ate(monday, 500, label: 'Porridge');
      await tester.pumpWidget(screen(figuresOff: true));
      await tester.pumpAndSettle();

      expect(find.text('Porridge'), findsOneWidget);
    });

    testWidgets('and every number goes', (tester) async {
      ate(monday, 500);
      await tester.pumpWidget(screen(figuresOff: true));
      await tester.pumpAndSettle();

      expect(find.textContaining('kcal'), findsNothing);
      expect(find.textContaining('this week'), findsNothing);
    });

    testWidgets('including the count of the ones that are missing',
        (tester) async {
      // A count of missing calories is still a calorie figure. Somebody who
      // asked not to see them has not asked to be told how many are unknown.
      ate(monday, 500);
      mini.planMeal(day: friday, title: 'Chilli');
      await tester.pumpWidget(screen(figuresOff: true));
      await tester.pumpAndSettle();

      expect(find.text(WeekAheadSection.awaitingLine(1)), findsNothing);
    });
  });

  group('when the Mac Mini cannot be reached', () {
    testWidgets('it says so rather than showing an empty week', (tester) async {
      // "Nothing is planned" and "I could not find out what is planned" are
      // different facts, and showing the first when the second is true is the
      // mistake this whole project keeps having to relearn.
      mini.reachable = false;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.textContaining("the week isn't showing"), findsOneWidget);
    });

    testWidgets('and nothing is written anywhere', (tester) async {
      mini.reachable = false;
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(mini.entries, isEmpty);
    });
  });

  group('the week is a read and only a read', () {
    testWidgets('looking at it asks for the week and nothing else',
        (tester) async {
      ate(monday, 400);
      mini.requests.clear();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(mini.requests, ['GET /household/week/${mini.aidan}']);
    });
  });
}
