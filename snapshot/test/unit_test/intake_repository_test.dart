import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import '../fixture/meal_entity_fixtures.dart';

void main() {
  group('IntakeRepository test', () {
    late AppDatabase db;
    late IntakeRepository repo;

    setUp(() {
      db = AppDatabase.createInMemory();
      repo = IntakeRepository(LogEntryDao(db), FoodItemDao(db));
    });

    tearDown(() async {
      await db.close();
    });

    test('returns last added first', () async {
      await repo.addIntake(IntakeEntity(
          id: "1",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealOne,
          dateTime: DateTime.utc(2024, 1, 1, 0, 0, 0)));
      await repo.addIntake(IntakeEntity(
          id: "2",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealTwo,
          dateTime: DateTime.utc(2024, 1, 2, 0, 0, 0)));
      await repo.addIntake(IntakeEntity(
          id: "3",
          unit: "g",
          amount: 1,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealThree,
          dateTime: DateTime.utc(2024, 1, 3, 0, 0, 0)));

      final recents = (await repo.getRecentIntake()).map((e) => e.id).toList();
      expect(recents, List.from(["3", "2", "1"]));
    });

    test('addQuickAddIntake creates entry with null foodItemId', () async {
      final intake = await repo.addQuickAddIntake(
        id: 'qa-1',
        kcal: 400,
        protein: 25,
        carbs: 50,
        fat: 12,
        label: 'Burrito',
        mealSlot: 'lunch',
        dateTime: DateTime.utc(2024, 2, 1, 12, 0, 0),
      );

      expect(intake.id, 'qa-1');
      expect(intake.isQuickAdd, isTrue);
      expect(intake.quickAddLabel, 'Burrito');
      expect(intake.totalKcal, 400);
      expect(intake.totalProteinsGram, 25);
      expect(intake.totalCarbsGram, 50);
      expect(intake.totalFatsGram, 12);
    });

    test('addQuickAddIntake stores correct snapshot values', () async {
      await repo.addQuickAddIntake(
        id: 'qa-2',
        kcal: 200,
        mealSlot: 'snack',
        dateTime: DateTime.utc(2024, 2, 1, 15, 0, 0),
      );

      final fetched = await repo.getIntakeById('qa-2');
      expect(fetched, isNotNull);
      expect(fetched!.isQuickAdd, isTrue);
      expect(fetched.totalKcal, 200);
      expect(fetched.totalProteinsGram, 0);
      expect(fetched.totalCarbsGram, 0);
      expect(fetched.totalFatsGram, 0);
      expect(fetched.quickAddLabel, isNull);
    });

    test('quick-add entries do not appear in getRecentIntake', () async {
      await repo.addIntake(IntakeEntity(
          id: "food-1",
          unit: "g",
          amount: 100,
          type: IntakeTypeEntity.breakfast,
          meal: MealEntityFixtures.mealOne,
          dateTime: DateTime.utc(2024, 1, 1, 8, 0, 0)));

      await repo.addQuickAddIntake(
        id: 'qa-3',
        kcal: 300,
        mealSlot: 'lunch',
        dateTime: DateTime.utc(2024, 1, 1, 12, 0, 0),
      );

      final recents = await repo.getRecentIntake();
      expect(recents.length, 1);
      expect(recents.first.id, 'food-1');
      expect(recents.where((e) => e.isQuickAdd).isEmpty, isTrue);
    });

    test('quick-add entries appear in getIntakeByDateAndType', () async {
      final day = DateTime.utc(2024, 2, 1);

      await repo.addQuickAddIntake(
        id: 'qa-4',
        kcal: 500,
        label: 'Dinner estimate',
        mealSlot: 'dinner',
        dateTime: DateTime.utc(2024, 2, 1, 19, 0, 0),
      );

      final dinnerIntakes =
          await repo.getIntakeByDateAndType(IntakeTypeEntity.dinner, day);
      expect(dinnerIntakes.length, 1);
      expect(dinnerIntakes.first.isQuickAdd, isTrue);
      expect(dinnerIntakes.first.totalKcal, 500);
      expect(dinnerIntakes.first.quickAddLabel, 'Dinner estimate');
    });

    test('quick-add entries cannot be updated via amount change', () async {
      await repo.addQuickAddIntake(
        id: 'qa-5',
        kcal: 300,
        mealSlot: 'snack',
        dateTime: DateTime.utc(2024, 2, 1, 15, 0, 0),
      );

      final result = await repo.updateIntake('qa-5', {'amount': 2.0});
      expect(result, isNull);
    });

    test('quick-add entries count toward a slot total alongside food',
        () async {
      final day = DateTime.utc(2024, 3, 1);

      // A food entry: 200g of a 150 kcal/100g food = 300 kcal.
      await repo.addIntake(IntakeEntity(
        id: 'food-mix',
        unit: 'g',
        amount: 200,
        type: IntakeTypeEntity.lunch,
        meal: MealEntity(
          code: 'mix-food',
          name: 'Mixed food',
          url: null,
          mealQuantity: null,
          mealUnit: 'g',
          servingQuantity: null,
          servingUnit: 'g',
          servingSize: null,
          nutriments: const MealNutrimentsEntity(
            energyKcal100: 150,
            proteins100: 10,
            carbohydrates100: 20,
            fat100: 5,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null,
          ),
          source: MealSourceEntity.custom,
        ),
        dateTime: DateTime.utc(2024, 3, 1, 12, 0, 0),
      ));

      // A quick-add estimate in the same slot: 450 kcal.
      await repo.addQuickAddIntake(
        id: 'qa-mix',
        kcal: 450,
        protein: 30,
        carbs: 40,
        fat: 15,
        label: 'Estimate',
        mealSlot: 'lunch',
        dateTime: DateTime.utc(2024, 3, 1, 12, 30, 0),
      );

      final lunch =
          await repo.getIntakeByDateAndType(IntakeTypeEntity.lunch, day);
      expect(lunch.length, 2);

      // Same reduction HomeBloc.getTotalKcal performs across a slot list.
      final totalKcal =
          lunch.fold<double>(0, (sum, i) => sum + i.totalKcal);
      final totalProtein =
          lunch.fold<double>(0, (sum, i) => sum + i.totalProteinsGram);
      expect(totalKcal, 300 + 450);
      expect(totalProtein, 20 + 30);
    });

    test('quick-add entries can be deleted', () async {
      final intake = await repo.addQuickAddIntake(
        id: 'qa-6',
        kcal: 150,
        mealSlot: 'snack',
        dateTime: DateTime.utc(2024, 2, 1, 10, 0, 0),
      );

      await repo.deleteIntake(intake);
      final fetched = await repo.getIntakeById('qa-6');
      expect(fetched, isNull);
    });
  });
}
