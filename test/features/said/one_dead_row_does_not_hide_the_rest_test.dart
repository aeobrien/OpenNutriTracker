/// A row the Mac Mini will not settle does not end the catch-up.
///
/// Written from his own ledger on the evening of 21 August 2026. Three rows sat
/// unfinished on his day: two from earlier, recorded but never transcribed and
/// with no words left on them, and one typed that same evening which would have
/// settled perfectly well. The catch-up walks them oldest first.
///
/// The Mini refuses a row with no words — correctly, there is nothing to work
/// out. But a refusal came back out of workOut as a thrown error rather than as
/// a fact about that one row, so the first dead row ended the whole pass and the
/// live one behind it was never reached. From the outside that is
/// indistinguishable from the catch-up not running at all.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/said/data/clip_store.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.createInMemory();
    // ClipStore keeps recordings in the app's own folder, which on a real phone
    // comes from the platform. Nothing here has one, and the recordings are
    // beside the point — the rows under test have no clip left anyway.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => Directory.systemTemp
          .createTempSync('catch-up-test')
          .path,
    );
  });
  tearDown(() async => db.close());

  /// The rows as they stood on his day: two with nothing left to work out, and
  /// one typed that evening.
  const unfinished = [
    LoggedItem(
        label: SaidRepository.notHeardYet,
        ownerId: 1,
        authorId: 1,
        clientId: 'a-recording-with-no-words-left',
        state: 'provisional'),
    LoggedItem(
        label: SaidRepository.notHeardYet,
        ownerId: 1,
        authorId: 1,
        clientId: 'another-one-just-like-it',
        state: 'provisional'),
    LoggedItem(
        label: 'two slices of whole meal toast with butter',
        said: 'two slices of whole meal toast with butter',
        ownerId: 1,
        authorId: 1,
        clientId: 'the-one-he-typed-tonight',
        state: 'provisional'),
  ];

  test('the row it can settle is still reached', () async {
    final asked = <String>[];
    final client = MockClient((request) async {
      if (!request.url.path.endsWith('/said')) {
        return http.Response(jsonEncode({'ok': true}), 200);
      }
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      final who = body['client_id'] as String;
      asked.add(who);
      if (who == 'the-one-he-typed-tonight') {
        return http.Response(
            jsonEncode({'ok': true, 'applied': true, 'said': 'toast'}), 200);
      }
      // What the Mini says about a row with nothing left on it.
      return http.Response(
          jsonEncode({'ok': false, 'error': 'nothing was said'}), 400);
    });

    final api = HouseholdApi(baseUrl: 'http://mini', client: client);
    final repo = HouseholdRepository(ConfigDao(db), api);
    final outbox = Outbox.of(db, api);
    final said = SaidRepository(
        api, HouseholdLogger(repo, outbox), outbox, ClipStore());

    final caught = await said.catchUp(unfinished);

    expect(asked, hasLength(3),
        reason: 'every unfinished row was asked about, not just the ones '
            'before the first refusal');
    expect(asked.last, 'the-one-he-typed-tonight');
    expect(caught.settled, 1);
  });
}
