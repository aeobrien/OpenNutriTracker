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
  });
}
