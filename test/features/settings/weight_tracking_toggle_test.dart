/// Turning weight tracking off hides it. It does not throw anything away.
///
/// Behaviour under test (Release 1, promise 5): weight tracking can be turned on
/// or off per person, and turning it off removes it from view without
/// destroying what was already recorded.
///
/// The test that carries the item is [the weights come back when it is turned
/// on again]. Weights are recorded, the switch goes off, the switch goes back
/// on, and every one of them must still be there — same days, same figures. An
/// implementation that cleared the history on toggle-off would pass "the tab
/// disappears" and fail only here, which is why the round trip is written out
/// rather than stopping at the disappearance.
///
/// Two supporting angles, because "it looks gone" and "it is gone" are easy to
/// confuse: the server's own records are inspected directly while the switch is
/// off, and the app is asked for the history while the switch is off — both must
/// still have it. The switch belongs to the screen, not to the ledger.
/// **What this file no longer covers, and why.** It used to mount a household
/// weight section beside the settings switch and watch the switch hide it. That
/// section is deleted: it sat directly above the app's own weight row on the
/// Profile screen, which is what Aidan hit when he asked why the profile weight
/// ignored the tracking switch. What the switch should hide now that there is
/// one weight row — a row the app needs, because it is where his weight for the
/// calorie calculation comes from — is an open question that has gone to be
/// decided rather than settled here.
///
/// Everything below is the half that does not depend on the answer: the switch
/// belongs to one person, and it changes what is shown and never what is kept.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

import '../household/fake_household_server.dart';

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository repository;
  late Outbox outbox;
  late HouseholdLogger logger;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    final api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    repository = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    logger = HouseholdLogger(repository, outbox);
    await repository.setOwner(mini.aidan);
    await repository.updateSettings(mini.aidan, weightTrackingOn: true);
  });

  tearDown(() async => db.close());

  /// Record some weigh-ins the way the app does — queued on the phone, then
  /// delivered to the server.
  Future<void> recordWeights() async {
    await logger.logWeight(day: '2026-08-17', kg: 82.4);
    await logger.logWeight(day: '2026-08-18', kg: 82.1);
    await logger.logWeight(day: '2026-08-19', kg: 81.9);
    await outbox.drain();
  }

  group('while it is on', () {
    test('the switch is this person\'s own', () async {
      expect((await repository.settings(mini.aidan)).weightTrackingOn, isTrue);
      expect((await repository.settings(mini.emily)).weightTrackingOn, isFalse,
          reason: 'switching it on for one person must not switch it on for '
              'the other');
    });
  });

  group('turning it off', () {
    test('leaves every weigh-in on the server', () async {
      await recordWeights();
      expect(mini.weights, hasLength(3));

      await repository.updateSettings(mini.aidan, weightTrackingOn: false);

      expect(mini.weights, hasLength(3),
          reason: 'the switch changes what is shown, never what is kept');
      expect(mini.weights.map((w) => w['kg']).toList(), [82.4, 82.1, 81.9]);
    });

    test('the history can still be asked for while it is off', () async {
      await recordWeights();
      await repository.updateSettings(mini.aidan, weightTrackingOn: false);

      final still = await repository.weights(mini.aidan);

      expect(still, hasLength(3));
      expect(still.map((w) => w.day).toList(),
          ['2026-08-17', '2026-08-18', '2026-08-19']);
    });

    test('nothing is asked of the server that could remove a weigh-in',
        () async {
      await recordWeights();
      mini.requests.clear();

      await repository.updateSettings(mini.aidan, weightTrackingOn: false);

      // The only traffic is the settings change itself. In particular there is
      // no DELETE, and no second write to the weights the phone already sent.
      expect(mini.requests, ['POST /household/settings/${mini.aidan}']);
    });
  });

  group('turning it back on', () {
    test('with the same days and the same figures as before', () async {
      await recordWeights();
      final before = await repository.weights(mini.aidan);

      await repository.updateSettings(mini.aidan, weightTrackingOn: false);
      await repository.updateSettings(mini.aidan, weightTrackingOn: true);

      expect(await repository.weights(mini.aidan), before);
    });

    test('a weigh-in recorded while it was off is there too', () async {
      // The switch hides a tab. It is not a pause button on the ledger, so
      // anything that did reach the server in the meantime is still counted.
      await recordWeights();
      await repository.updateSettings(mini.aidan, weightTrackingOn: false);
      await logger.logWeight(day: '2026-08-20', kg: 81.6);
      await outbox.drain();

      await repository.updateSettings(mini.aidan, weightTrackingOn: true);

      final after = await repository.weights(mini.aidan);
      expect(after, hasLength(4));
      expect(after.last.day, '2026-08-20');
    });
  });

  group('the two people keep their own', () {
    test('one person turning it off does not turn it off for the other',
        () async {
      await repository.updateSettings(mini.emily, weightTrackingOn: true);

      await repository.updateSettings(mini.aidan, weightTrackingOn: false);

      expect((await repository.settings(mini.emily)).weightTrackingOn, isTrue);
      expect((await repository.settings(mini.aidan)).weightTrackingOn, isFalse);
    });

    test('and does not touch the other person\'s weigh-ins', () async {
      await recordWeights();
      await repository.setOwner(mini.emily);
      await repository.updateSettings(mini.emily, weightTrackingOn: true);
      await logger.logWeight(day: '2026-08-19', kg: 64.2);
      await outbox.drain();

      await repository.updateSettings(mini.aidan, weightTrackingOn: false);

      expect(await repository.weights(mini.emily), hasLength(1));
      expect(await repository.weights(mini.aidan), hasLength(3));
    });
  });
}
