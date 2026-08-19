/// Adding a food reaches the household, and reaches both of you when it was
/// for both of you.
///
/// Behaviour under test: two promises that share one code path.
///
///  * **Release A** said everything the app already writes also writes to the
///    household ledger. Until now, adding a food wrote only to this phone's own
///    diary — so the thing he does most often was the one thing the Mac Mini
///    never heard about. The first group below is that gap closed.
///  * **Release B, TM-0011** said one meal can land on two ledgers. The second
///    group is that: two rows, one per person, each worked out from that
///    person's own amount and both entered by whoever is holding the phone.
///
/// Why it is tested here rather than through the sheet: the screen that adds a
/// food cannot be stood up without the phone's whole diary behind it, so the
/// part that carries the promise — who ends up with what — was given its own
/// seam. What the sheet does with it is checked next door, and that the sheet
/// actually calls it is checked in the wiring test.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/food_shares.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import '../household/fake_household_server.dart';

void main() {
  final day = DateTime(2026, 8, 19, 19, 30);

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late Outbox outbox;
  late FoodLedger ledger;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    ledger = FoodLedger(HouseholdLogger(household, outbox));
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  /// A pack of oat biscuits: 450 kcal, 8g protein, 20g fat, 60g carbs per 100g.
  Future<void> logBiscuits({
    required double mine,
    List<FoodShare> alsoFor = const [],
    bool liquid = false,
    num? kcalPer100 = 450,
  }) =>
      ledger.add(
        day: day,
        slot: 'snack',
        label: 'Oat biscuits',
        liquid: liquid,
        mine: mine,
        alsoFor: alsoFor,
        kcalPerUnit: kcalPer100 == null ? null : kcalPer100 / 100,
        proteinPerUnit: 8 / 100,
        fatPerUnit: 20 / 100,
        carbsPerUnit: 60 / 100,
      );

  List<Map<String, dynamic>> rowsFor(int person) => mini.entries.values
      .where((e) => e['owner_id'] == person)
      .toList();

  group('the food he logs reaches the Mac Mini', () {
    test('one row, on his day, with his figures', () async {
      await logBiscuits(mine: 40);
      await outbox.drain();

      expect(mini.entries, hasLength(1));
      final row = mini.entries.values.single;
      expect(row['owner_id'], mini.aidan);
      expect(row['author_id'], mini.aidan);
      expect(row['day'], '2026-08-19');
      expect(row['label'], 'Oat biscuits');
      expect(row['slot'], 'snack');
      expect(row['qty'], 40);
      expect(row['unit'], 'g');
      expect(row['kcal'], 180); // 4.5 per gram, forty grams
      expect(row['protein'], 3.2);
      expect(row['fat'], 8);
      expect(row['carbs'], 24);
    });

    test('a drink is logged in millilitres, not grams', () async {
      await logBiscuits(mine: 250, liquid: true);
      await outbox.drain();

      expect(mini.entries.values.single['unit'], 'ml');
    });

    test('a figure the food does not carry stays missing, never zero',
        () async {
      await logBiscuits(mine: 40, kcalPer100: null);
      await outbox.drain();

      final row = mini.entries.values.single;
      expect(row['kcal'], isNull,
          reason: 'zero would be a claim that biscuits have no calories');
      expect(row.containsKey('kcal'), isFalse);
    });

    test('a sleeping Mac Mini loses nothing — it lands when it wakes',
        () async {
      mini.reachable = false;
      await logBiscuits(mine: 40);
      await outbox.drain();
      expect(mini.entries, isEmpty);

      mini.reachable = true;
      await outbox.drain();
      expect(mini.entries, hasLength(1));
    });

    test('draining twice does not log it twice', () async {
      await logBiscuits(mine: 40);
      await outbox.drain();
      await outbox.drain();

      expect(mini.entries, hasLength(1));
    });
  });

  group('for both of us — one food, two ledgers', () {
    test('two rows, one on each of their days', () async {
      await logBiscuits(
          mine: 40, alsoFor: [FoodShare(personId: mini.emily, quantity: 40)]);
      await outbox.drain();

      expect(mini.entries, hasLength(2));
      expect(rowsFor(mini.aidan), hasLength(1));
      expect(rowsFor(mini.emily), hasLength(1));
    });

    test('both rows say he entered them', () async {
      await logBiscuits(
          mine: 40, alsoFor: [FoodShare(personId: mini.emily, quantity: 40)]);
      await outbox.drain();

      for (final row in mini.entries.values) {
        expect(row['author_id'], mini.aidan);
      }
    });

    test("her figures come from her amount, not from a share of his", () async {
      await logBiscuits(
          mine: 60, alsoFor: [FoodShare(personId: mini.emily, quantity: 20)]);
      await outbox.drain();

      expect(rowsFor(mini.aidan).single['qty'], 60);
      expect(rowsFor(mini.aidan).single['kcal'], 270);
      expect(rowsFor(mini.emily).single['qty'], 20);
      expect(rowsFor(mini.emily).single['kcal'], 90);
    });

    test('"just me" puts nothing on her day at all', () async {
      await logBiscuits(mine: 40);
      await outbox.drain();

      expect(rowsFor(mini.emily), isEmpty);
    });

    test('a sleeping Mac Mini keeps both, and delivers both', () async {
      mini.reachable = false;
      await logBiscuits(
          mine: 40, alsoFor: [FoodShare(personId: mini.emily, quantity: 25)]);
      await outbox.drain();
      expect(mini.entries, isEmpty);

      mini.reachable = true;
      await outbox.drain();
      expect(rowsFor(mini.aidan), hasLength(1));
      expect(rowsFor(mini.emily), hasLength(1));
    });

    test('draining twice is still one biscuit each', () async {
      await logBiscuits(
          mine: 40, alsoFor: [FoodShare(personId: mini.emily, quantity: 25)]);
      await outbox.drain();
      await outbox.drain();

      expect(mini.entries, hasLength(2));
    });
  });

  group('working out one person share', () {
    test('multiplies their own amount', () {
      final row = portionFor(const FoodShare(personId: 2, quantity: 20),
          kcalPerUnit: 4.5, proteinPerUnit: 0.08);
      expect(row.personId, 2);
      expect(row.quantity, 20);
      expect(row.kcal, 90);
      expect(row.protein, 1.6);
    });

    test('leaves what it was not told alone', () {
      final row = portionFor(const FoodShare(personId: 2, quantity: 20));
      expect(row.kcal, isNull);
      expect(row.protein, isNull);
      expect(row.fat, isNull);
      expect(row.carbs, isNull);
    });

    test('rounds to one decimal rather than trailing a long float', () {
      final row = portionFor(const FoodShare(personId: 1, quantity: 33),
          kcalPerUnit: 4.53);
      expect(row.kcal, 149.5);
    });
  });
}
