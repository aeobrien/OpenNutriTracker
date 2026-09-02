/// Two ways out of a part the house has no food for.
///
/// Behaviour under test: the part sheet on a meal's own screen offers only the
/// household's own foods, deliberately — a meal this house cooks is made of
/// things this house buys, and a figure is only as good as its worst part. On
/// 2 September 2026 that turned out to be a dead end: a built meal naming
/// something nobody here has ever bought had nowhere to go. Asked which way
/// out he wanted, Aidan said *"Can we have the option of either?"*
///
/// So there are two doors, and the point of these tests is that they are doors
/// in the wall rather than a hole in it. Both end by writing a food into the
/// household's own list, carrying an honest account of where its numbers came
/// from, and the part is then filled from that list exactly as before.
///
/// The carrying test is [looking one up online ends with the part filled in
/// from the household's own list]. The rest check one step each; only that one
/// checks the steps join, which is the whole claim.
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
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';
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
  late Outbox outbox;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(mini.aidan);
    await household.people();
    plan = PlanRepository(api, household);
    outbox = Outbox.of(db, api);
    GetIt.instance
      ..registerSingleton<FoodFinder>(
          FoodFinder(api, household, FoodItemDao(db)))
      ..registerSingleton<HouseholdLogger>(HouseholdLogger(household, outbox))
      ..registerSingleton<Outbox>(outbox)
      ..registerSingleton<ConfigRepository>(ConfigRepository(ConfigDao(db)));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await db.close();
  });

  /// A traybake whose vegetables nobody has named, in a house that has bought
  /// broccoli and has never in its life bought a romanesco.
  Future<PlannedMeal> aTraybakeMissingItsVegetables() async {
    mini.addFood(name: 'Tenderstem broccoli', kcal100: 35);
    final chicken = mini.addFood(name: 'Chicken thighs', kcal100: 177);
    mini.addMeal(name: 'Chicken traybake');
    mini.addMealPart(1, 'protein',
        foodName: 'Chicken thighs',
        qty: 500,
        unit: 'g',
        grams: 500,
        kcal: 885,
        trust: 'weighed',
        food: chicken);
    mini.addMealPart(1, 'vegetables',
        why: 'nobody has said what this is or how much of it goes in');
    final planId = mini.planMeal(
        day: mini.today, title: 'Chicken traybake', mealId: 1);
    return (await plan.week())
        .dayFor(mini.today)
        .planned
        .firstWhere((m) => m.planId == planId);
  }

  /// Open the meal, then the sheet for the part nobody has named.
  ///
  /// [figuresOff] mounts the same scope [MealScreen.show] mounts, because that
  /// is where the answer lives in the real app. [routes] is how the packet door
  /// gets somewhere to go — see its own test for why that is a stand-in.
  Future<void> openThePartSheet(
    WidgetTester tester, {
    bool figuresOff = false,
    Map<String, WidgetBuilder> routes = const {},
  }) async {
    final planned = await aTraybakeMissingItsVegetables();
    await tester.pumpWidget(MaterialApp(
      routes: routes,
      home: FiguresScope(
        figuresOff: figuresOff,
        child: MealScreen(
          repository: plan,
          mealId: 1,
          title: 'Chicken traybake',
          people: await household.cachedPeople(),
          planned: planned,
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('vegetables'));
    await tester.pumpAndSettle();
  }

  Future<void> lookFor(WidgetTester tester, String text) async {
    await tester.enterText(
        find.widgetWithText(TextField, MealScreen.whichFood), text);
    await tester.pumpAndSettle();
  }

  /// Press Save on the packet form.
  ///
  /// Scrolled to first. The form is nine fields tall and its button sits below
  /// the fold on a phone as well as in a test — a tap that lands on nothing
  /// looks exactly like a save that did nothing.
  Future<void> saveIt(WidgetTester tester) async {
    final button = find.text('Save to the household list');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  group('the dead end', () {
    testWidgets('a name the house knows offers no doors out', (tester) async {
      // The doors exist for the case where the house has nothing. Offering
      // them beside a perfectly good answer would be inviting somebody to
      // enter a second copy of a food already on the list.
      await openThePartSheet(tester);
      await lookFor(tester, 'broccoli');

      expect(find.text('Tenderstem broccoli'), findsOneWidget);
      expect(find.text(MealScreen.photographThePacket), findsNothing);
      expect(find.text(MealScreen.lookItUpOnline), findsNothing);
    });

    testWidgets('an empty box offers no doors out either', (tester) async {
      // There is nothing to photograph and nothing to look up until somebody
      // has said what they are after.
      await openThePartSheet(tester);

      expect(find.text(MealScreen.lookItUpOnline), findsNothing);
    });

    testWidgets('a name the house has never bought offers both doors',
        (tester) async {
      await openThePartSheet(tester);
      await lookFor(tester, 'romanesco');

      expect(find.textContaining('never bought that'), findsOneWidget);
      expect(find.text(MealScreen.photographThePacket), findsOneWidget);
      expect(find.text(MealScreen.lookItUpOnline), findsOneWidget);
    });
  });

  group('looking it up online', () {
    void theWebHas(
        {required String name, String? brand, num? kcal100, num? protein100}) {
      mini.webCandidates.add({
        'name': name,
        if (brand != null) 'brand': brand,
        if (kcal100 != null) 'kcal_100': kcal100,
        if (protein100 != null) 'protein_100': protein100,
      });
    }

    testWidgets('what comes back is shown as candidates, and asking saves '
        'nothing', (tester) async {
      theWebHas(name: 'Romanesco', brand: 'Waitrose', kcal100: 25);
      await openThePartSheet(tester);
      await lookFor(tester, 'romanesco');

      await tester.tap(find.text(MealScreen.lookItUpOnline));
      await tester.pumpAndSettle();

      expect(find.text('Waitrose Romanesco'), findsOneWidget);
      expect(find.text('25 kcal/100g'), findsOneWidget);
      expect(mini.huntedFor, 'romanesco');
      expect(mini.foods.length, 2,
          reason: 'looking something up wrote it into the household list '
              'before anybody had looked at its numbers');
    });

    testWidgets('a candidate carrying no calorie figure says nothing rather '
        'than zero', (tester) async {
      theWebHas(name: 'Romanesco');
      await openThePartSheet(tester);
      await lookFor(tester, 'romanesco');
      await tester.tap(find.text(MealScreen.lookItUpOnline));
      await tester.pumpAndSettle();

      expect(find.text('Romanesco'), findsOneWidget);
      expect(find.textContaining('0 kcal'), findsNothing);
    });

    testWidgets('picking one goes to the form a photographed label goes to',
        (tester) async {
      theWebHas(name: 'Romanesco', kcal100: 25);
      await openThePartSheet(tester);
      await lookFor(tester, 'romanesco');
      await tester.tap(find.text(MealScreen.lookItUpOnline));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Romanesco'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmFoodScreen), findsOneWidget,
          reason: 'a food reached this way skips the screen where a person '
              'checks the numbers before they are saved');
    });

    testWidgets('looking one up online ends with the part filled in from the '
        "household's own list", (tester) async {
      theWebHas(name: 'Romanesco', kcal100: 25);
      await openThePartSheet(tester);
      await lookFor(tester, 'romanesco');
      await tester.tap(find.text(MealScreen.lookItUpOnline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Romanesco'));
      await tester.pumpAndSettle();

      await saveIt(tester);

      // It is a household food now, and it says where its numbers came from.
      final written = mini.foods.values.firstWhere((f) => f['name'] == 'Romanesco');
      expect(written['trust'], 'web');

      // And it is back on the part sheet, pickable like anything else.
      expect(find.widgetWithText(TextField, MealScreen.whichFood),
          findsOneWidget);
      await tester.tap(find.text('Romanesco').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, MealScreen.howMuch), '150');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('150 g'), findsOneWidget);
      expect(find.textContaining('nobody has said what this is'), findsNothing,
          reason: 'the part was recorded and the screen still calls it a gap');
    });

    testWidgets('nothing coming back is said in words, not left blank',
        (tester) async {
      // Three different situations arrive here as an empty list — nothing
      // found, the Mini unreachable, the Mini too old to know how. They all
      // mean the same thing to the person holding the phone.
      mini.canHuntTheWeb = false;
      await openThePartSheet(tester);
      await lookFor(tester, 'romanesco');

      await tester.tap(find.text(MealScreen.lookItUpOnline));
      await tester.pumpAndSettle();

      expect(find.text(MealScreen.nothingOnTheWeb), findsOneWidget);
      expect(find.text(MealScreen.photographThePacket), findsOneWidget,
          reason: 'the other door was taken away when this one failed');
    });

    testWidgets('a food saved while the house cannot be reached says so '
        'rather than looking lost', (tester) async {
      // The food is written into this phone's queue and gets the id the house
      // knows it by only when the Mini accepts it. Saying "that did not work"
      // would be a lie about a food sitting in a queue perfectly intact.
      theWebHas(name: 'Romanesco', kcal100: 25);
      await openThePartSheet(tester);
      await lookFor(tester, 'romanesco');
      await tester.tap(find.text(MealScreen.lookItUpOnline));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Romanesco'));
      await tester.pumpAndSettle();

      mini.reachable = false;
      await saveIt(tester);

      expect(find.text(MealScreen.savedButNotSentYet), findsOneWidget);
      expect(await outbox.pendingCount(), greaterThan(0),
          reason: 'the food was neither sent nor kept');
    });
  });

  group('photographing the packet', () {
    /// What is and is not under test here.
    ///
    /// The real route behind this button opens a camera, reads a label with a
    /// model, and ends on the same form the web door ends on. None of that is
    /// this build's work and none of it runs in a test — so this stands in for
    /// it with a screen that writes a food the same way the real one does and
    /// pops, exactly as [GuidedCaptureScreen] does when somebody saves.
    ///
    /// What that leaves genuinely proved is the part that is mine: the button
    /// goes to the app's own label-capture route rather than somewhere
    /// invented, and whatever that route wrote is waiting on the part sheet
    /// when it comes back.
    Widget aScreenThatWritesAPacket(BuildContext context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              await GetIt.instance<HouseholdLogger>().addFood(
                name: 'Romanesco',
                trust: 'label',
                source: 'label_photo',
                kcal100: 25,
              );
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('pretend to photograph it'),
          ),
        );

    testWidgets('the packet door goes to the screen the app photographs labels '
        'with', (tester) async {
      await openThePartSheet(tester, routes: {
        NavigationOptions.labelCaptureRoute: aScreenThatWritesAPacket,
      });
      await lookFor(tester, 'romanesco');

      await tester.tap(find.text(MealScreen.photographThePacket));
      await tester.pumpAndSettle();

      expect(find.text('pretend to photograph it'), findsOneWidget,
          reason: 'the button went somewhere other than the route the app '
              'registers for photographing a label');
    });

    testWidgets('a packet photographed here ends with the part filled in',
        (tester) async {
      await openThePartSheet(tester, routes: {
        NavigationOptions.labelCaptureRoute: aScreenThatWritesAPacket,
      });
      await lookFor(tester, 'romanesco');
      await tester.tap(find.text(MealScreen.photographThePacket));
      await tester.pumpAndSettle();

      await tester.tap(find.text('pretend to photograph it'));
      await tester.pumpAndSettle();

      // Back on the part sheet, with the food the packet screen wrote.
      final written =
          mini.foods.values.firstWhere((f) => f['name'] == 'Romanesco');
      expect(written['trust'], 'label');
      expect(find.text(MealScreen.photographThePacket), findsNothing,
          reason: 'the doors are still open beside a food that now exists');

      await tester.tap(find.text('Romanesco').last);
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, MealScreen.howMuch), '150');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('150 g'), findsOneWidget);
    });
  });

  testWidgets('a candidate shows no calorie figure when figures are switched '
      'off', (tester) async {
    // Two sheets deep, on a surface added after the switch was built. A sheet
    // opens on the navigator's overlay rather than inside the screen that
    // opened it, so the answer has to be carried down by hand — and a figure
    // that keeps appearing to somebody who asked not to see them is exactly
    // what the switch exists to stop.
    mini.webCandidates.add({'name': 'Romanesco', 'kcal_100': 25});
    await openThePartSheet(tester, figuresOff: true);
    await lookFor(tester, 'romanesco');

    await tester.tap(find.text(MealScreen.lookItUpOnline));
    await tester.pumpAndSettle();

    expect(find.text('Romanesco'), findsOneWidget);
    expect(find.textContaining('kcal'), findsNothing);
  });
}
