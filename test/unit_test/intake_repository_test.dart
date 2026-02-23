import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';

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
