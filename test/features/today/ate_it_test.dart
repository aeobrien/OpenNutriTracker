/// One tap to say you ate what was planned — and one to say you didn't.
///
/// Behaviour under test (Release B, TM-0010 and TM-0012): a planned meal on
/// Home carries two answers. "Ate it" puts it on this person's ledger with
/// their own portion of it. "Didn't have it" puts nothing anywhere. Either
/// answer takes the row off their day and neither touches the other person's.
///
/// What is proved here, and why each is worth a test:
///
///  * the buttons are on the row Home already shows, not on a screen of their
///    own — the whole release is about not building a second version of things;
///  * the row goes as soon as they tap, before the Mac Mini has heard, because
///    the answer is on the queue and being asked to confirm your dinner twice
///    is worse than a moment's optimism;
///  * a sleeping Mini loses nothing — the tap survives and lands on the ledger
///    when the queue next drains;
///  * "didn't have it" is a real answer and not just a dismissal, so nothing
///    appears on the day afterwards;
///  * and the figure that lands is this person's share, not the meal's.
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
import 'package:opennutritracker/features/today/presentation/planned_meals_section.dart';

import '../household/fake_household_server.dart';

void main() {
  const today = '2026-08-19';

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late DayRepository days;
  late int traybake;

  HouseholdApi api() => HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    logger = HouseholdLogger(household, outbox);
    days = DayRepository(api(), household);
    await household.setOwner(mini.aidan);
    traybake = mini.planMeal(
      day: today,
      title: 'Chicken traybake',
      mealKcal: 640,
      forPeople: {mini.aidan: 1.5, mini.emily: 0.5},
    );
  });

  tearDown(() async => db.close());

  Widget screen() => MaterialApp(
        home: Scaffold(
          body: PlannedMealsSection(
            repository: days,
            day: today,
            logger: logger,
          ),
        ),
      );

  /// What is on a person's ledger, as the Mini has it.
  List<Map<String, dynamic>> ledgerOf(int person) => mini.entries.values
      .where((e) => e['owner_id'] == person)
      .toList();

  group('the buttons are on the day Home already shows', () {
    testWidgets('a planned meal offers both answers', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      expect(find.text('Chicken traybake'), findsOneWidget);
      expect(find.text(PlannedMealRow.ateLabel), findsOneWidget);
      expect(find.text(PlannedMealRow.notEatenLabel), findsOneWidget);
    });

    testWidgets('a section with no way to answer shows no buttons',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: PlannedMealsSection(repository: days, day: today),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Chicken traybake'), findsOneWidget);
      expect(find.text(PlannedMealRow.ateLabel), findsNothing);
    });
  });

  group('ate it', () {
    testWidgets('puts the meal on this person\'s ledger', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();
      await outbox.drain();

      final mine = ledgerOf(mini.aidan);
      expect(mine, hasLength(1));
      expect(mine.first['label'], 'Chicken traybake');
    });

    testWidgets('with this person\'s share of it, not the meal\'s',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();
      await outbox.drain();

      // 640 a portion, and he is down for one and a half of them.
      expect(ledgerOf(mini.aidan).first['kcal'], 960);
      expect(ledgerOf(mini.aidan).first['qty'], 1.5);
    });

    testWidgets('and the row goes straight away, before the Mini has heard',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();

      // Nothing has been sent yet — the queue has not been drained.
      expect(mini.entries, isEmpty);
      expect(find.text('Chicken traybake'), findsNothing,
          reason: 'a meal they have answered must not keep asking');
    });

    testWidgets('it does not come back when the day is asked again',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();

      // Home reloads for all sorts of reasons before the queue drains.
      final section = tester.state<PlannedMealsSectionState>(
          find.byType(PlannedMealsSection));
      await section.reload();
      await tester.pumpAndSettle();

      expect(find.text('Chicken traybake'), findsNothing);
    });

    testWidgets('nothing lands on the other person\'s ledger', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();
      await outbox.drain();

      expect(ledgerOf(mini.emily), isEmpty);
    });

    testWidgets('and the other person still has it to decide', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();
      await outbox.drain();

      expect(mini.plannedFor(mini.emily, today), hasLength(1));
      expect(mini.decisionFor(traybake, mini.emily), isNull);
    });
  });

  group("didn't have it", () {
    testWidgets('takes it off the day', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.notEatenLabel));
      await tester.pumpAndSettle();

      expect(find.text('Chicken traybake'), findsNothing);
    });

    testWidgets('and puts nothing at all on the ledger', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.notEatenLabel));
      await tester.pumpAndSettle();
      await outbox.drain();

      expect(ledgerOf(mini.aidan), isEmpty);
      expect(mini.decisionFor(traybake, mini.aidan), 'skipped');
    });
  });

  group('a Mini that is asleep', () {
    testWidgets('does not lose the answer', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      mini.reachable = false;

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();
      expect(await outbox.pendingCount(), 1);

      mini.reachable = true;
      await outbox.drain();

      expect(ledgerOf(mini.aidan), hasLength(1));
      expect(await outbox.pendingCount(), 0);
    });

    testWidgets('and the row still goes, because the answer was given',
        (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();
      mini.reachable = false;

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();

      expect(find.text('Chicken traybake'), findsNothing);
    });
  });

  group('a phone that sends twice', () {
    testWidgets('still only eats it once', (tester) async {
      await tester.pumpWidget(screen());
      await tester.pumpAndSettle();

      await tester.tap(find.text(PlannedMealRow.ateLabel));
      await tester.pumpAndSettle();
      await outbox.drain();
      await outbox.drain();

      expect(ledgerOf(mini.aidan), hasLength(1));
    });
  });
}
