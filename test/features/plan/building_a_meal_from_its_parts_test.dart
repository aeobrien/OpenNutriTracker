/// Building a meal out of its parts, from the phone.
///
/// Behaviour under test (Release 6, TM-0020 / BC-0021). This household cooks
/// by assembling: something to cook, a way of cooking it, some vegetables,
/// something starchy. The kitchen panel has recorded meals that way for months
/// and has been learning the combinations. A phone could not, and the phone is
/// what somebody is holding when they decide what Tuesday is.
///
/// The carrying test is [the lists are what this house has cooked]. Four
/// dropdowns are only faster than typing a name because the lists are short,
/// and they are short because they are drawn from habit. A builder that offers
/// everything is a search box with more steps, and there would be no reason to
/// have built it.
///
/// What this does not prove: that the ordering itself is right. The narrowing
/// is the Mac Mini's, out of its own pairing graph, and the tests that hold it
/// to that are on the Mini in test_building_a_meal.py. The fake here answers
/// in the same shape so the screen can be held to what it does with the
/// answer.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/domain/plan_week.dart';
import 'package:opennutritracker/features/plan/presentation/meal_builder.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late PlanRepository plan;
  MealChoice? built;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    final household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(mini.aidan);
    await household.people();
    plan = PlanRepository(api, household);
    built = null;
  });

  tearDown(() async => db.close());

  /// What this house has cooked before.
  void habits() {
    mini.hasCooked('chicken thighs', 'roast',
        veg: ['tenderstem broccoli'], carb: 'new potatoes');
    mini.hasCooked('chicken thighs', 'teriyaki', veg: ['pak choi']);
    mini.hasCooked('salmon', 'baked', veg: ['asparagus'], carb: 'new potatoes');
  }

  Future<void> openIt(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                built = await MealBuilder.show(context, repository: plan),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> choose(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilterChip, label));
    await tester.pumpAndSettle();
  }

  group('nothing arrives chosen', () {
    /// Aidan, 23 August 2026, asked whether the builder should start with the
    /// most likely parts already ticked:
    ///
    /// > "No default, I do it manually - the learning system is unproven."
    ///
    /// So the pairing graph orders what is offered and decides nothing. The
    /// distinction matters and is the reason these tests do not check the
    /// order: a list put in a helpful order is the graph making a suggestion,
    /// which he did not object to; a part arriving ticked is the graph making
    /// the choice, which he did.
    List<FilterChip> chips(WidgetTester tester) =>
        tester.widgetList<FilterChip>(find.byType(FilterChip)).toList();

    testWidgets('the builder opens with nothing ticked', (tester) async {
      habits();

      await openIt(tester);

      expect(chips(tester), isNotEmpty, reason: 'there is something to tick');
      expect(chips(tester).where((c) => c.selected), isEmpty);
    });

    testWidgets('choosing what to cook does not tick anything under it',
        (tester) async {
      // The Mini answers with the parts that have gone with roast chicken
      // before, best first. Best first is a suggestion; ticked is a decision.
      habits();
      await openIt(tester);

      await choose(tester, 'chicken thighs');
      await choose(tester, 'roast');

      final ticked =
          chips(tester).where((c) => c.selected).map((c) => c.label).toList();
      expect(ticked.length, 2,
          reason: 'only the two parts actually tapped are chosen');
      expect(find.widgetWithText(FilterChip, 'tenderstem broccoli'),
          findsOneWidget);
      expect(
          tester
              .widget<FilterChip>(
                  find.widgetWithText(FilterChip, 'tenderstem broccoli'))
              .selected,
          isFalse,
          reason: 'the only vegetable this house has had with roast chicken '
              'is still not chosen for him');
      expect(
          tester
              .widget<FilterChip>(
                  find.widgetWithText(FilterChip, 'new potatoes'))
              .selected,
          isFalse);
    });

    testWidgets('a meal built without touching the parts below has none',
        (tester) async {
      // If anything were quietly pre-filled, this is where it would show: the
      // meal would arrive with a vegetable nobody chose.
      habits();
      await openIt(tester);
      await choose(tester, 'chicken thighs');
      await choose(tester, 'roast');

      await tester.tap(find.text(MealBuilder.buildIt));
      await tester.pumpAndSettle();

      expect(mini.built.single['veg'], isEmpty);
      expect(mini.built.single['carb'], '');
    });
  });

  group('what it offers', () {
    testWidgets('the lists are what this house has cooked', (tester) async {
      // The carrying test. Short lists drawn from habit are the only thing a
      // builder has over typing the meal's name.
      habits();
      await openIt(tester);
      await choose(tester, 'chicken thighs');
      await choose(tester, 'roast');

      expect(find.widgetWithText(FilterChip, 'tenderstem broccoli'),
          findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'new potatoes'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'pak choi'), findsNothing,
          reason: 'what goes with teriyaki chicken is offered for roast '
              'chicken, so the lists are a catalogue and not a habit');
      expect(find.widgetWithText(FilterChip, 'asparagus'), findsNothing);
    });

    testWidgets('nothing below is asked until there is something to cook',
        (tester) async {
      // What goes with roast chicken is not a question until the chicken is
      // chosen, and four empty lists at once is four things to ignore.
      habits();
      await openIt(tester);

      expect(find.text(MealBuilder.proteinHeading), findsOneWidget);
      expect(find.text(MealBuilder.vegHeading), findsNothing);
      await choose(tester, 'salmon');
      expect(find.text(MealBuilder.vegHeading), findsOneWidget);
    });

    testWidgets('a part with nothing in it invites one rather than sitting empty',
        (tester) async {
      // An empty list reads as broken. An invitation reads as a beginning, and
      // every option in every list here was typed into that box once.
      mini.hasCooked('ostrich', 'roast');
      await openIt(tester);
      await choose(tester, 'ostrich');

      expect(find.text(MealBuilder.nothingYet), findsWidgets);
      expect(find.widgetWithText(TextField, MealBuilder.typeOne), findsWidgets);
    });

    testWidgets('choosing a different thing to cook clears what was under it',
        (tester) async {
      // Roast chicken's broccoli left sitting under baked salmon is somebody
      // else's habit wearing a tick.
      habits();
      await openIt(tester);
      await choose(tester, 'chicken thighs');
      await choose(tester, 'roast');
      await choose(tester, 'tenderstem broccoli');
      await choose(tester, 'salmon');

      expect(find.widgetWithText(FilterChip, 'tenderstem broccoli'),
          findsNothing);
      // Salmon's own habits, once it is said how it is being cooked. What goes
      // with roast chicken has gone; what goes with baked salmon is offered.
      await choose(tester, 'baked');
      expect(find.widgetWithText(FilterChip, 'asparagus'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'tenderstem broccoli'),
          findsNothing);
    });
  });

  group('what it builds', () {
    testWidgets('a meal is built from what was chosen', (tester) async {
      habits();
      await openIt(tester);
      await choose(tester, 'chicken thighs');
      await choose(tester, 'roast');
      await choose(tester, 'tenderstem broccoli');
      await choose(tester, 'new potatoes');
      await tester.tap(find.text(MealBuilder.buildIt));
      await tester.pumpAndSettle();

      expect(mini.built.single['protein'],
          {'name': 'chicken thighs', 'prep': 'roast'});
      expect(mini.built.single['veg'], ['tenderstem broccoli']);
      expect(mini.built.single['carb'], 'new potatoes');
      expect(built?.name,
          'roast chicken thighs with tenderstem broccoli and new potatoes');
    });

    testWidgets('a part this house has never had can be typed in',
        (tester) async {
      // Not a fallback for a short list — this is how anything gets into the
      // house's habits at all.
      await openIt(tester);
      await tester.enterText(
          find.widgetWithText(TextField, MealBuilder.typeOne).first, 'venison');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(find.text(MealBuilder.buildIt));
      await tester.pumpAndSettle();

      expect(mini.built.single['protein'], {'name': 'venison', 'prep': ''});
    });

    testWidgets('something typed in is visible as chosen', (tester) async {
      // Otherwise it is chosen and invisible at the same time, and the only
      // way to check what is about to be built is to build it.
      await openIt(tester);
      await tester.enterText(
          find.widgetWithText(TextField, MealBuilder.typeOne).first, 'venison');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      final chip = tester.widget<FilterChip>(
          find.widgetWithText(FilterChip, 'venison'));
      expect(chip.selected, isTrue);
    });

    testWidgets('nothing is built until there is something to cook',
        (tester) async {
      habits();
      await openIt(tester);

      final before =
          tester.widget<FilledButton>(find.widgetWithText(FilledButton,
              MealBuilder.buildIt));
      expect(before.onPressed, isNull,
          reason: 'a meal of nothing can be built, and it would be named '
              'after nothing');
      await choose(tester, 'salmon');
      final after = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, MealBuilder.buildIt));
      expect(after.onPressed, isNotNull);
    });

    testWidgets('a meal is only its protein, and that is a real meal',
        (tester) async {
      habits();
      await openIt(tester);
      await choose(tester, 'salmon');
      await tester.tap(find.text(MealBuilder.buildIt));
      await tester.pumpAndSettle();

      expect(mini.built.single['veg'], isEmpty);
      expect(mini.built.single['carb'], '');
      expect(built?.name, 'salmon');
    });

    testWidgets('a third vegetable is refused out loud', (tester) async {
      // The house's meals hold two. Silently dropping the third would make the
      // built meal differ from the screen somebody was looking at.
      mini.hasCooked('chicken thighs', 'roast',
          veg: ['broccoli', 'carrots'], carb: 'rice');
      mini.hasCooked('chicken thighs', '', veg: ['peas']);
      await openIt(tester);
      await choose(tester, 'chicken thighs');
      await choose(tester, 'roast');
      await choose(tester, 'broccoli');
      await choose(tester, 'carrots');
      await choose(tester, 'peas');

      expect(find.text(MealBuilder.twoIsTheLimit), findsOneWidget);
      final peas =
          tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'peas'));
      expect(peas.selected, isFalse);
    });

    testWidgets('backing out builds nothing', (tester) async {
      habits();
      await openIt(tester);
      await choose(tester, 'salmon');
      await tester.tap(find.text(MealBuilder.skipIt));
      await tester.pumpAndSettle();

      expect(mini.built, isEmpty);
      expect(built, isNull);
    });

    testWidgets('a Mini that cannot be reached says so and keeps the choices',
        (tester) async {
      // The choices are the work. Losing them to a network error means doing
      // it all again, which is what makes somebody stop using the builder.
      habits();
      await openIt(tester);
      await choose(tester, 'salmon');
      await choose(tester, 'baked');
      mini.reachable = false;
      await tester.tap(find.text(MealBuilder.buildIt));
      await tester.pumpAndSettle();

      expect(find.textContaining('that meal was not made'), findsOneWidget);
      final salmon =
          tester.widget<FilterChip>(find.widgetWithText(FilterChip, 'salmon'));
      expect(salmon.selected, isTrue);
      expect(built, isNull);
    });
  });
}
