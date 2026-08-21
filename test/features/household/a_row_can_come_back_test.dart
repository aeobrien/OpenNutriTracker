/// Undoing a removal, at the house as well as on the phone.
///
/// Until 21 August 2026 the house was only ever told to stop counting
/// something. Undo put the row back on the phone and the Mac Mini went on
/// counting it as gone — and the phone looked entirely correct while it
/// happened, which is why nobody noticed. The disagreement lived on the other
/// side of the wire.
///
/// So every check here reads what reached the house, not what the phone shows.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import 'fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late Outbox outbox;
  late FoodLedger ledger;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    final household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    ledger = FoodLedger(HouseholdLogger(household, outbox));
    await household.setOwner(mini.aidan);
  });

  tearDown(() async => db.close());

  Future<void> ate(String intakeId, String label, num kcal) async {
    await ledger.add(
      intakeId: intakeId,
      day: DateTime(2026, 8, 21),
      slot: 'snack',
      label: label,
      liquid: false,
      mine: 1,
      kcalPerUnit: kcal,
    );
    await outbox.drain();
  }

  /// What the house says is still counting on that day.
  num counted() => mini.entries.values
      .where((e) => e['deleted_at'] == null)
      .fold<num>(0, (sum, e) => sum + ((e['kcal'] ?? 0) as num));

  test('the house counts it again after it is put back', () async {
    await ate('keep-1', 'Porridge', 250);
    await ate('undo-1', 'Flapjack', 300);
    expect(counted(), 550);

    await ledger.retire('undo-1');
    await outbox.drain();
    expect(counted(), 250, reason: 'retiring stops the house counting it');

    await ledger.putBack('undo-1');
    await outbox.drain();
    expect(counted(), 550, reason: 'and putting it back starts it again');
  });

  test('the same row comes back, not a second one', () async {
    // A new row would make the total right and the day wrong: two entries at
    // the house where the person had one thing.
    await ate('undo-2', 'Flapjack', 300);
    await ledger.retire('undo-2');
    await outbox.drain();
    await ledger.putBack('undo-2');
    await outbox.drain();

    expect(mini.entries.length, 1);
    expect(mini.entries['undo-2']!['deleted_at'], isNull);
  });

  test('it goes on the queue, so undoing on a train works', () async {
    await ate('undo-3', 'Flapjack', 300);
    await ledger.retire('undo-3');
    await outbox.drain();

    mini.reachable = false;
    await ledger.putBack('undo-3');
    await outbox.drain();
    expect(counted(), 0, reason: 'nothing reached the house yet');

    mini.reachable = true;
    await outbox.drain();
    expect(counted(), 300, reason: 'and it lands when the house is back');
  });

  test('putting back a row the house has never heard of does not throw',
      () async {
    // The original write may still be sitting in the queue behind this. A 404
    // is not something to crash the screen over.
    await ledger.putBack('never-arrived');
    await outbox.drain();
    expect(counted(), 0);
  });
}
