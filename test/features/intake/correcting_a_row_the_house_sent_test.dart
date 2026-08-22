/// Correcting a row that came *from* the house, on the phone.
///
/// Behaviour under test — the four things his walkthrough found on 20 August,
/// where tapping a row on the phone did nothing at all:
///
///  * a spoken row can be corrected by hand — what it was called and what it
///    came to — and the correction reaches the Mac Mini;
///  * it reaches the Mac Mini under the name the *house* knows it by, not the
///    one this phone minted for its own copy. Getting that wrong is silent:
///    the house answers "no row called that has reached here yet" and the
///    correction is simply lost;
///  * moving a row to the other person takes it off this phone's day as well
///    as putting it on theirs, so the two machines do not disagree about
///    somebody's total with nothing to say so;
///  * taking a row off the day takes it off there too.
///
/// The tests drive the use cases rather than the screen, for the same reason
/// the ledger tests do: the screen cannot be stood up without the phone's whole
/// diary behind it, and the part that carries the promise is what ends up where.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/food_item_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/log_entry_dao.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/domain/usecase/delete_intake_usecase.dart';
import 'package:opennutritracker/core/domain/usecase/update_intake_usecase.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import '../household/fake_household_server.dart';

void main() {
  final day = DateTime(2026, 8, 20, 8, 15);

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late IntakeRepository intakes;
  late Outbox outbox;
  late UpdateIntakeUsecase correct;
  late DeleteIntakeUsecase takeOff;

  HouseholdApi api() =>
      HouseholdApi(baseUrl: 'http://mini', client: mini.client);

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final household = HouseholdRepository(ConfigDao(db), api());
    outbox = Outbox.of(db, api());
    final ledger = FoodLedger(HouseholdLogger(household, outbox), api());
    intakes = IntakeRepository(LogEntryDao(db), FoodItemDao(db));
    correct = UpdateIntakeUsecase(intakes, ledger);
    takeOff = DeleteIntakeUsecase(intakes, ledger);
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  /// A row the house worked out from something he said, arriving on the phone
  /// the way the sync brings one in: a fresh local id here, the house's own id
  /// kept alongside it.
  Future<void> aSpokenRowArrives({
    String localId = 'local-1',
    String houseId = 'house-9',
    String label = 'Porridge',
    double kcal = 350,
  }) async {
    await intakes.addQuickAddIntake(
      id: localId,
      externalId: houseId,
      said: 'I had a bowl of porridge',
      label: label,
      kcal: kcal,
      protein: 12,
      carbs: 60,
      fat: 6,
      mealSlot: 'breakfast',
      dateTime: day,
    );
    // The house's own row for it, as the house already holds it.
    mini.entries[houseId] = {
      'client_id': houseId,
      'id': 1,
      'owner_id': mini.aidan,
      'label': label,
      'kcal': kcal,
      'qty': 1,
      'unit': 'serving',
      'protein': 12,
      'fat': 6,
      'carbs': 60,
      'slot': 'breakfast',
      'day': '2026-08-20',
      'deleted_at': null,
      'version': 0,
      'state': 'settled',
    };
  }

  Map<String, dynamic> houseRow(String id) => mini.entries[id]!;

  group('a row that came from the house', () {
    test('the correction reaches the house under the name the house knows',
        () async {
      await aSpokenRowArrives();
      await correct.updateIntake('local-1', {'kcal': 250.0});
      await outbox.drain();

      expect(houseRow('house-9')['kcal'], 250.0,
          reason: 'sent under this phone\'s own id it would 404 and be lost');
      expect(
          mini.requests.where((r) => r.contains('by-client/local-1')), isEmpty);
    });

    test('what it was called can be corrected too', () async {
      await aSpokenRowArrives();
      await correct.updateIntake('local-1', {'label': 'Porridge with honey'});
      await outbox.drain();

      final here = await intakes.getIntakeById('local-1');
      expect(here!.quickAddLabel, 'Porridge with honey');
      expect(houseRow('house-9')['label'], 'Porridge with honey');
    });

    test('what was said is kept, so the guess can be judged against it',
        () async {
      await aSpokenRowArrives();
      final row = await intakes.getIntakeById('local-1');
      expect(row!.said, 'I had a bowl of porridge');
    });

    test('the protein, fat and carbs move with the calories', () async {
      await aSpokenRowArrives(kcal: 350);
      final after = await correct.updateIntake('local-1', {'kcal': 175.0});

      // Half the calories, so half of each of the three.
      expect(after!.totalKcal, 175.0);
      expect(after.totalProteinsGram, 6.0);
      expect(after.totalCarbsGram, 30.0);
      expect(after.totalFatsGram, 3.0);
    });
  });

  group("moving it to Emily's day", () {
    test('it lands on her day at the house', () async {
      await aSpokenRowArrives();
      await correct.updateIntake('local-1', const {}, moveTo: mini.emily);
      await outbox.drain();

      expect(houseRow('house-9')['owner_id'], mini.emily);
    });

    test('and comes off this phone, so his own total drops by it', () async {
      await aSpokenRowArrives();
      await correct.updateIntake('local-1', const {}, moveTo: mini.emily);

      expect(await intakes.getIntakeById('local-1'), isNull,
          reason: 'left here it would go on counting towards a total it is no '
              'longer part of, and the two machines would disagree');
    });

    test('it is moved, not deleted — the house still has it', () async {
      await aSpokenRowArrives();
      await correct.updateIntake('local-1', const {}, moveTo: mini.emily);
      await outbox.drain();

      expect(houseRow('house-9')['deleted_at'], isNull);
      expect(mini.requests.where((r) => r.contains('/retire')), isEmpty);
    });

    test('a move made in the same save as a correction travels with it',
        () async {
      await aSpokenRowArrives();
      await correct
          .updateIntake('local-1', {'kcal': 250.0}, moveTo: mini.emily);
      await outbox.drain();

      final row = houseRow('house-9');
      expect(row['owner_id'], mini.emily);
      expect(row['kcal'], 250.0);
      expect(mini.requests.where((r) => r.contains('/amend')).length, 1,
          reason: 'two messages could half-land and leave both totals wrong '
              'with nothing to say so');
    });
  });

  group('taking it back off the day', () {
    test('it stops counting at the house, under the right name', () async {
      await aSpokenRowArrives();
      final row = await intakes.getIntakeById('local-1');
      await takeOff.deleteIntake(row!);
      await outbox.drain();

      expect(houseRow('house-9')['deleted_at'], isNotNull);
      expect(await intakes.getIntakeById('local-1'), isNull);
    });
  });

  group('a row this phone logged itself', () {
    test('is still corrected under its own id', () async {
      await intakes.addQuickAddIntake(
        id: 'mine-1',
        label: 'Two biscuits',
        kcal: 180,
        mealSlot: 'snack',
        dateTime: day,
      );
      mini.entries['mine-1'] = {
        'client_id': 'mine-1',
        'id': 2,
        'owner_id': mini.aidan,
        'label': 'Two biscuits',
        'kcal': 180,
        'deleted_at': null,
      };

      await correct.updateIntake('mine-1', {'kcal': 90.0});
      await outbox.drain();

      expect(houseRow('mine-1')['kcal'], 90.0);
    });
  });
}
