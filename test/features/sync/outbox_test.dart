/// The one queue of work waiting to reach the Mac Mini.
///
/// Behaviour under test (Release 1, promise 10): the app keeps working when it
/// cannot reach the Mini — it says so plainly, anything logged meanwhile is
/// held and sent later exactly once, and nothing is lost if the app is killed
/// while work is waiting.
///
/// Two of these are easy to claim and hard to prove, so they are proved
/// directly rather than by inspection:
///
///  * **Nothing is lost if the app is killed.** The queue is written to a real
///    database file in a temporary directory; the test closes it — which is
///    what a kill leaves behind — and opens it again from scratch. An in-memory
///    database would have made this test pass while proving nothing.
///  * **Exactly once.** The fake server counts what it receives by the id the
///    phone minted, so a resend after a lost reply is visible as a second
///    delivery of the same id, and is asserted not to create a second entry.
///
/// There is also a test that there is only *one* queue, because the plan review
/// found the same queue described twice in two places and two implementations
/// is a failure of this item even if both pass their own tests.
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/outbox_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

/// A stand-in for the Mac Mini that records what it was sent, and can be told
/// to go away.
class FakeMini {
  /// Every request that arrived, in order — including duplicates, which is the
  /// whole point.
  final List<Map<String, dynamic>> received = [];

  /// The entries the server would actually have stored, keyed by the id the
  /// phone minted. A resend of a known id changes nothing here, exactly as the
  /// real server behaves.
  final Map<String, Map<String, dynamic>> stored = {};

  bool reachable = true;

  /// When true, the request is stored but the reply is lost on the way back —
  /// the case the phone cannot tell apart from never having arrived.
  bool loseTheReply = false;

  int get deliveries => received.length;

  http.Client get client => MockClient((request) async {
        if (!reachable) {
          throw http.ClientException('Connection refused', request.url);
        }
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        received.add(body);
        final id = body['client_id'] as String;
        stored.putIfAbsent(id, () => {...body, 'id': stored.length + 1});
        if (loseTheReply) {
          throw http.ClientException('Connection closed', request.url);
        }
        return http.Response(
            jsonEncode({'ok': true, 'entry': stored[id]}), 200,
            headers: {'content-type': 'application/json'});
      });
}

void main() {
  late Directory tempDir;
  late File dbFile;
  late AppDatabase db;
  late FakeMini mini;
  late Outbox outbox;

  AppDatabase openDb() => AppDatabase(NativeDatabase(dbFile));

  Outbox outboxOver(AppDatabase database) => Outbox.of(
      database, HouseholdApi(baseUrl: 'http://mini', client: mini.client));

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('outbox_test');
    dbFile = File('${tempDir.path}/foodtracker.db');
    mini = FakeMini();
    db = openDb();
    outbox = outboxOver(db);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  Future<String> queueAMeal({String label = 'Porridge', int owner = 1}) {
    return outbox.enqueue(
      path: '/household/entry',
      body: {'day': '2026-08-19', 'label': label, 'kcal': 320},
      ownerId: owner,
      authorId: owner,
    );
  }

  group('sending when the Mini is there', () {
    test('work reaches the server and leaves the queue', () async {
      await queueAMeal();
      final result = await outbox.drain();

      expect(result.sent, 1);
      expect(result.remaining, 0);
      expect(result.unreachable, isFalse);
      expect(mini.stored.length, 1);
    });

    test('work is sent oldest first', () async {
      await queueAMeal(label: 'Breakfast');
      await queueAMeal(label: 'Lunch');
      await queueAMeal(label: 'Dinner');

      await outbox.drain();

      expect(mini.received.map((r) => r['label']),
          ['Breakfast', 'Lunch', 'Dinner']);
    });

    test('the person it belongs to travels with it', () async {
      await outbox.enqueue(
        path: '/household/entry',
        body: {'day': '2026-08-19', 'label': 'Risotto', 'kcal': 610},
        ownerId: 2,
        authorId: 1,
      );
      await outbox.drain();

      expect(mini.received.single['owner_id'], 2);
      expect(mini.received.single['author_id'], 1);
    });
  });

  group('when the Mini cannot be reached', () {
    test('the app is told plainly, and nothing is lost', () async {
      mini.reachable = false;
      await queueAMeal();

      final result = await outbox.drain();

      expect(result.unreachable, isTrue);
      expect(result.sent, 0);
      expect(result.remaining, 1);
      expect(mini.deliveries, 0);
    });

    test('work logged while it is away is sent when it comes back', () async {
      mini.reachable = false;
      await queueAMeal(label: 'Breakfast');
      await queueAMeal(label: 'Lunch');
      expect((await outbox.drain()).sent, 0);

      mini.reachable = true;
      final result = await outbox.drain();

      expect(result.sent, 2);
      expect(result.remaining, 0);
      expect(mini.stored.length, 2);
    });

    test('being unreachable is not the same as being refused', () async {
      // A refusal is the server answering. It must not be reported as the Mini
      // being away, or the app tells the person something untrue.
      final refusing = MockClient((request) async => http.Response(
          jsonEncode({'ok': false, 'error': 'no owner given'}), 400,
          headers: {'content-type': 'application/json'}));
      final refused = Outbox.of(
          db, HouseholdApi(baseUrl: 'http://mini', client: refusing));
      await queueAMeal();

      final result = await refused.drain();

      expect(result.unreachable, isFalse);
      expect(result.remaining, 1, reason: 'a refused item is kept, not dropped');
    });
  });

  group('exactly once', () {
    test('a reply lost on the way back does not create a second entry',
        () async {
      mini.loseTheReply = true;
      await queueAMeal();
      await outbox.drain();
      // The phone never learned it worked, so the item is still queued.
      expect(await outbox.pendingCount(), 1);

      mini.loseTheReply = false;
      final result = await outbox.drain();

      expect(result.sent, 1);
      expect(mini.deliveries, 2, reason: 'the phone did send it twice');
      expect(mini.stored.length, 1, reason: 'but only one entry exists');
    });

    test('draining repeatedly sends nothing extra', () async {
      await queueAMeal();
      await outbox.drain();
      await outbox.drain();
      await outbox.drain();

      expect(mini.deliveries, 1);
      expect(await outbox.pendingCount(), 0);
    });

    test('the same work queued twice is queued once', () async {
      final id = await queueAMeal();
      await outbox.enqueue(
        path: '/household/entry',
        body: {'day': '2026-08-19', 'label': 'Porridge', 'kcal': 320},
        ownerId: 1,
        authorId: 1,
        clientId: id,
      );

      expect(await outbox.pendingCount(), 1);
    });
  });

  group('surviving the app being killed', () {
    test('queued work is still there after a restart', () async {
      mini.reachable = false;
      await queueAMeal(label: 'Breakfast');
      await queueAMeal(label: 'Lunch');

      // The app is killed: the database is closed with work still in it.
      await db.close();
      db = openDb();
      outbox = outboxOver(db);

      expect(await outbox.pendingCount(), 2);
      mini.reachable = true;
      final result = await outbox.drain();
      expect(result.sent, 2);
      expect(mini.stored.length, 2);
    });

    test('a restart does not re-send work already confirmed', () async {
      await queueAMeal(label: 'Breakfast');
      await outbox.drain();

      await db.close();
      db = openDb();
      outbox = outboxOver(db);

      final result = await outbox.drain();
      expect(result.sent, 0);
      expect(mini.deliveries, 1);
    });

    test('who it belongs to survives the restart unchanged', () async {
      mini.reachable = false;
      await outbox.enqueue(
        path: '/household/entry',
        body: {'day': '2026-08-19', 'label': 'Toast', 'kcal': 180},
        ownerId: 1,
        authorId: 1,
      );
      await db.close();
      db = openDb();
      outbox = outboxOver(db);

      // The phone changes hands while the work is still waiting. The queued
      // item was stamped when it was logged, so it must be unmoved.
      mini.reachable = true;
      await outbox.drain();

      expect(mini.received.single['owner_id'], 1);
      expect(mini.received.single['author_id'], 1);
    });
  });

  group('there is only one queue', () {
    test('the app has exactly one outbound queue implementation', () async {
      // The review found the connectivity module and the offline queue
      // describing the same thing twice. Two queues means two answers to "have
      // we sent that yet", so this walks the source rather than trusting that
      // nobody added a second one.
      final lib = Directory('lib');
      final suspects = <String>[];
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('outbox.dart') ||
            entity.path.endsWith('outbox_dao.dart') ||
            entity.path.endsWith('outbox_items.dart') ||
            entity.path.endsWith('outbox_sender.dart') ||
            entity.path.endsWith('.g.dart')) {
          continue;
        }
        final source = entity.readAsStringSync();
        if (RegExp(r'class \w*(Outbox|OfflineQueue|PendingQueue|SyncQueue)\w*')
            .hasMatch(source)) {
          suspects.add(entity.path);
        }
      }
      expect(suspects, isEmpty,
          reason: 'a second outbound queue would compete with the first');
    });

    test('the sender keeps no queue of its own', () {
      // outbox_sender.dart is exempt from the sweep above because its name
      // matches while its job does not: it decides *when* to send and holds
      // nothing. That exemption is only safe while it stays true, so this
      // reads the file and checks it never touches the store — no DAO, no
      // table companion, no enqueueing. A sender that started keeping its own
      // list would be the second queue the sweep exists to catch.
      final source =
          File('lib/features/household/data/outbox_sender.dart').readAsStringSync();
      for (final storing in const [
        'OutboxDao',
        'OutboxItemsCompanion',
        'OutboxItem ',
        'enqueue(',
        'AppDatabase',
      ]) {
        expect(source.contains(storing), isFalse,
            reason: 'the sender stores work itself ($storing) — that is a '
                'second queue wearing a different name');
      }
      expect(source.contains('.drain()'), isTrue,
          reason: 'the sender must send through the one queue');
    });

    test('nothing posts to the household server except the queue', () async {
      // The other half of "one queue": a screen that posts directly would
      // bypass the queue entirely and lose the person's work when offline.
      final lib = Directory('lib');
      final direct = <String>[];
      for (final entity in lib.listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (entity.path.endsWith('household_api.dart') ||
            entity.path.endsWith('outbox.dart')) {
          continue;
        }
        final source = entity.readAsStringSync();
        if (RegExp(r"\.post\(\s*'/household/(entry|exercise|weight|food)")
            .hasMatch(source)) {
          direct.add(entity.path);
        }
      }
      expect(direct, isEmpty,
          reason: 'ledger writes must go through the queue, not straight out');
    });
  });

  group('the queue is honest about what is in it', () {
    test('a refused item keeps the reason', () async {
      final refusing = MockClient((request) async => http.Response(
          jsonEncode({'ok': false, 'error': 'no author given'}), 400,
          headers: {'content-type': 'application/json'}));
      final refused = Outbox.of(
          db, HouseholdApi(baseUrl: 'http://mini', client: refusing));
      final id = await queueAMeal();

      await refused.drain();
      final row = await OutboxDao(db).byClientId(id);

      expect(row, isNotNull);
      expect(row!.lastError, contains('author'));
      expect(row.attempts, 1);
    });
  });
}
