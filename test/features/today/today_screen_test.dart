/// The day, read the way a person reads it.
///
/// Behaviour under test (Release 1, promise 6): Today shows the day as a list —
/// what has been eaten, what is still planned, and where the person stands
/// against their own target.
///
/// Every test here renders the actual screen and asserts on text a person would
/// see. That is deliberate and it is the harder way to write it: a test over a
/// view model computing a total would pass while the screen showed the two
/// people's days mixed together, or planned meals counted as eaten, or a
/// remaining figure that quietly assumed a target nobody set.
///
/// The day used throughout has a mix — two things eaten, one planned, some
/// exercise — because a day with only one kind of row cannot show whether the
/// two kinds are distinguishable, which is the next promise along.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/presentation/planned_meal_row.dart';
import 'package:opennutritracker/features/today/presentation/today_screen.dart';

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

  Widget screen() => MaterialApp(
        home: Scaffold(
          body: TodayScreen(repository: days, day: today),
        ),
      );

  /// A day with both kinds of row on it, plus exercise.
  Future<void> anOrdinaryDay() async {
    await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
    await logger.logFood(
        day: today, label: 'Porridge and berries', kcal: 320, slot: 'breakfast');
    await logger.logFood(day: today, label: 'Cheese sandwich', kcal: 480);
    await logger.logExercise(day: today, source: 'health', kcal: 300);
    await outbox.drain();
    mini.planMeal(
      day: today,
      title: 'Chicken traybake',
      mealKcal: 640,
      forPeople: {mini.aidan: 1.5, mini.emily: 0.5},
    );
  }

  group('the day as a list', () {
    testWidgets('shows what has been eaten', (tester) async {
      await anOrdinaryDay();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Eaten'), findsOneWidget);
      expect(find.text('Porridge and berries'), findsOneWidget);
      expect(find.text('Cheese sandwich'), findsOneWidget);
      expect(find.text('320 kcal'), findsOneWidget);
      expect(find.text('480 kcal'), findsOneWidget);
    });

    testWidgets('shows what is still planned', (tester) async {
      await anOrdinaryDay();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Still planned'), findsOneWidget);
      expect(find.text('Chicken traybake'), findsOneWidget);
    });

    testWidgets('shows the exercise that moved the day the other way',
        (tester) async {
      await anOrdinaryDay();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Exercise'), findsOneWidget);
      expect(find.text('+300 kcal'), findsOneWidget);
      expect(find.text('Measured'), findsOneWidget);
    });

    testWidgets('says where the person stands against their own target',
        (tester) async {
      await anOrdinaryDay();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      // 2400 target − 800 eaten + 300 from exercise.
      expect(find.text('1900 kcal left'), findsOneWidget);
      expect(find.text('Target 2400 kcal'), findsOneWidget);
      expect(find.text('800 kcal eaten'), findsOneWidget);
    });

    testWidgets('counts what is still to come separately from what is eaten',
        (tester) async {
      await anOrdinaryDay();
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      // The traybake has not been eaten, so it is not in the eaten figure —
      // it is named as still to come.
      expect(find.text('960 kcal still planned'), findsOneWidget);
      expect(find.text('800 kcal eaten'), findsOneWidget);
    });
  });

  group('it is this person\'s day and nobody else\'s', () {
    testWidgets('the other person\'s food is not on it', (tester) async {
      await anOrdinaryDay();
      await logger.logFood(
          day: today, label: 'Emily\'s pastry', kcal: 410, owner: mini.emily);
      await outbox.drain();

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Emily\'s pastry'), findsNothing);
      expect(find.text('800 kcal eaten'), findsOneWidget);
    });

    testWidgets('the target shown is this person\'s own', (tester) async {
      await anOrdinaryDay();
      await household.updateSettings(mini.emily, dailyTargetKcal: 1800);

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Target 2400 kcal'), findsOneWidget);
      expect(find.text('Target 1800 kcal'), findsNothing);
    });

    testWidgets('something the other person entered says so', (tester) async {
      await anOrdinaryDay();
      // Emily logs Aidan's pudding for him from her phone.
      await logger.logFood(
          day: today,
          label: 'Crumble',
          kcal: 380,
          owner: mini.aidan,
          author: mini.emily);
      await outbox.drain();

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Crumble'), findsOneWidget);
      expect(find.text('Entered by the other phone'), findsOneWidget);
    });
  });

  group('a day with nothing on it', () {
    testWidgets('says so rather than showing an empty screen', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Nothing logged yet today.'), findsOneWidget);
      expect(find.text('Nothing planned for today.'), findsOneWidget);
    });

    testWidgets('and does not invent a target', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('No daily target set yet.'), findsOneWidget);
      expect(find.textContaining('left'), findsNothing);
    });
  });

  group('honest gaps', () {
    testWidgets('a planned meal without numbers is named as such',
        (tester) async {
      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      mini.planMeal(
          day: today,
          title: 'Something from the freezer',
          forPeople: {mini.aidan: 1});

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Something from the freezer'), findsOneWidget);
      expect(find.text('Awaiting calories'), findsOneWidget);
      expect(
          find.text('One planned meal is still awaiting its calories.'),
          findsOneWidget,
          reason: 'a meal with no numbers must not quietly count as zero');
    });

    testWidgets('the remaining figure does not pretend the unknown is nothing',
        (tester) async {
      await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
      mini.planMeal(day: today, title: 'Freezer thing',
          forPeople: {mini.aidan: 1});

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      // The day still says what is left of the target — but it also says a
      // meal is unaccounted for, so the figure is not read as the whole story.
      expect(find.text('2400 kcal left'), findsOneWidget);
      expect(find.textContaining('awaiting its calories'), findsOneWidget);
    });
  });

  group('when the Mini cannot be reached', () {
    testWidgets('it says so instead of showing a day with nothing on it',
        (tester) async {
      await anOrdinaryDay();
      mini.reachable = false;

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.textContaining("Can't reach the kitchen computer"),
          findsOneWidget);
      // An empty day is a claim that this person ate nothing, and it is false.
      expect(find.text('Nothing logged yet today.'), findsNothing);
    });
  });

  group('with the figures switched off', () {
    testWidgets('the day is still a day, with no numbers on it',
        (tester) async {
      await anOrdinaryDay();
      await household.updateSettings(mini.aidan, figuresOff: true);

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Porridge and berries'), findsOneWidget);
      expect(find.text('Chicken traybake'), findsOneWidget);
      expect(find.textContaining('kcal'), findsNothing);
      expect(find.text('Your day is being counted.'), findsOneWidget);
    });

    testWidgets('planned is still marked as planned', (tester) async {
      await anOrdinaryDay();
      await household.updateSettings(mini.aidan, figuresOff: true);

      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.byType(PlannedMealRow), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
    });
  });
}
