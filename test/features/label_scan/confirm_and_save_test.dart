/// Getting a food into the household list — including on the days the camera
/// does not help.
///
/// Behaviour under test (Release 1, promise 13): a food and its numbers can be
/// got into the household list from day one, by hand if necessary, so that
/// filling the database in as you go is actually possible rather than a promise
/// with nowhere to land.
///
/// The test that carries the item is [a food can be typed in when the
/// photographs cannot be read]. Aidan chose to fill the list in as he goes on
/// the understanding that photographing a packet would make it quick; the
/// reading will sometimes fail, and on those days he still has to be able to
/// put the packet in. So the hand-typed route is not a fallback branch of the
/// photograph route — it is the same screen, opened empty, saving through the
/// same call. A version that only saved when the extraction succeeded would
/// pass every other test here.
///
/// The other thing held to is honesty about where numbers came from. Accepting
/// what a photograph said records the food as read off a photograph; changing
/// anything records it as typed in. The list has to keep saying which, long
/// after everybody has forgotten.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/label_scan/data/household_label_reader.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late HouseholdApi api;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    logger = HouseholdLogger(household, outbox);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Widget confirm({FoodDraft? draft}) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConfirmFoodScreen(logger: logger, draft: draft),
          ),
        ),
      );

  Future<void> type(WidgetTester tester, String label, String value) async {
    await tester.enterText(
        find.widgetWithText(TextField, label).first, value);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save to the household list'));
    await tester.pumpAndSettle();
    await outbox.drain();
  }

  Map<String, dynamic> theSavedFood() => mini.foods.values.single;

  const readFromAPacket = FoodDraft(
    name: 'Oat Crunch',
    brand: 'Store own',
    kcal100: 412,
    protein100: 9.4,
    fat100: 14.2,
    carbs100: 60.1,
    servingG: 45,
    trust: 'photo',
    source: 'photo',
  );

  group('accepting what the photographs said', () {
    testWidgets('opens filled in', (tester) async {
      await tester.pumpWidget(confirm(draft: readFromAPacket));
      await tester.pumpAndSettle();

      expect(find.text('Oat Crunch'), findsOneWidget);
      expect(find.text('412'), findsOneWidget);
      expect(find.text('These numbers came off the photographs.'),
          findsOneWidget);
    });

    testWidgets('saves the food with its numbers', (tester) async {
      await tester.pumpWidget(confirm(draft: readFromAPacket));
      await tester.pumpAndSettle();
      await save(tester);

      final saved = theSavedFood();
      expect(saved['name'], 'Oat Crunch');
      expect(saved['kcal_100'], 412);
      expect(saved['protein_100'], 9.4);
      expect(saved['serving_g'], 45);
    });

    testWidgets('and records that a photograph is where they came from',
        (tester) async {
      await tester.pumpWidget(confirm(draft: readFromAPacket));
      await tester.pumpAndSettle();
      await save(tester);

      expect(theSavedFood()['trust'], 'photo');
      expect(theSavedFood()['source'], 'photo');
    });

    testWidgets('nothing is saved until Save is pressed', (tester) async {
      await tester.pumpWidget(confirm(draft: readFromAPacket));
      await tester.pumpAndSettle();
      await outbox.drain();

      expect(mini.foods, isEmpty);
    });
  });

  group('correcting what the photographs said', () {
    testWidgets('a changed figure is what gets saved', (tester) async {
      await tester.pumpWidget(confirm(draft: readFromAPacket));
      await tester.pumpAndSettle();

      await type(tester, 'Calories per 100g', '389');
      await save(tester);

      expect(theSavedFood()['kcal_100'], 389);
    });

    testWidgets('and the food is recorded as typed in, not photographed',
        (tester) async {
      await tester.pumpWidget(confirm(draft: readFromAPacket));
      await tester.pumpAndSettle();

      await type(tester, 'Calories per 100g', '389');
      await save(tester);

      expect(theSavedFood()['trust'], 'typed',
          reason: 'a corrected figure is a figure a person stands behind, and '
              'the list has to keep saying so');
      expect(theSavedFood()['source'], 'photo',
          reason: 'the photograph still happened — which is worth knowing '
              'later, when asking how well the reading actually works');
    });

    testWidgets('the screen says so before it is saved', (tester) async {
      await tester.pumpWidget(confirm(draft: readFromAPacket));
      await tester.pumpAndSettle();

      await type(tester, 'Calories per 100g', '389');

      expect(
          find.text(
              'You corrected these, so they are recorded as typed in.'),
          findsOneWidget);
    });
  });

  group('when the photographs cannot be read', () {
    testWidgets('a food can be typed in when the photographs cannot be read',
        (tester) async {
      // The reading fails — the panel was creased, the light was bad, the model
      // had nothing. This is an ordinary day, not an error state.
      mini.labelReadable = false;
      final reader = HouseholdLabelReader(api, readFile: (_) async => [1, 2, 3]);
      await expectLater(
        reader.read(const {
          'front': 'a.jpg',
          'nutrition': 'b.jpg',
          'ingredients': 'c.jpg',
        }),
        throwsA(isA<LabelUnreadable>()),
      );

      // The same screen, opened empty. Not a different, lesser path.
      await tester.pumpWidget(confirm());
      await tester.pumpAndSettle();

      await type(tester, 'Name', 'Oat Crunch');
      await type(tester, 'Calories per 100g', '412');
      await save(tester);

      final saved = theSavedFood();
      expect(saved['name'], 'Oat Crunch');
      expect(saved['kcal_100'], 412);
      expect(saved['trust'], 'typed');
      expect(saved['source'], 'typed');
    });

    testWidgets('the hand-typed route does not need a photograph at all',
        (tester) async {
      await tester.pumpWidget(confirm());
      await tester.pumpAndSettle();

      await type(tester, 'Name', 'Emily\'s oat bars');
      await type(tester, 'Calories per 100g', '380');
      await type(tester, 'Protein per 100g', '6');
      await save(tester);

      expect(theSavedFood()['name'], 'Emily\'s oat bars');
      expect(theSavedFood()['protein_100'], 6);
    });

    testWidgets('a food with no numbers still goes in, and says so',
        (tester) async {
      await tester.pumpWidget(confirm());
      await tester.pumpAndSettle();

      await type(tester, 'Name', 'The green bag of lentils');

      expect(find.textContaining('No calories yet'), findsOneWidget);
      await save(tester);

      expect(theSavedFood()['name'], 'The green bag of lentils');
      expect(theSavedFood()['kcal_100'], isNull);
    });

    testWidgets('a food with no name is not saved', (tester) async {
      await tester.pumpWidget(confirm());
      await tester.pumpAndSettle();

      await type(tester, 'Calories per 100g', '412');
      await save(tester);

      expect(mini.foods, isEmpty);
      expect(find.textContaining('needs a name'), findsOneWidget);
    });
  });

  group('when the Mini is unreachable', () {
    testWidgets('the food is held and reaches the list later', (tester) async {
      mini.reachable = false;
      await tester.pumpWidget(confirm(draft: readFromAPacket));
      await tester.pumpAndSettle();
      await save(tester);

      expect(mini.foods, isEmpty);
      expect(await outbox.pendingCount(), 1);

      mini.reachable = true;
      await outbox.drain();

      expect(theSavedFood()['name'], 'Oat Crunch');
    });
  });

  group('what the reading gives back', () {
    test('a draft, not a saved food', () async {
      mini.labelRead = {
        'name': 'Oat Crunch',
        'brand': 'Store own',
        'kcal_100': 412,
        'protein_100': 9.4,
        'fat_100': 14.2,
        'carbs_100': 60.1,
        'serving_g': 45,
      };
      final reader = HouseholdLabelReader(api, readFile: (_) async => [1, 2, 3]);

      final draft = await reader.read(const {
        'front': 'a.jpg',
        'nutrition': 'b.jpg',
        'ingredients': 'c.jpg',
      });

      expect(draft.name, 'Oat Crunch');
      expect(draft.kcal100, 412);
      expect(draft.trust, 'photo');
      expect(mini.foods, isEmpty,
          reason: 'reading a packet saves nothing; only confirming does');
    });

    test('it names what it could not read', () async {
      mini.labelRead = {'name': 'Oat Crunch', 'kcal_100': 412};
      mini.labelUnreadable = ['fat_100', 'protein_100'];
      final reader = HouseholdLabelReader(api, readFile: (_) async => [1, 2, 3]);

      final draft = await reader.read(const {
        'front': 'a.jpg',
        'nutrition': 'b.jpg',
        'ingredients': 'c.jpg',
      });

      expect(draft.unreadable, ['fat_100', 'protein_100']);
      expect(draft.protein100, isNull);
    });
  });
}
