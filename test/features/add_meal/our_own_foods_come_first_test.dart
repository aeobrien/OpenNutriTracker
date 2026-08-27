/// The household's own foods come before anything from the internet.
///
/// Behaviour under test — Release C. Three screens ask the same question in
/// three shapes, and all three should ask the house first:
///
///  * the picker, when it opens, before anybody has typed anything;
///  * the search box, when they have;
///  * the barcode scanner, which is the case where it matters most, because a
///    packet this house has already read the label of has better numbers on it
///    than a public database's guess at the same packet.
///
/// The other half of the release is the promise underneath that ordering: a
/// person's *own* foods come first, which the Mac Mini can only work
/// out if the app tells it which food each meal was. That is the food id, and
/// it is checked here too.
///
/// One test in here reproduces a specific real fault rather than an imagined
/// one. On the evening of 19 August the Mac Mini was running code that
/// did not understand being asked for a search, and answered every search with
/// its entire list. Left alone that means typing "banana" and getting last
/// week's curry back.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/usecase/search_products_usecase.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/domain/household_food.dart';
import 'package:opennutritracker/features/scanner/domain/usecase/search_product_by_barcode_usecase.dart';

import '../household/fake_household_server.dart';
import 'fake_products_repository.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late FoodFinder finder;
  late FakeProductsRepository publicList;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  SearchProductsUseCase searching() =>
      SearchProductsUseCase(publicList, finder);
  SearchProductByBarcodeUseCase scanning() =>
      SearchProductByBarcodeUseCase(publicList, finder);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db), api());
    finder = FoodFinder(api(), household, FoodItemDao(db));
    publicList = FakeProductsRepository();
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  group('the picker opens on what the house already has', () {
    test('their own foods, not an empty screen', () async {
      mini.addFood(name: 'Oat biscuits', brand: 'Waitrose', kcal100: 450);
      mini.addFood(name: 'Cheddar', kcal100: 416);

      final opening = (await searching().ourFoods()).foods;

      expect(opening.map((m) => m.name), ['Oat biscuits', 'Cheddar']);
      expect(
        publicList.searchesMade,
        isEmpty,
        reason: 'opening the picker should not go out to the internet',
      );
    });

    /// Aidan, away from home, 27 August, on the picker: "Now my own foods
    /// aren't showing at all. It simply says “Search results” then
    /// “please enter a search word”."
    ///
    /// His own foods live on the Mac Mini and are fetched fresh every time
    /// this screen opens. Away from home he cannot reach it, so the answer is
    /// an empty list — and an empty list here is indistinguishable from a
    /// household that owns no foods at all. The screen draws the same thing
    /// for both.
    ///
    /// This is not about the scrolling change of 25 August, which touched only
    /// the screen's layout and left every line of this path alone. It is what
    /// the picker has always done away from the house.
    test('away from home it comes back empty, which reads as owning nothing',
        () async {
      mini.addFood(name: 'Oat biscuits', brand: 'Waitrose', kcal100: 450);
      mini.addFood(name: 'Cheddar', kcal100: 416);

      // The same two foods, still on the house's list. Only the route to it
      // is gone.
      final awayFromHome = SearchProductsUseCase(
          publicList,
          FoodFinder(HouseholdApi(baseUrl: 'http://mini',
                                  client: mini.unreachable()),
              household, FoodItemDao(db)));

      final away = await awayFromHome.ourFoods();
      expect(away.foods, isEmpty);
      expect(away.houseAnswered, isFalse,
          reason: 'and it knows the difference between that and owning '
              'nothing — see the_picker_says_when_it_could_not_ask_test');
      expect((await searching().ourFoods()).foods, isNotEmpty,
          reason: 'the foods are there; it is the Mac Mini that is not');
    });

    test(
      "asked on this person's behalf, not the household's in general",
      () async {
        mini.addFood(name: 'Oat biscuits');

        await finder.theirs();

        expect(mini.askedFoodsFor, mini.aidan);
      },
    );

    test(
      'a sleeping Mac Mini leaves the picker exactly as it was',
      () async {
        mini.addFood(name: 'Oat biscuits');
        mini.reachable = false;

        expect((await searching().ourFoods()).foods, isEmpty);
      },
    );
  });

  group('searching looks at home first', () {
    test('ours above theirs, and theirs still there', () async {
      mini.addFood(name: 'Oat biscuits', brand: 'Waitrose', kcal100: 450);
      publicList.willReturn = [_publicMeal('Oaty bars')];

      final results = await searching().searchOFFProductsByString('oat');

      expect(results.map((m) => m.name), ['Oat biscuits', 'Oaty bars']);
    });

    test(
      'a food of ours is marked as ours, so the ledger can name it later',
      () async {
        final row = mini.addFood(name: 'Oat biscuits');

        final results = await searching().searchOFFProductsByString('oat');

        expect(HouseholdFood.idFromCode(results.first.code), row['id']);
      },
    );

    test('the public search still runs when the house has nothing', () async {
      publicList.willReturn = [_publicMeal('Oaty bars')];

      final results = await searching().searchOFFProductsByString('oat');

      expect(results.map((m) => m.name), ['Oaty bars']);
    });

    test(
      'the public search still runs when the Mac Mini is asleep',
      () async {
        mini.addFood(name: 'Oat biscuits');
        mini.reachable = false;
        publicList.willReturn = [_publicMeal('Oaty bars')];

        final results = await searching().searchOFFProductsByString('oat');

        expect(
          results.map((m) => m.name),
          ['Oaty bars'],
          reason: 'searching for food away from home has to keep working',
        );
      },
    );

    test(
      'a public database that is down leaves our own foods showing',
      () async {
        // The mirror of the test above it, and it was missing. On 24 August
        // 2026 Open Food Facts answered every search with a 503 and a page of
        // HTML, and this app showed Aidan an error screen with nothing on it —
        // although the house had twenty-one foods of its own and could answer
        // perfectly well. A public database going down must cost this
        // household its own list no more than a sleeping Mac Mini costs it the
        // internet.
        mini.addFood(name: 'Oat biscuits', brand: 'Waitrose', kcal100: 450);
        publicList.searchesFailWith = StateError('503 from the internet');

        final results = await searching().searchOFFProductsByString('oat');

        expect(results.map((m) => m.name), ['Oat biscuits']);
      },
    );

    test(
      'and when neither can answer, the screen may still say so',
      () async {
        // Nothing of ours and nothing of theirs is the one case that should
        // still reach the error state — there is genuinely nothing to show,
        // and a silent empty list would read as "no such food".
        publicList.searchesFailWith = StateError('503 from the internet');

        expect(searching().searchOFFProductsByString('oat'),
            throwsA(isA<StateError>()));
      },
    );

    test(
      'an out-of-date Mac Mini cannot put the wrong food in front of '
      'them',
      () async {
        mini.addFood(name: 'Butter chicken wrap');
        mini.addFood(name: 'Banana');
        mini.understandsFoodSearch = false;

        final results = await searching().searchOFFProductsByString('banana');

        expect(results.map((m) => m.name), ['Banana']);
      },
    );
  });

  group('a packet this house has scanned before', () {
    test(
      'comes back from our own list, and the internet is not asked',
      () async {
        mini.addFood(
          name: 'Oat biscuits',
          barcode: '5012345678900',
          kcal100: 450,
        );

        final found = await scanning().searchProductByBarcode('5012345678900');

        expect(found.name, 'Oat biscuits');
        expect(
          publicList.barcodesLookedUp,
          isEmpty,
          reason:
              'the numbers this house checked must not be replaced by a '
              "stranger's reading of the same packet",
        );
      },
    );

    test('a packet we have never seen falls through to the internet', () async {
      publicList.willReturnForBarcode = _publicMeal("Somebody else's biscuits");

      final found = await scanning().searchProductByBarcode('5099999999999');

      expect(found.name, "Somebody else's biscuits");
      expect(publicList.barcodesLookedUp, ['5099999999999']);
    });

    test(
      'a sleeping Mac Mini falls through rather than failing',
      () async {
        mini.addFood(name: 'Oat biscuits', barcode: '5012345678900');
        mini.reachable = false;
        publicList.willReturnForBarcode = _publicMeal(
          "Somebody else's biscuits",
        );

        final found = await scanning().searchProductByBarcode('5012345678900');

        expect(found.name, "Somebody else's biscuits");
      },
    );
  });

  group('a food of ours carries its numbers across intact', () {
    test('the per-100 figures stay per-100 figures', () async {
      mini.addFood(
        name: 'Oat biscuits',
        brand: 'Waitrose',
        kcal100: 450,
        protein100: 8,
        fat100: 20,
        carbs100: 60,
        servingG: 25,
      );

      final meal = (await finder.theirs()).single;

      expect(meal.name, 'Oat biscuits');
      expect(meal.brands, 'Waitrose');
      expect(meal.nutriments.energyKcal100, 450);
      expect(meal.nutriments.proteins100, 8);
      expect(meal.nutriments.fat100, 20);
      expect(meal.nutriments.carbohydrates100, 60);
      expect(meal.servingQuantity, 25);
    });

    test(
      'a figure nobody knows stays unknown rather than becoming zero',
      () async {
        mini.addFood(name: 'Leftovers');

        final meal = (await finder.theirs()).single;

        expect(meal.nutriments.energyKcal100, isNull);
        expect(meal.nutriments.proteins100, isNull);
      },
    );
  });

  group('the ledger says which food it was', () {
    late Outbox outbox;
    late FoodLedger ledger;

    setUp(() {
      outbox = Outbox.of(db, api());
      ledger = FoodLedger(HouseholdLogger(household, outbox), api());
    });

    test('a food from our own list is named on the entry', () async {
      final row = mini.addFood(name: 'Oat biscuits', kcal100: 450);
      final ours = (await finder.theirs()).single;

      await ledger.add(
        intakeId: 'intake-1',
        day: DateTime(2026, 8, 19),
        slot: 'snack',
        label: ours.name!,
        liquid: false,
        mine: 40,
        foodId: HouseholdFood.idFromCode(ours.code),
      );
      await outbox.drain();

      expect(
        mini.entries.values.single['food_id'],
        row['id'],
        reason:
            'the Mac Mini counts entries against a food to work '
            'out which foods this person actually eats',
      );
    });

    test('a food from the internet is not named as one of ours', () async {
      await ledger.add(
        intakeId: 'intake-1',
        day: DateTime(2026, 8, 19),
        slot: 'snack',
        label: 'Oaty bars',
        liquid: false,
        mine: 40,
        foodId: HouseholdFood.idFromCode('5012345678900'),
      );
      await outbox.drain();

      expect(mini.entries.values.single.containsKey('food_id'), isFalse);
    });
  });

  group('reading a food id back out of a code', () {
    test(
      'one of ours',
      () => expect(HouseholdFood.idFromCode(HouseholdFood.codeFor(7)), 7),
    );
    test(
      'a barcode is not one of ours',
      () => expect(HouseholdFood.idFromCode('5012345678900'), isNull),
    );
    test(
      'nothing at all is not one of ours',
      () => expect(HouseholdFood.idFromCode(null), isNull),
    );
    test(
      'something that only looks like one of ours',
      () => expect(HouseholdFood.idFromCode('mantel:banana'), isNull),
    );
  });

  group('the second match check on the phone', () {
    const biscuits = HouseholdFood(
      id: 1,
      name: 'Oat biscuits',
      brand: 'Waitrose',
    );

    test('by name', () => expect(biscuits.matches('biscuit'), isTrue));
    test('by brand', () => expect(biscuits.matches('waitrose'), isTrue));
    test('ignoring case', () => expect(biscuits.matches('OAT'), isTrue));
    test(
      'nothing typed matches everything',
      () => expect(biscuits.matches('  '), isTrue),
    );
    test(
      'something else does not',
      () => expect(biscuits.matches('banana'), isFalse),
    );
    test(
      'a food with no brand does not crash on a brand search',
      () => expect(
        const HouseholdFood(id: 2, name: 'Leftovers').matches('waitrose'),
        isFalse,
      ),
    );
  });
}

MealEntity _publicMeal(String name) => MealEntity(
  code: '5099999999999',
  name: name,
  url: null,
  mealQuantity: null,
  mealUnit: 'g',
  servingQuantity: null,
  servingUnit: null,
  servingSize: null,
  nutriments: const MealNutrimentsEntity(
    energyKcal100: 500,
    carbohydrates100: null,
    fat100: null,
    proteins100: null,
    sugars100: null,
    saturatedFat100: null,
    fiber100: null,
  ),
  source: MealSourceEntity.off,
);
