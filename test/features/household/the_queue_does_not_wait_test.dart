/// Something put on the queue goes now, not the next time the app is opened.
///
/// Behaviour under test: [OutboxSender] sends as soon as [Outbox.enqueue] is
/// called, without anything else happening first.
///
/// This is written from what the app actually did on 20 August 2026. Typing a
/// weight into Profile showed the new figure on the phone straight away and
/// did not put it on the household's ledger at all — the queue logged
/// "[OUTBOX] queued /household/weight" and then sat on it. Backgrounding the
/// app and bringing it back sent it immediately.
///
/// The reason was that nothing watched the queue. Sending was tried when the
/// sender started, when the app came back to the front, and on a two-minute
/// timer that was only ever set if a previous attempt had left something
/// behind. A queue that was empty when the app opened therefore had nothing
/// scheduled at all, and the first thing added after that waited for a resume
/// that might not come for hours. For as long as somebody kept looking at the
/// phone, the phone and the kitchen panel disagreed about his weight.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/household/data/outbox_sender.dart';

import 'fake_household_server.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late Outbox outbox;
  late OutboxSender sender;

  setUp(() {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    outbox = Outbox.of(db, HouseholdApi(baseUrl: 'http://mini', client: mini.client));
    sender = OutboxSender(outbox);
  });

  tearDown(() async {
    sender.stop();
    await db.close();
  });

  Future<void> enqueueAWeight() => outbox.enqueue(
        path: '/household/weight',
        body: {'person_id': 1, 'kg': 114.8, 'day': '2026-08-20'},
        ownerId: 1,
        authorId: 1,
      );

  test('a weight typed after the app opened reaches the household', () async {
    sender.start();
    await pumpEventQueue();
    expect(mini.weights, isEmpty, reason: 'nothing has been typed yet');

    await enqueueAWeight();
    await pumpEventQueue();

    expect(mini.weights.length, 1,
        reason: 'it was still sitting on the queue when he looked at the panel');
    expect(mini.weights.single['kg'], 114.8);
    expect(await outbox.pendingCount(), 0);
  });

  test('nothing is sent once the sender has been stopped', () async {
    sender.start();
    await pumpEventQueue();
    sender.stop();

    await enqueueAWeight();
    await pumpEventQueue();

    expect(mini.weights, isEmpty);
    expect(await outbox.pendingCount(), 1,
        reason: 'held for the next time, not thrown away');
  });
}
