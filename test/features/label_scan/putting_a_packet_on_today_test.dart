/// Being offered your day after you have entered a packet.
///
/// Behaviour under test: saving a packet puts it in the household food list —
/// and then *offers* to put it on today, rather than doing it.
///
/// The offer exists because the two places are genuinely different and the
/// screen used to leave somebody stranded between them. Aidan pressed Save on
/// a packet, was told nothing, and went and scanned its barcode afterwards to
/// find out whether it had worked. The message that fixed that told him where
/// the food had gone; it still left him to go and search for a thing he had
/// that second finished typing in.
///
/// The test that carries the item is [nothing reaches the day unless the offer
/// is taken]. Aidan was asked on 21 August 2026 whether saving a packet should
/// offer to put it on his day and said yes — an offer. Entering a packet and
/// eating it are two different acts: somebody typing a jar of coffee in as they
/// put it in the cupboard has not drunk it. An implementation that quietly
/// added every saved packet to the day would pass every other test here.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/label_scan/domain/putting_it_on_today.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late HouseholdApi api;
  late FoodFinder finder;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    logger = HouseholdLogger(household, outbox);
    finder = FoodFinder(api, household);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  const aPacket = FoodDraft(
    name: 'Oat Crunch',
    brand: 'Store own',
    barcode: '5012345678900',
    kcal100: 412,
    trust: 'photo',
    source: 'photo',
  );

  /// The offer as a person meets it: press Save, then look at what is offered.
  Widget confirm({void Function(BuildContext, FoodDraft)? offer}) =>
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ConfirmFoodScreen(
              logger: logger,
              draft: aPacket,
              onPutOnDay: offer,
            ),
          ),
        ),
      );

  Future<void> save(WidgetTester tester) async {
    // Scrolled to first, the way a person does: the form is longer than a
    // phone screen, so Save is below the fold on any real device.
    await tester.ensureVisible(find.text('Save to the household list'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to the household list'));
    await tester.pumpAndSettle();
  }

  group('what the screen offers once a packet is saved', () {
    testWidgets('it offers to put it on today', (tester) async {
      await tester.pumpWidget(confirm(offer: (_, __) {}));
      await save(tester);
      expect(find.text(ConfirmFoodScreen.putItOnToday), findsOneWidget);
    });

    testWidgets('and still says where the food itself went', (tester) async {
      await tester.pumpWidget(confirm(offer: (_, __) {}));
      await save(tester);
      // Inside the question now rather than beside it. Somebody who has just
      // pressed Save wants to know the save worked before being asked anything
      // else, so the question says where the food is and then asks.
      expect(
        find.widgetWithText(
            AlertDialog, ConfirmFoodScreen.putItOnTodayQuestion(aPacket.name)),
        findsOneWidget,
      );
    });

    testWidgets('nothing reaches the day unless the offer is taken', (
      tester,
    ) async {
      var taken = false;
      await tester.pumpWidget(confirm(offer: (_, __) => taken = true));
      await save(tester);
      // The message is on screen with its button, and the offer has not been
      // pressed. Nothing may have happened by itself.
      expect(find.text(ConfirmFoodScreen.putItOnToday), findsOneWidget);
      expect(taken, isFalse);
    });

    testWidgets('and it does reach the day when it is', (tester) async {
      FoodDraft? offered;
      await tester.pumpWidget(confirm(offer: (_, food) => offered = food));
      await save(tester);
      await tester.tap(find.text(ConfirmFoodScreen.putItOnToday));
      await tester.pumpAndSettle();
      expect(offered?.name, aPacket.name);
    });

    testWidgets('a screen with no offer to make says the longer sentence', (
      tester,
    ) async {
      await tester.pumpWidget(confirm());
      await save(tester);
      expect(
        find.text(ConfirmFoodScreen.savedSentence(aPacket.name)),
        findsOneWidget,
      );
      expect(find.text(ConfirmFoodScreen.putItOnToday), findsNothing);
    });
  });

  group('finding the packet again so it can go on the day', () {
    /// Save the packet the way the screen does — onto the queue, not straight
    /// at the Mac Mini.
    Future<void> saveIt({String? barcode, String name = 'Oat Crunch'}) => logger
        .addFood(name: name, trust: 'photo', barcode: barcode, kcal100: 412);

    test('it is found by its barcode', () async {
      await saveIt(barcode: '5012345678900');
      final answer = await PuttingItOnToday(outbox, finder).find(aPacket);
      expect(answer.found, isTrue);
      expect(answer.food!.name, 'Oat Crunch');
    });

    test('the queue is emptied first, so the house has it to find', () async {
      await saveIt(barcode: '5012345678900');
      // Nothing has drained yet: the Mac Mini has never heard of this food.
      expect(mini.foods, isEmpty);
      final answer = await PuttingItOnToday(outbox, finder).find(aPacket);
      expect(answer.found, isTrue);
    });

    test('a packet with no barcode is found by its name', () async {
      await saveIt(name: 'Bramley Apple Pie');
      final answer = await PuttingItOnToday(outbox, finder).find(
        const FoodDraft(
          name: 'Bramley Apple Pie',
          trust: 'typed',
          source: 'manual',
        ),
      );
      expect(answer.food!.name, 'Bramley Apple Pie');
    });

    test('and not by something merely like its name', () async {
      await saveIt(name: 'Bramley Apple Pie');
      final answer = await PuttingItOnToday(
        outbox,
        finder,
      ).find(const FoodDraft(name: 'Apple', trust: 'typed', source: 'manual'));
      expect(answer.found, isFalse);
    });

    test(
      'a sleeping Mac Mini is said out loud, and the food is safe',
      () async {
        await saveIt(barcode: '5012345678900');
        mini.reachable = false;
        final answer = await PuttingItOnToday(outbox, finder).find(aPacket);
        expect(answer.found, isFalse);
        expect(answer.why, PuttingItOnToday.cannotReach);
      },
    );

    test('a house that does not have it yet says so differently', () async {
      final answer = await PuttingItOnToday(outbox, finder).find(aPacket);
      expect(answer.found, isFalse);
      expect(answer.why, PuttingItOnToday.notThereYet);
    });
  });

  group('which meal it opens on', () {
    Future<IntakeTypeEntity> mealAt(DateTime at) async {
      final answer = await PuttingItOnToday(
        outbox,
        finder,
      ).find(aPacket, now: at);
      return answer.meal;
    }

    test('the clock decides', () async {
      expect(
        await mealAt(DateTime(2026, 8, 22, 8)),
        IntakeTypeEntity.breakfast,
      );
      expect(await mealAt(DateTime(2026, 8, 22, 12)), IntakeTypeEntity.lunch);
      expect(await mealAt(DateTime(2026, 8, 22, 19)), IntakeTypeEntity.dinner);
    });

    test('and an hour that is nobody\'s mealtime is a snack', () async {
      expect(await mealAt(DateTime(2026, 8, 22, 23)), IntakeTypeEntity.snack);
    });

    test('the meal is still said when the packet cannot be found', () async {
      mini.reachable = false;
      final answer = await PuttingItOnToday(
        outbox,
        finder,
      ).find(aPacket, now: DateTime(2026, 8, 22, 8));
      expect(answer.found, isFalse);
      expect(answer.meal, IntakeTypeEntity.breakfast);
    });
  });
}
