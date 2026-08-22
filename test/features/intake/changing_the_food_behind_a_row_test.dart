/// Saying a row was the wrong food altogether.
///
/// The last of release 7's four audit gaps, and the larger half of the one
/// about what an already-logged row can be corrected to. Everything else on
/// the edit screen corrects what the row *says* — how much, what it came to,
/// whose day, which meal. This corrects what the row *is*, and every figure
/// follows from that rather than being typed.
///
/// What is held here:
///
///  * the row becomes the other food and keeps its identity — same id, same
///    day, same meal, so what it used to say is still there to put back;
///  * the amount is kept and every figure is worked out again from the new
///    food, because somebody swapping brown bread for white had the same two
///    slices;
///  * the house is told the new name and the new figures, and told the row is
///    no longer the household food it was linked to — the one true thing the
///    phone can say about a list it has never seen;
///  * a row with no food behind it is refused rather than quietly given one,
///    and refused *before* anything reaches the house — a spoken row and a
///    recipe row alike, because neither is measured in anything a food knows
///    about.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import '../household/fake_household_server.dart';

/// A food with round numbers, so a recomputed figure is readable rather than
/// something only a calculator can check.
MealEntity _aFood(String code, String name,
        {double kcal = 100,
        double protein = 10,
        double carbs = 20,
        double fat = 5,
        String unit = 'g'}) =>
    MealEntity(
      code: code,
      name: name,
      url: null,
      mealQuantity: null,
      mealUnit: unit,
      servingQuantity: null,
      servingUnit: unit,
      servingSize: null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: kcal,
        proteins100: protein,
        carbohydrates100: carbs,
        fat100: fat,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    );

void main() {
  final day = DateTime(2026, 8, 22, 19, 30);

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late IntakeRepository intakes;
  late Outbox outbox;
  late UpdateIntakeUsecase correct;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    final household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    final ledger = FoodLedger(HouseholdLogger(household, outbox), api);
    intakes = IntakeRepository(LogEntryDao(db), FoodItemDao(db));
    correct = UpdateIntakeUsecase(intakes, ledger);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  /// Two slices of brown bread, on both machines, linked to the house's own
  /// food number 7.
  Future<void> twoSlicesOfBrownBread() async {
    await intakes.addIntake(IntakeEntity(
      id: 'local-1',
      unit: 'g',
      amount: 80,
      type: IntakeTypeEntity.lunch,
      meal: _aFood('brown-bread', 'Brown bread',
          kcal: 250, protein: 9, carbs: 45, fat: 3),
      dateTime: day,
    ));
    // The house knows a row the phone logged by the phone's own name for it —
    // a food row is created here first and travels under that id.
    mini.entries['local-1'] = {
      'client_id': 'local-1',
      'id': 1,
      'owner_id': mini.aidan,
      'label': 'Brown bread',
      'kcal': 200,
      'qty': 80,
      'unit': 'g',
      'protein': 7.2,
      'fat': 2.4,
      'carbs': 36,
      'slot': 'lunch',
      'day': '2026-08-22',
      'food_id': 7,
      'deleted_at': null,
      'version': 0,
      'state': 'settled',
    };
  }

  final whiteBread = _aFood('white-bread', 'White bread',
      kcal: 300, protein: 8, carbs: 55, fat: 4);

  group('it was the wrong food altogether', () {
    test('the row becomes the other food', () async {
      await twoSlicesOfBrownBread();
      await correct.updateIntake('local-1', const {}, nowItIs: whiteBread);

      final here = await intakes.getIntakeById('local-1');
      expect(here!.meal.name, 'White bread');
    });

    test('the amount is kept and every figure is worked out again', () async {
      await twoSlicesOfBrownBread();
      final after =
          await correct.updateIntake('local-1', const {}, nowItIs: whiteBread);

      // 80 g of a 300 kcal/100 g food.
      expect(after!.amount, 80);
      expect(after.totalKcal, closeTo(240, 0.001));
      expect(after.totalProteinsGram, closeTo(6.4, 0.001));
      expect(after.totalCarbsGram, closeTo(44, 0.001));
      expect(after.totalFatsGram, closeTo(3.2, 0.001));
    });

    test('it is the same row, not a new one', () async {
      await twoSlicesOfBrownBread();
      await correct.updateIntake('local-1', const {}, nowItIs: whiteBread);

      final lunch =
          await intakes.getIntakeByDateAndType(IntakeTypeEntity.lunch, day);
      expect(lunch.map((r) => r.id), ['local-1'],
          reason: 'a second row would make the day count both breads');
      expect(lunch.single.dateTime, day);
    });

    test('the house is told what it now is, and what it now comes to',
        () async {
      await twoSlicesOfBrownBread();
      await correct.updateIntake('local-1', const {}, nowItIs: whiteBread);
      await outbox.drain();

      final row = mini.entries['local-1']!;
      expect(row['label'], 'White bread');
      expect(row['kcal'], closeTo(240, 0.001));
      expect(row['qty'], 80);
    });

    test('and told the row is no longer the food it was linked to', () async {
      await twoSlicesOfBrownBread();
      await correct.updateIntake('local-1', const {}, nowItIs: whiteBread);
      await outbox.drain();

      expect(mini.entries['local-1']!['food_id'], isNull,
          reason: 'a link saying brown bread, on a row that says white bread, '
              'reads as real wherever it is followed');
    });

    test('in one correction, not several', () async {
      await twoSlicesOfBrownBread();
      await correct.updateIntake('local-1', const {}, nowItIs: whiteBread);
      await outbox.drain();

      expect(mini.requests.where((r) => r.contains('/amend')).length, 1);
    });

    test('the unit follows the new food', () async {
      await twoSlicesOfBrownBread();
      await correct.updateIntake('local-1', const {},
          nowItIs: _aFood('soup', 'Soup', unit: 'ml'));

      final here = await intakes.getIntakeById('local-1');
      expect(here!.unit, 'ml',
          reason: 'a food measured in millilitres and one measured in grams '
              'are not the same kind of thing');
    });
  });

  group('the food and the amount, corrected together', () {
    test('the figures come from the new food at the new amount', () async {
      await twoSlicesOfBrownBread();
      final after = await correct.updateIntake('local-1', {'amount': 120.0},
          nowItIs: whiteBread);

      // 120 g of the *new* bread, not of the old one.
      expect(after!.totalKcal, closeTo(360, 0.001));
    });

    test('and still only one correction reaches the house', () async {
      await twoSlicesOfBrownBread();
      await correct.updateIntake('local-1', {'amount': 120.0},
          nowItIs: whiteBread);
      await outbox.drain();

      expect(mini.requests.where((r) => r.contains('/amend')).length, 1);
      expect(mini.entries['local-1']!['kcal'], closeTo(360, 0.001));
    });
  });

  group('what is written down', () {
    // For a row with a food behind it the phone works its figures out live,
    // from the food and the amount, so the stored figures are not what it
    // shows. They are still the record — anything reading this row without
    // the food to hand reads these — and a swap that left them saying what
    // the row used to come to would be a lie sitting in the column.
    test('the figures stored on the row are the new food at the same amount',
        () async {
      await twoSlicesOfBrownBread();
      await correct.updateIntake('local-1', const {}, nowItIs: whiteBread);

      final row = await LogEntryDao(db).getById('local-1');
      expect(row!.logEntry.amount, 80);
      expect(row.logEntry.snapshotKcal, closeTo(240, 0.001));
      expect(row.logEntry.snapshotProtein, closeTo(6.4, 0.001));
      expect(row.logEntry.snapshotCarbs, closeTo(44, 0.001));
      expect(row.logEntry.snapshotFat, closeTo(3.2, 0.001));
    });
  });

  group('a row that is a recipe', () {
    // It takes the same shape as a food row — an amount and a unit — but its
    // amount is a number of servings of a recipe, which measures nothing a
    // food knows about, and unlike a food row it shows the figures written
    // down rather than working them out. So a swap here would not be slightly
    // wrong, it would read "2 servings of shepherd's pie" as two grams of
    // bread and write that down as the truth.
    Future<void> twoServingsOfShepherdsPie() async {
      await intakes.addRecipeIntake(
        id: 'local-3',
        recipeId: 'pie',
        recipeName: "Shepherd's pie",
        multiplier: 2,
        kcal: 900,
        protein: 50,
        carbs: 80,
        fat: 40,
        mealSlot: 'dinner',
        dateTime: day,
      );
    }

    test('is refused rather than worked out in servings of a food', () async {
      await twoServingsOfShepherdsPie();
      final after =
          await correct.updateIntake('local-3', const {}, nowItIs: whiteBread);

      expect(after, isNull);
      final here = await intakes.getIntakeById('local-3');
      expect(here!.quickAddLabel, "Shepherd's pie");
      expect(here.totalKcal, 900,
          reason: 'six kcal of white bread would be what two servings became');
    });

    test('and nothing about it reaches the house', () async {
      await twoServingsOfShepherdsPie();
      await correct.updateIntake('local-3', const {}, nowItIs: whiteBread);
      await outbox.drain();

      expect(mini.requests.where((r) => r.contains('/amend')), isEmpty);
    });
  });

  group('a row with no food behind it', () {
    Future<void> somethingHeSaid() async {
      await intakes.addQuickAddIntake(
        id: 'local-2',
        externalId: 'house-10',
        said: 'I had a bowl of porridge',
        label: 'Porridge',
        kcal: 350,
        mealSlot: 'breakfast',
        dateTime: day,
      );
      mini.entries['house-10'] = {
        'client_id': 'house-10',
        'id': 2,
        'owner_id': mini.aidan,
        'label': 'Porridge',
        'kcal': 350,
        'slot': 'breakfast',
        'day': '2026-08-22',
        'deleted_at': null,
        'version': 0,
        'state': 'settled',
      };
    }

    test('is refused rather than quietly given one', () async {
      await somethingHeSaid();
      final after =
          await correct.updateIntake('local-2', const {}, nowItIs: whiteBread);

      expect(after, isNull);
      final here = await intakes.getIntakeById('local-2');
      expect(here!.quickAddLabel, 'Porridge');
      expect(here.totalKcal, 350);
    });

    test('and nothing about it reaches the house', () async {
      await somethingHeSaid();
      await correct.updateIntake('local-2', const {}, nowItIs: whiteBread);
      await outbox.drain();

      expect(mini.requests.where((r) => r.contains('/amend')), isEmpty,
          reason: 'the house would be told the row is called White bread on '
              'the strength of a change that never happened here');
      expect(mini.entries['house-10']!['label'], 'Porridge');
    });
  });
}
