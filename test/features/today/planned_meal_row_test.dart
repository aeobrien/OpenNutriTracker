/// Planned is not eaten, and it has to look it.
///
/// Behaviour under test (Release 1, promise 7): a meal that was planned for
/// today sits on the day waiting, shown in a lighter style so planned and eaten
/// are never confused.
///
/// Two things are proved here and neither is "the row has a field on it".
///
/// The first is that the difference is *observable* — on a day holding both
/// kinds of row, the planned one says the word Planned, is drawn faded, and the
/// eaten one is neither. A row that carried an `isPlanned` flag and rendered
/// identically would pass a field check and fail every test in the first group.
///
/// The second is that the portion on the row is **this person's own**. The plan
/// holds one traybake for the household; Aidan is down for one and a half
/// portions of it and Emily for half. Each phone must show its own holder's
/// share, and the calorie figure that follows from it — an implementation that
/// showed the meal's standard portion would give both of them the same wrong
/// number and look perfectly reasonable doing it.
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

import 'package:opennutritracker/features/today/domain/day_view.dart';

import '../household/fake_household_server.dart';

/// A few planned meals with nothing behind them, for the tests that look at the
/// row alone rather than at a whole day.
class PlannedItemStub {
  static const traybake = PlannedItem(
      planId: 1,
      title: 'Chicken traybake',
      portions: 1.5,
      kcal: 960,
      mealKcalKnown: true);
  static const one = PlannedItem(
      planId: 2, title: 'Soup', portions: 1, kcal: 300, mealKcalKnown: true);
  static const unset =
      PlannedItem(planId: 3, title: 'Chilli', mealKcalKnown: true);
  static const noNumbers =
      PlannedItem(planId: 4, title: 'Freezer thing', portions: 1);
}

void main() {
  const today = '2026-08-19';

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late DayRepository days;

  HouseholdApi api() => HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    logger = HouseholdLogger(household, outbox);
    days = DayRepository(api(), household);
    await household.setOwner(mini.aidan);
    await household.updateSettings(mini.aidan, dailyTargetKcal: 2400);
  });

  tearDown(() async => db.close());

  Widget screen(DayRepository repository) => MaterialApp(
        home: Scaffold(body: TodayScreen(repository: repository, day: today)),
      );

  /// The household's traybake, with the two of them down for different amounts.
  void planTheTraybake() => mini.planMeal(
        day: today,
        title: 'Chicken traybake',
        mealKcal: 640,
        forPeople: {mini.aidan: 1.5, mini.emily: 0.5},
      );

  /// True when [text] is drawn inside a faded planned row.
  bool isFaded(WidgetTester tester, String text) {
    final fades = tester.widgetList<Opacity>(find.ancestor(
      of: find.text(text),
      matching: find.byType(Opacity),
    ));
    return fades.any((o) => o.opacity == PlannedMealRow.plannedOpacity);
  }

  group('on a day holding both kinds', () {
    setUp(() async {
      await logger.logFood(day: today, label: 'Cheese sandwich', kcal: 480);
      await outbox.drain();
      planTheTraybake();
    });

    testWidgets('the planned meal says it is planned', (tester) async {
      await tester.pumpWidget(screen(days));
      await tester.pumpAndSettle();

      expect(find.text('Chicken traybake'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
    });

    testWidgets('and the eaten one does not', (tester) async {
      await tester.pumpWidget(screen(days));
      await tester.pumpAndSettle();

      final sandwichRow = find.ancestor(
        of: find.text('Cheese sandwich'),
        matching: find.byType(Card),
      );
      expect(sandwichRow, findsOneWidget);
      expect(
          find.descendant(of: sandwichRow, matching: find.text('Planned')),
          findsNothing);
    });

    testWidgets('the planned one is drawn faded and the eaten one is not',
        (tester) async {
      await tester.pumpWidget(screen(days));
      await tester.pumpAndSettle();

      expect(isFaded(tester, 'Chicken traybake'), isTrue);
      expect(isFaded(tester, 'Cheese sandwich'), isFalse,
          reason: 'something already eaten must not be dimmed like a thing '
              'still to come');
    });

    testWidgets('planned meals sit below what has been eaten', (tester) async {
      await tester.pumpWidget(screen(days));
      await tester.pumpAndSettle();

      final eaten = tester.getTopLeft(find.text('Cheese sandwich')).dy;
      final planned = tester.getTopLeft(find.text('Chicken traybake')).dy;
      expect(planned, greaterThan(eaten));
    });

    testWidgets('a planned meal is not counted as eaten', (tester) async {
      await tester.pumpWidget(screen(days));
      await tester.pumpAndSettle();

      expect(find.text('480 kcal eaten'), findsOneWidget);
      expect(find.text('960 kcal still planned'), findsOneWidget);
    });
  });

  group('the portion is this person\'s own', () {
    testWidgets('the holder sees their own share of the meal', (tester) async {
      planTheTraybake();
      await tester.pumpWidget(screen(days));
      await tester.pumpAndSettle();

      expect(find.text('Your portion: 1.5 portions'), findsOneWidget);
      expect(find.text('960 kcal'), findsOneWidget,
          reason: '1.5 portions of a 640 kcal meal');
    });

    testWidgets('the other person\'s phone shows theirs, not his',
        (tester) async {
      planTheTraybake();
      final emilysStore = AppDatabase.createInMemory();
      addTearDown(() async => emilysStore.close());
      final emilys = HouseholdRepository(ConfigDao(emilysStore), api());
      await emilys.setOwner(mini.emily);

      await tester.pumpWidget(screen(DayRepository(api(), emilys)));
      await tester.pumpAndSettle();

      expect(find.text('Your portion: 0.5 portions'), findsOneWidget);
      expect(find.text('320 kcal'), findsOneWidget,
          reason: 'half a portion of the same 640 kcal meal');
      expect(find.text('960 kcal'), findsNothing);
    });

    testWidgets('one portion reads as one portion, not 1.0', (tester) async {
      mini.planMeal(
          day: today, title: 'Soup', mealKcal: 300, forPeople: {mini.aidan: 1});
      await tester.pumpWidget(screen(days));
      await tester.pumpAndSettle();

      expect(find.text('Your portion: 1 portion'), findsOneWidget);
    });

    testWidgets('a portion nobody has set says so rather than guessing one',
        (tester) async {
      mini.planMeal(day: today, title: 'Chilli', mealKcal: 500);

      await tester.pumpWidget(screen(days));
      await tester.pumpAndSettle();

      expect(find.text('Portion not set'), findsOneWidget);
      expect(find.text('Awaiting a portion'), findsOneWidget);
      // A guessed "one portion" here would be a 500 kcal claim about somebody's
      // day that nobody made.
      expect(find.text('500 kcal'), findsNothing);
      expect(find.textContaining('still planned'), findsNothing);
    });
  });

  group('the row on its own', () {
    testWidgets('shows the meal, the portion and the figure', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: PlannedMealRow(
            item: PlannedItemStub.traybake,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chicken traybake'), findsOneWidget);
      expect(find.text('Your portion: 1.5 portions'), findsOneWidget);
      expect(find.text('960 kcal'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
    });

    test('the portion wording covers the cases the day actually produces', () {
      expect(PlannedMealRow.portionText(PlannedItemStub.traybake),
          'Your portion: 1.5 portions');
      expect(PlannedMealRow.portionText(PlannedItemStub.one),
          'Your portion: 1 portion');
      expect(PlannedMealRow.portionText(PlannedItemStub.unset),
          'Portion not set');
    });

    test('the gap wording says which thing is missing', () {
      expect(PlannedMealRow.gapText(PlannedItemStub.traybake), isNull);
      expect(PlannedMealRow.gapText(PlannedItemStub.unset),
          'Awaiting a portion');
      expect(PlannedMealRow.gapText(PlannedItemStub.noNumbers),
          'Awaiting calories');
    });
  });
}
