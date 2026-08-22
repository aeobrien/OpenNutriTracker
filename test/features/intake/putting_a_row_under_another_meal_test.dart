/// Moving a row from one meal of the day to another.
///
/// Release 7, the last of the four gaps the audit named: the Mac Mini has
/// accepted a corrected slot since the day it could accept a correction at
/// all, and the phone had no way to ask for one. Until this, a lunch logged
/// under dinner could only be removed and logged again — which loses when it
/// was eaten and who entered it.
///
/// What is held here:
///
///  * the row moves here *and* at the house, in one correction;
///  * a correction that did not touch the meal sends no meal, so a row the
///    house never pinned to a slot is not quietly pinned by an unrelated fix;
///  * moving the meal on its own still hands the row back, so the day's total
///    does not lose a meal nobody removed.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import '../household/fake_household_server.dart';

void main() {
  final day = DateTime(2026, 8, 22, 13, 5);

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

  /// A sandwich he ate at lunchtime and logged under dinner, on both machines.
  /// The house's copy is given a *different* slot on purpose in one test
  /// below — here they agree, as they normally would.
  Future<void> aRowUnder(String slot, {String houseSlot = ''}) async {
    await intakes.addQuickAddIntake(
      id: 'local-1',
      externalId: 'house-9',
      label: 'Cheese sandwich',
      kcal: 420,
      protein: 18,
      carbs: 44,
      fat: 19,
      mealSlot: slot,
      dateTime: day,
    );
    mini.entries['house-9'] = {
      'client_id': 'house-9',
      'id': 1,
      'owner_id': mini.aidan,
      'label': 'Cheese sandwich',
      'kcal': 420,
      'qty': 1,
      'unit': 'serving',
      'protein': 18,
      'fat': 19,
      'carbs': 44,
      'slot': houseSlot.isEmpty ? slot : houseSlot,
      'day': '2026-08-22',
      'deleted_at': null,
      'version': 0,
      'state': 'settled',
    };
  }

  group('a row logged under the wrong meal', () {
    test('moves to the right one on this phone', () async {
      await aRowUnder('dinner');
      await correct.updateIntake('local-1', {'slot': 'lunch'});

      final here = await intakes.getIntakeById('local-1');
      expect(here!.type, IntakeTypeEntity.lunch);
    });

    test('and moves at the house too', () async {
      await aRowUnder('dinner');
      await correct.updateIntake('local-1', {'slot': 'lunch'});
      await outbox.drain();

      expect(mini.entries['house-9']!['slot'], 'lunch');
    });

    test('it is corrected, not removed and logged again', () async {
      await aRowUnder('dinner');
      await correct.updateIntake('local-1', {'slot': 'lunch'});
      await outbox.drain();

      // Same row, still counting, with its own history intact. A remove-and-
      // relog would lose when it was eaten and who entered it.
      expect(mini.entries['house-9']!['deleted_at'], isNull);
      expect(mini.requests.where((r) => r.contains('/retire')), isEmpty);
      expect(mini.requests.where((r) => r.contains('/amend')).length, 1);
    });

    test('the meal it now sits under is what the day is drawn from', () async {
      await aRowUnder('dinner');
      await correct.updateIntake('local-1', {'slot': 'lunch'});

      final lunch =
          await intakes.getIntakeByDateAndType(IntakeTypeEntity.lunch, day);
      final dinner =
          await intakes.getIntakeByDateAndType(IntakeTypeEntity.dinner, day);
      expect(lunch.map((r) => r.id), ['local-1']);
      expect(dinner, isEmpty);
    });

    test('the figures are left exactly alone', () async {
      await aRowUnder('dinner');
      final after = await correct.updateIntake('local-1', {'slot': 'lunch'});

      expect(after, isNotNull,
          reason: 'the caller takes what the row was off the day and puts '
              'what it now is back on — answering null here takes a meal off '
              'the total and never puts it back');
      expect(after!.totalKcal, 420);
      expect(after.totalProteinsGram, 18);
      expect(after.totalCarbsGram, 44);
      expect(after.totalFatsGram, 19);
    });
  });

  group('a correction that was not about the meal', () {
    test('sends no meal at all', () async {
      // The house has this row under a slot of its own — it worked one out
      // from the clock when nobody said. Correcting the calories must not
      // overwrite that with whatever this phone happens to show.
      await aRowUnder('snack', houseSlot: 'breakfast');
      await correct.updateIntake('local-1', {'kcal': 300.0});
      await outbox.drain();

      expect(mini.entries['house-9']!['slot'], 'breakfast');
    });
  });

  group('the meal and something else, corrected together', () {
    test('both land, in one correction', () async {
      await aRowUnder('dinner');
      await correct
          .updateIntake('local-1', {'kcal': 300.0, 'slot': 'lunch'});
      await outbox.drain();

      final row = mini.entries['house-9']!;
      expect(row['slot'], 'lunch');
      expect(row['kcal'], 300.0);
      expect(mini.requests.where((r) => r.contains('/amend')).length, 1,
          reason: 'two messages could half-land');
    });

    test('and the move to the other person travels with them', () async {
      await aRowUnder('dinner');
      await correct.updateIntake('local-1', {'slot': 'lunch'},
          moveTo: mini.emily);
      await outbox.drain();

      final row = mini.entries['house-9']!;
      expect(row['slot'], 'lunch');
      expect(row['owner_id'], mini.emily);
      expect(mini.requests.where((r) => r.contains('/amend')).length, 1);
    });
  });
}
