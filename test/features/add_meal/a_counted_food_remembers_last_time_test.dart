/// A food the house counts in items, opening on what he had last time.
///
/// The order Aidan settled on 22 August is: his portion of the meal, then the
/// amount he had last time, then whatever the pack says. For a food with a
/// count on it — six fish cakes in a four-hundred-gram box — the second step
/// could never fire, because the two facts arrive from different places and
/// nothing joined them. A pack weight and a count come off the household's
/// list; how much somebody last ate is in this phone's own log. So the box
/// always fell through to "one of them", and the change he approved that
/// afternoon — ninety-six grams of a hundred-and-twenty-five-gram pie opening
/// on 0.8 — was right, tested, and unreachable on his phone.
///
/// The carrying test is [it opens on what he had last time, not on one of
/// them]. Everything else here would pass on a version that fetched the last
/// amount and then let the pack win anyway.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/meal_detail/domain/default_portion.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late FoodFinder finder;
  late IntakeRepository intakes;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    final household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(mini.aidan);
    finder = FoodFinder(api, household, FoodItemDao(db));
    intakes = IntakeRepository(LogEntryDao(db), FoodItemDao(db));
  });

  tearDown(() async => db.close());

  /// Six fish cakes in a four-hundred-gram box: sixty-six and a bit grams
  /// each, and a food whose amount box counts in items.
  void aBoxOfSix() => mini.addFood(
      name: 'Fish cakes', kcal100: 200, packGrams: 400, perPack: 6);

  /// The house's fish cakes as the picker hands them over.
  Future<MealEntity> asThePickerHasIt() async =>
      (await finder.matching('Fish cakes')).single;

  /// Eat some, the way the amount screen does when Add is pressed.
  Future<void> heHad(double grams, MealEntity food) => intakes.addIntake(
        IntakeEntity(
          id: 'had-it',
          unit: 'g',
          amount: grams,
          type: IntakeTypeEntity.dinner,
          meal: food,
          dateTime: DateTime(2026, 8, 21, 19),
        ),
      );

  group('a food the house counts in items', () {
    test('carries nothing about last time until there has been a last time',
        () async {
      aBoxOfSix();
      expect((await asThePickerHasIt()).lastUsedGrams, isNull);
    });

    test('carries what he had once he has had some', () async {
      aBoxOfSix();
      await heHad(133, await asThePickerHasIt());
      expect((await asThePickerHasIt()).lastUsedGrams, 133);
    });

    test('and it is still the food the house counts', () async {
      // The join must not cost the two numbers that made it a counted food in
      // the first place — they arrive from the other side.
      aBoxOfSix();
      await heHad(133, await asThePickerHasIt());
      final food = await asThePickerHasIt();
      expect(food.packGrams, 400);
      expect(food.perPack, 6);
      expect(food.hasItemValues, isTrue);
    });

    test('it opens on what he had last time, not on one of them', () async {
      aBoxOfSix();
      await heHad(133, await asThePickerHasIt());
      final food = await asThePickerHasIt();

      // The box is counting items, so the figure in it is in items: two of
      // them, near enough, rather than the one the pack would have offered.
      // "2.0" and not "2" because two fish cakes out of a box of six is
      // 133.3 g and he had 133 — the box says the amount he actually had
      // rather than tidying it into a round number of fish cakes.
      final portion = defaultPortionFor(food,
          usesImperialUnits: false, unit: 'item', gramsPerUnit: food.itemGrams!);
      expect(portion.source, PortionSource.lastTime);
      expect(portion.amount, '2.0');
    });

    test('somebody else\'s food is not mistaken for his', () async {
      // Joined by the id the house gave the food. Two foods, one eaten.
      aBoxOfSix();
      mini.addFood(name: 'Oat biscuits', kcal100: 450, packGrams: 300);
      await heHad(133, (await finder.matching('Fish cakes')).single);

      final biscuits = (await finder.matching('Oat biscuits')).single;
      expect(biscuits.lastUsedGrams, isNull);
    });
  });
}
