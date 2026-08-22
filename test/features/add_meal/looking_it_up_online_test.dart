/// Naming a food and letting the app go looking — last, and marked as unchecked.
///
/// Behaviour under test — Release C, the third and least trusted of the three
/// ways to find a food. The other two are already built: the household's own
/// list first, the public database second. This is what happens when neither
/// had it.
///
/// Two things are held to throughout, and they are the reason this is a button
/// rather than something that runs on its own:
///
///  * **It goes last.** These numbers were read by a model off a shop's page
///    seconds ago. Putting them above a packet somebody in this house
///    photographed would put the least-checked figures in front of the
///    most-checked ones.
///  * **Nothing is saved by looking.** What comes back are drafts. A person
///    picks one and confirms it on the same screen a photographed label goes
///    through, and that screen stays the only place a food is written.
///
/// The third thing, which is really the first: a hunt that finds nothing, a
/// Mac Mini that is asleep, and a Mac Mini too old to know how
/// to look are all the same answer to the person holding the phone — no, and
/// you can still type it in yourself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/look_it_up_widget.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late FoodFinder finder;
  late Outbox outbox;
  late HouseholdLogger logger;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final theApi = api();
    household = HouseholdRepository(ConfigDao(db), theApi);
    finder = FoodFinder(theApi, household, FoodItemDao(db));
    outbox = Outbox.of(db, theApi);
    logger = HouseholdLogger(household, outbox);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Map<String, dynamic> candidate({
    String name = 'Butter Chicken Wrap',
    String? brand = 'Waitrose',
    String? barcode = '5000169123456',
    num? kcal100 = 217,
    num? protein100 = 8,
    num? fat100 = 9,
    num? carbs100 = 25,
    num? packGrams = 194,
    num? servingG = 194,
    String source = 'https://www.waitrose.com/a-wrap',
  }) =>
      {
        'name': name,
        'brand': brand,
        'barcode': barcode,
        'kcal_100': kcal100,
        'protein_100': protein100,
        'fat_100': fat100,
        'carbs_100': carbs100,
        'pack_grams': packGrams,
        'serving_g': servingG,
        'trust': 'web',
        'source': source,
      };

  /// The confirmation form is taller than a phone screen, so the button has to
  /// be brought into view before it can be pressed — the same as for a person.
  Future<void> saveIt(WidgetTester tester) async {
    final button = find.text('Save to the household list');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  Widget lookItUp(String searchText) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: LookItUpWidget(
                finder: finder, logger: logger, searchText: searchText),
          ),
        ),
      );

  group('what comes back from a hunt', () {
    test('it asks for what was typed, not something of its own', () async {
      mini.webCandidates = [candidate()];
      await finder.huntFor('  waitrose butter chicken wrap  ');
      expect(mini.huntedFor, 'waitrose butter chicken wrap');
    });

    test('every candidate is marked as having come off the web', () async {
      mini.webCandidates = [candidate()];
      final found = await finder.huntFor('wrap');
      expect(found.single.trust, 'web');
    });

    test('and says which page, not merely "the web"', () async {
      mini.webCandidates = [candidate()];
      final found = await finder.huntFor('wrap');
      expect(found.single.source, 'https://www.waitrose.com/a-wrap');
    });

    test('the numbers arrive intact', () async {
      mini.webCandidates = [candidate()];
      final found = await finder.huntFor('wrap');
      expect(found.single.name, 'Butter Chicken Wrap');
      expect(found.single.brand, 'Waitrose');
      expect(found.single.barcode, '5000169123456');
      expect(found.single.kcal100, 217);
      expect(found.single.protein100, 8);
      expect(found.single.packGrams, 194);
    });

    test('a figure the page never stated is empty and named as missing',
        () async {
      mini.webCandidates = [candidate(protein100: null, servingG: null)];
      final found = await finder.huntFor('wrap');
      expect(found.single.protein100, isNull);
      expect(found.single.unreadable, contains('protein_100'));
      expect(found.single.unreadable, contains('serving_g'));
      expect(found.single.unreadable, isNot(contains('kcal_100')));
    });

    test('a blank source is not passed off as a page', () async {
      mini.webCandidates = [candidate(source: '')];
      final found = await finder.huntFor('wrap');
      expect(found.single.source, 'web');
    });
  });

  group('a hunt that gives nothing back', () {
    test('finding nothing is an empty list, not a failure', () async {
      mini.webCandidates = [];
      expect(await finder.huntFor('something nobody sells'), isEmpty);
    });

    test('a Mac Mini too old to look answers the same way', () async {
      mini.canHuntTheWeb = false;
      mini.webCandidates = [candidate()];
      expect(await finder.huntFor('wrap'), isEmpty);
    });

    test('a sleeping Mac Mini answers the same way', () async {
      mini.reachable = false;
      expect(await finder.huntFor('wrap'), isEmpty);
    });

    test('asking for nothing does not go and ask at all', () async {
      expect(await finder.huntFor('   '), isEmpty);
      expect(mini.requests, isNot(contains('POST /household/food/find')));
    });
  });

  group('the button, and where it sits', () {
    testWidgets('nothing is offered until something has been typed',
        (tester) async {
      await tester.pumpWidget(lookItUp('   '));
      expect(find.text(LookItUpWidget.buttonLabel), findsNothing);
    });

    testWidgets('with a search in the box, the offer is there',
        (tester) async {
      await tester.pumpWidget(lookItUp('butter chicken wrap'));
      expect(find.text(LookItUpWidget.buttonLabel), findsOneWidget);
    });

    testWidgets('the hunt does not run until it is asked to', (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('butter chicken wrap'));
      await tester.pumpAndSettle();
      expect(mini.requests, isNot(contains('POST /household/food/find')),
          reason: 'a hunt that fired on its own would put a page reading '
              'above the two better lists');
    });

    testWidgets('pressing it shows what it found, said to be unchecked',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('butter chicken wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();

      expect(find.text('Butter Chicken Wrap'), findsOneWidget);
      expect(find.text(LookItUpWidget.shortlistLabel), findsOneWidget);
    });

    testWidgets('each row says the shop, the pack size and the calories',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();

      expect(find.text('Waitrose · 194g pack · 217 kcal per 100g'),
          findsOneWidget);
    });

    testWidgets('and no calorie figure at all for somebody who turned them off',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: FiguresScope(
            figuresOff: true,
            child: SingleChildScrollView(
              child: LookItUpWidget(
                  finder: finder, logger: logger, searchText: 'wrap'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();

      expect(find.text('Waitrose · 194g pack'), findsOneWidget);
      expect(find.textContaining('kcal'), findsNothing);
    });

    testWidgets('finding nothing says so plainly and leaves the way out open',
        (tester) async {
      mini.webCandidates = [];
      await tester.pumpWidget(lookItUp('something nobody sells'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();

      expect(find.text(LookItUpWidget.nothingFound), findsOneWidget);
    });

    testWidgets('a new search clears the last search\'s answers',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();
      expect(find.text('Butter Chicken Wrap'), findsOneWidget);

      await tester.pumpWidget(lookItUp('yoghurt'));
      await tester.pumpAndSettle();
      expect(find.text('Butter Chicken Wrap'), findsNothing);
    });
  });

  group('picking one', () {
    testWidgets('opens the same screen a photographed packet goes through',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Butter Chicken Wrap'));
      await tester.pumpAndSettle();

      expect(find.byType(ConfirmFoodScreen), findsOneWidget);
    });

    testWidgets('nothing is in the household list merely for having looked',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Butter Chicken Wrap'));
      await tester.pumpAndSettle();
      await outbox.drain();

      expect(mini.foods, isEmpty);
    });

    testWidgets('the screen says nobody here has checked these numbers',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Butter Chicken Wrap'));
      await tester.pumpAndSettle();

      expect(
          find.textContaining('Nobody here has checked them'), findsOneWidget);
    });

    testWidgets('a figure the page never stated is pointed at, in its own words',
        (tester) async {
      mini.webCandidates = [candidate(protein100: null)];
      await tester.pumpWidget(lookItUp('wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Butter Chicken Wrap'));
      await tester.pumpAndSettle();

      expect(find.text(ConfirmFoodScreen.pageDidNotSay), findsOneWidget);
      expect(find.text(ConfirmFoodScreen.couldNotRead), findsNothing,
          reason: 'nothing failed to be read — the page simply never said');
    });

    testWidgets('confirming it puts it in the list, still marked as web',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Butter Chicken Wrap'));
      await tester.pumpAndSettle();
      await saveIt(tester);
      await outbox.drain();

      final saved = mini.foods.values.single;
      expect(saved['name'], 'Butter Chicken Wrap');
      expect(saved['trust'], 'web');
      expect(saved['source'], 'https://www.waitrose.com/a-wrap');
    });

    testWidgets('correcting a figure records it as typed in, not as web',
        (tester) async {
      mini.webCandidates = [candidate()];
      await tester.pumpWidget(lookItUp('wrap'));
      await tester.tap(find.text(LookItUpWidget.buttonLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Butter Chicken Wrap'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Calories per 100g').first, '230');
      await tester.pumpAndSettle();
      await saveIt(tester);
      await outbox.drain();

      final saved = mini.foods.values.single;
      expect(saved['trust'], 'typed');
      expect(saved['kcal_100'], 230);
      expect(saved['source'], 'https://www.waitrose.com/a-wrap',
          reason: 'the page still happened — correcting it does not unhappen');
    });
  });

  group('what a draft made from a page keeps', () {
    test('a candidate with no name at all still makes a draft to be fixed', () {
      final draft = FoodDraft.fromWebCandidate({'name': null});
      expect(draft.name, '');
      expect(draft.isSaveable, isFalse);
    });

    test('a food with no calories on it says so rather than reading zero', () {
      final draft = FoodDraft.fromWebCandidate(candidate(kcal100: null));
      expect(draft.kcal100, isNull);
      expect(draft.hasNoNumbers, isTrue);
    });
  });
}
