/// Reading back what a meal is made of.
///
/// A meal on the plan has always been a name and a calorie figure. That is
/// enough to plan an evening around and not enough to trust: a figure with
/// nothing behind it cannot be checked, and a wrong one looks exactly like a
/// right one. The Mac Mini has recorded each meal's parts since it was built
/// and no phone code has ever asked for them.
///
/// The carrying test is [a part nobody has said the amount of is named, not
/// dropped]. Everything else here would pass on a version that quietly showed
/// only the parts it had numbers for — which is the version that turns a
/// half-described dinner into a confident-looking list.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late PlanRepository plan;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    final household = HouseholdRepository(ConfigDao(db), api);
    await household.setOwner(mini.aidan);
    plan = PlanRepository(api, household);
  });

  tearDown(() async => db.close());

  /// A chicken traybake, described the way the panel describes one.
  void aTraybake() {
    mini.addMeal(name: 'Chicken traybake', kcal: 620);
    mini.addMealPart(1, 'protein',
        foodName: 'Chicken thighs', qty: 500, unit: 'g', kcal100: 177,
        trust: 'weighed');
    mini.addMealPart(1, 'carbohydrate',
        foodName: 'New potatoes', qty: 600, unit: 'g', kcal100: 75,
        trust: 'typed');
  }

  group('what a meal is made of', () {
    test('comes back with a food and an amount for each part', () async {
      aTraybake();
      final made = await plan.madeOf(1);

      expect(made.isMadeOfParts, isTrue);
      expect(made.parts.map((p) => p.component),
          containsAll(['protein', 'carbohydrate']));
      final protein = made.parts.firstWhere((p) => p.component == 'protein');
      expect(protein.foodName, 'Chicken thighs');
      expect(protein.howMuch, '500 g');
      expect(protein.trust, 'weighed');
    });

    test('a meal out of a packet has no parts, and that is not a failure',
        () async {
      // Most of what this house eats is a packet. Being made of parts is the
      // interesting case, not the normal one, so the ordinary case must not
      // read as something having gone wrong.
      mini.addMeal(name: 'Fish and chips', kcal: 900);
      final made = await plan.madeOf(1);
      expect(made.isMadeOfParts, isFalse);
      expect(made.parts, isEmpty);
    });

    test('a part nobody has said the amount of is named, not dropped',
        () async {
      aTraybake();
      mini.addMealPart(1, 'vegetables', foodName: 'Tenderstem', kcal100: 35);

      final made = await plan.madeOf(1);

      expect(made.parts.length, 3,
          reason: 'the part holding the meal up was left out of the list, so '
              'a half-described dinner reads as a finished one');
      final veg = made.parts.firstWhere((p) => p.component == 'vegetables');
      expect(veg.foodName, 'Tenderstem');
      expect(veg.howMuch, isNull,
          reason: 'a made-up amount is worse than a stated gap');
      expect(made.awaiting.map((p) => p.component), ['vegetables']);
    });

    test('a food the house has but has no calories for is also awaiting',
        () async {
      // A different gap with the same consequence: the meal cannot be added up.
      aTraybake();
      mini.addMealPart(1, 'vegetables',
          foodName: 'Tenderstem', qty: 200, unit: 'g');

      final made = await plan.madeOf(1);
      expect(made.awaiting.map((p) => p.component), ['vegetables']);
      expect(made.parts.firstWhere((p) => p.component == 'vegetables').howMuch,
          '200 g');
    });

    test('a meal with everything said is awaiting nothing', () async {
      aTraybake();
      final made = await plan.madeOf(1);
      expect(made.awaiting, isEmpty);
    });
  });
}
