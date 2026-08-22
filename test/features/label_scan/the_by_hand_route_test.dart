/// Typing a packet in by hand, driven the way the app builds it.
///
/// Aidan walked this on 22 August and it failed, in his words: *"After I have
/// saved to the household list and then added to today, I'm still in the add a
/// food by hand window. Because I'm still in that it looks like nothing has
/// been saved."* And: *"even though I tapped the button saying to add it to
/// today, it has not been added to today."*
///
/// Three separate faults, and every one of them lived in the gap between the
/// form and the route that hosts it:
///
///   * the route never closed the form on a successful save, so the boxes he
///     had just filled were still in front of him;
///   * the offer was a strip along the bottom that takes itself away after ten
///     seconds, so by the time he had read the form and looked up it was gone;
///   * nothing put him back where he started, whichever way he answered.
///
/// The reason none of it was caught is the reason this file exists. Every test
/// of the form built the form directly and handed it a stand-in for the offer,
/// so they proved a callback fired and nothing about what a person is looking
/// at afterwards. This file pushes the route the app registers, onto a screen
/// he started from, and reads the answer off the screen.
///
/// The carrying test is [answering it either way puts the form away]. A modal
/// that is dismissed but leaves him back on the finished form has fixed the
/// question and not the complaint.
///
/// **What this file stops short of.** Saying yes opens the amount screen; the
/// food reaches the day when Add is pressed there, which is deliberate — a
/// packet says what is in a hundred grams, not how much of it somebody ate. So
/// the last leg is watched on the phone, not here. What is proved here is that
/// the amount screen is reached, carrying the food he just typed in.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/repository/config_repository.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/label_scan/presentation/add_food_by_hand.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';
import 'package:opennutritracker/features/meal_detail/meal_detail_screen.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdApi api;
  late HouseholdRepository household;

  /// What arrived at the amount screen, if anything did.
  MealDetailScreenArguments? reachedTheAmountScreen;

  const whereHeStarted = 'Where he started';

  /// The button on the screen he started from. Deliberately not the words the
  /// form's own title uses, so a finder for one can never quietly match the
  /// other.
  const theWayIn = 'Type a packet in';

  /// What the form calls itself once it is open.
  const theFormsTitle = 'Add a food by hand';

  setUp(() async {
    reachedTheAmountScreen = null;
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(mini.aidan);
    final outbox = Outbox.of(db, api);
    // Everything the route reaches for out of the locator. The route asks for
    // its logger; the offer it hands on asks for the other three.
    GetIt.instance
      ..registerSingleton<HouseholdLogger>(HouseholdLogger(household, outbox))
      ..registerSingleton<Outbox>(outbox)
      ..registerSingleton<FoodFinder>(FoodFinder(api, household, FoodItemDao(db)))
      ..registerSingleton<ConfigRepository>(ConfigRepository(ConfigDao(db)));
  });

  tearDown(() async {
    await GetIt.instance.reset();
    await db.close();
  });

  /// The app as he meets it: a screen he started from, and the route the app
  /// registers pushed on top of it by name.
  ///
  /// The amount screen is stood in for rather than built. It is a screen of its
  /// own with its own tests, and the question here is only whether it is
  /// reached and what it is handed.
  Widget theApp() => MaterialApp(
        routes: {
          NavigationOptions.addFoodByHandRoute: addFoodByHandScreen,
          NavigationOptions.mealDetailRoute: (context) {
            reachedTheAmountScreen = ModalRoute.of(context)!.settings.arguments
                as MealDetailScreenArguments;
            return const Scaffold(body: Text('The amount screen'));
          },
        },
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(whereHeStarted),
                  FilledButton(
                    onPressed: () => Navigator.of(context)
                        .pushNamed(NavigationOptions.addFoodByHandRoute),
                    child: const Text(theWayIn),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// A phone-shaped surface tall enough that the whole form is built. Nine
  /// fields and a button do not fit the 800x600 the test binding hands out,
  /// and a button that was never laid out cannot be pressed.
  void giveTheScreenRoom(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> openTheForm(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, theWayIn));
    await tester.pumpAndSettle();
  }

  Future<void> type(WidgetTester tester, String label, String value) async {
    await tester.enterText(find.widgetWithText(TextField, label).first, value);
    await tester.pumpAndSettle();
  }

  /// Fill it in and press Save, the way somebody standing at a cupboard does.
  Future<void> fillItInAndSave(WidgetTester tester,
      {String name = 'Fish cakes'}) async {
    await type(tester, 'Name', name);
    await type(tester, 'Calories per 100g', '200');
    await type(tester, 'What the whole pack weighs in grams', '400');
    await type(tester, 'How many are in a pack', '6');
    await tester.ensureVisible(find.text('Save to the household list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to the household list'));
    await tester.pumpAndSettle();
  }

  group('what he is looking at after he presses Save', () {
    testWidgets('the question is asked as a question, in front of him',
        (tester) async {
      giveTheScreenRoom(tester);
      await tester.pumpWidget(theApp());
      await openTheForm(tester);
      await fillItInAndSave(tester);

      // A strip along the bottom takes itself away while somebody is reading
      // the form. A modal waits.
      expect(
        find.widgetWithText(
            AlertDialog, ConfirmFoodScreen.putItOnTodayQuestion('Fish cakes')),
        findsOneWidget,
      );
      expect(find.text(ConfirmFoodScreen.putItOnToday), findsOneWidget);
      expect(find.text(ConfirmFoodScreen.notNow), findsOneWidget,
          reason: 'a question with only one answer is not a question');
    });

    testWidgets('answering it either way puts the form away', (tester) async {
      for (final answer in const [
        ConfirmFoodScreen.notNow,
        ConfirmFoodScreen.putItOnToday
      ]) {
        giveTheScreenRoom(tester);
        await tester.pumpWidget(theApp());
        await openTheForm(tester);
        await fillItInAndSave(tester, name: 'Fish cakes $answer');
        await tester.tap(find.text(answer));
        await tester.pumpAndSettle();

        expect(find.widgetWithText(AppBar, theFormsTitle), findsNothing,
            reason: 'answering "$answer" left him on the form he had just '
                'filled in — which is what he read as the save having failed');
        expect(find.widgetWithText(TextField, 'Name'), findsNothing,
            reason: 'the boxes he filled in are still in front of him');
      }
    });

    testWidgets('saying no leaves him where he started, with nothing added',
        (tester) async {
      giveTheScreenRoom(tester);
      await tester.pumpWidget(theApp());
      await openTheForm(tester);
      await fillItInAndSave(tester);
      await tester.tap(find.text(ConfirmFoodScreen.notNow));
      await tester.pumpAndSettle();

      expect(find.text(whereHeStarted), findsOneWidget);
      expect(reachedTheAmountScreen, isNull,
          reason: 'declining today still opened the amount screen');
      // Declining today is not declining the food. It is in the list either
      // way — waiting on the queue, which nothing has emptied yet because
      // nothing asked the house a question.
      await GetIt.instance<Outbox>().drain();
      expect(mini.foods.values.single['name'], 'Fish cakes');
    });

    testWidgets('saying yes opens the amount screen on the food he just typed',
        (tester) async {
      giveTheScreenRoom(tester);
      await tester.pumpWidget(theApp());
      await openTheForm(tester);
      await fillItInAndSave(tester);
      await tester.tap(find.text(ConfirmFoodScreen.putItOnToday));
      await tester.pumpAndSettle();

      expect(reachedTheAmountScreen, isNotNull,
          reason: 'he tapped the button that says it goes on today and '
              'nothing opened');
      expect(reachedTheAmountScreen!.mealEntity.name, 'Fish cakes');
      expect(find.text('The amount screen'), findsOneWidget);
      // And not stacked on top of the finished form: closing the amount screen
      // has to land him somewhere he can use.
      expect(find.widgetWithText(AppBar, theFormsTitle), findsNothing);
    });
  });
}
