/// Recording how many are in a pack, so one of them can be added later.
///
/// Behaviour under test (Release 5, TM-0016). The Mac Mini has always had a
/// place to keep how many things are in a pack, and its arithmetic has always
/// been able to turn "one fish cake" into grams from it. Nothing could ever put
/// a number there: the reading did not ask for it, the confirmation screen had
/// no box for it, and the pack weight itself was carried silently through the
/// form rather than shown. So the "one (125 g)" amount added to the portion
/// sheet could only ever appear for a food nobody in this house had taught it.
///
/// The carrying test is [what the two numbers come to is said back before
/// saving]. A pack weight and a count are each easy to mistype and neither
/// looks wrong on its own — 400 and 6 is a 67g fish cake, 400 and 60 is a 6.7g
/// one, and both are numbers a person would accept without blinking. The third
/// figure is the only thing on the screen that can catch either mistake, and it
/// has to be there while the packet is still in their hand.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/domain/household_food.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;

  const packLabel = 'What the whole pack weighs in grams';
  const countLabel = 'How many are in a pack';

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
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
    await tester.enterText(find.widgetWithText(TextField, label).first, value);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    // Scrolled to first, the way a person does: the form is longer than a
    // phone screen, so Save is below the fold on any real device.
    await tester.ensureVisible(find.text('Save to the household list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to the household list'));
    await tester.pumpAndSettle();
    await outbox.drain();
  }

  Map<String, dynamic> theSavedFood() => mini.foods.values.single;

  const readOffAPacket = FoodDraft(
    name: 'Fish cakes',
    brand: 'Store own',
    kcal100: 200,
    packGrams: 400,
    perPack: 6,
    trust: 'photo',
    source: 'photo',
  );

  group('the third number, said back', () {
    testWidgets('what the two numbers come to is said back before saving',
        (tester) async {
      await tester.pumpWidget(confirm(draft: readOffAPacket));
      await tester.pumpAndSettle();

      expect(find.text(ConfirmFoodScreen.oneOfThemSentence(400 / 6)),
          findsOneWidget);
      expect(find.textContaining('66.7 g'), findsOneWidget,
          reason: 'the only figure on this screen that can catch a mistyped '
              'pack weight or a mistyped count');
    });

    testWidgets('and it follows the boxes as they are corrected',
        (tester) async {
      await tester.pumpWidget(confirm(draft: readOffAPacket));
      await tester.pumpAndSettle();

      // A finger slip: six becomes sixty.
      await type(tester, countLabel, '60');
      expect(find.textContaining('6.7 g'), findsOneWidget,
          reason: 'a 6.7g fish cake is the sentence that makes somebody look '
              'at the count again');
      expect(find.textContaining('66.7 g'), findsNothing);
    });

    testWidgets('nothing is said when there is nothing to say',
        (tester) async {
      // Most food is sold by weight and has no count. A line about "one of
      // them" on a bag of rice would be inventing a thing to be one of.
      await tester.pumpWidget(confirm(
          draft: const FoodDraft(
              name: 'Basmati rice', kcal100: 350, packGrams: 1000)));
      await tester.pumpAndSettle();

      expect(find.textContaining('That makes one of them'), findsNothing);
    });
  });

  group('what reaches the household list', () {
    testWidgets('both numbers are saved', (tester) async {
      await tester.pumpWidget(confirm(draft: readOffAPacket));
      await tester.pumpAndSettle();
      await save(tester);

      expect(theSavedFood()['pack_grams'], 400);
      expect(theSavedFood()['per_pack'], 6);
    });

    testWidgets('a food typed in from scratch can carry them too',
        (tester) async {
      await tester.pumpWidget(confirm());
      await tester.pumpAndSettle();

      await type(tester, 'Name', 'Fish cakes');
      await type(tester, packLabel, '400');
      await type(tester, countLabel, '6');
      await save(tester);

      expect(theSavedFood()['name'], 'Fish cakes');
      expect(theSavedFood()['pack_grams'], 400);
      expect(theSavedFood()['per_pack'], 6);
    });

    testWidgets('the pack weight is a box now, not something carried unseen',
        (tester) async {
      // It used to travel from the reading to the save without ever appearing,
      // so a misread pack weight could not be corrected by the person holding
      // the pack.
      await tester.pumpWidget(confirm(draft: readOffAPacket));
      await tester.pumpAndSettle();

      await type(tester, packLabel, '500');
      await save(tester);

      expect(theSavedFood()['pack_grams'], 500);
    });

    testWidgets('an empty count is left out rather than sent as nothing',
        (tester) async {
      await tester.pumpWidget(confirm());
      await tester.pumpAndSettle();
      await type(tester, 'Name', 'Basmati rice');
      await type(tester, packLabel, '1000');
      await save(tester);

      expect(theSavedFood().containsKey('per_pack'), isFalse);
      expect(theSavedFood()['pack_grams'], 1000);
    });
  });

  group('the count box says what a blank means', () {
    testWidgets('because on most packets a blank is the right answer',
        (tester) async {
      await tester.pumpWidget(confirm());
      await tester.pumpAndSettle();

      expect(find.text(ConfirmFoodScreen.countHelper), findsOneWidget);
      expect(ConfirmFoodScreen.countHelper, contains('Only if the pack says'));
    });
  });

  group('the whole way through', () {
    test('a food saved with a count comes back able to be counted', () {
      // The point of all of it: the amount sheet can offer "one of them" only
      // for a food that has both numbers, and until now nothing could give it
      // both.
      final food = HouseholdFood.fromJson(const {
        'id': 3,
        'name': 'Fish cakes',
        'kcal_100': 200,
        'pack_grams': 400,
        'per_pack': 6,
        'trust': 'photo',
        'source': 'photo',
      });

      final meal = MealEntity.fromHouseholdFood(food);
      expect(meal.hasItemValues, isTrue);
      expect(meal.itemGrams, closeTo(66.7, 0.1));
    });
  });

  group('a reading that arrives with a count', () {
    test('carries it into the draft', () {
      final draft = FoodDraft.fromReading(const {
        'name': 'Fish cakes',
        'kcal_100': 200,
        'pack_grams': 400,
        'per_pack': 6,
      });
      expect(draft.perPack, 6);
      expect(draft.itemGrams, closeTo(66.7, 0.1));
    });

    test('and a correction keeps it', () {
      final draft = FoodDraft.fromReading(const {
        'name': 'Fish cakes',
        'per_pack': 6,
      }).edited(name: 'Fish cakes, large');
      expect(draft.perPack, 6);
      expect(draft.trust, 'typed');
    });
  });
}
