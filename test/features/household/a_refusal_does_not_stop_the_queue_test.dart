/// One item the server will never accept does not hold up everything behind it.
///
/// Written from what the phone actually did on the evening of 21 August 2026.
/// Adding food by voice had stopped working. The address in Settings looked
/// wrong, and it was not: the phone was talking to the Mac Mini perfectly well
/// and making dozens of successful calls a minute.
///
/// What was actually happening: one item near the front of the queue was
/// posting to a URL a since-replaced build had minted — the retire route with
/// its last segment missing. The Mini answered that 405, as an HTML page,
/// because a routing error never reaches the code that would have written a
/// JSON one. The app read "not JSON" the only way it could, as the Mini being
/// unreachable, and the queue stops at the first sign of unreachable on
/// purpose. So it stopped there, every time, for hours — and a sentence
/// somebody had just spoken onto their day sat behind it and never left the
/// phone.
///
/// Two rules come out of that, and this file holds both:
///
///   * a refusal is a refusal whatever it is written in, and
///   * the queue steps over a refusal rather than stopping on it.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;

  setUp(() => db = AppDatabase.createInMemory());
  tearDown(() async => db.close());

  /// Every path this stand-in was asked for, in order.
  final asked = <String>[];

  /// A Mini that refuses one particular URL the way the real one did — with an
  /// HTML error page, which is what a routing error looks like on any Flask
  /// server that has not been taught otherwise.
  http.Client miniThatRefusesInHtml() {
    asked.clear();
    return MockClient((request) async {
      asked.add(request.url.path);
      if (request.url.path.startsWith('/household/entry/by-client/')) {
        return http.Response(
          '<!doctype html>\n<html lang=en>\n<title>405 Method Not Allowed</title>\n'
          '<h1>Method Not Allowed</h1>\n',
          405,
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }
      return http.Response(jsonEncode({'ok': true}), 200,
          headers: {'content-type': 'application/json'});
    });
  }

  Outbox queueAgainst(http.Client client) =>
      Outbox.of(db, HouseholdApi(baseUrl: 'http://mini', client: client));

  test('a refusal written in HTML is still a refusal, not an absent Mini',
      () async {
    final outbox = queueAgainst(miniThatRefusesInHtml());
    await outbox.enqueue(
      path: '/household/entry/by-client/a-row-an-older-build-named/retire',
      body: const {},
      ownerId: 1,
      authorId: 1,
    );

    final result = await outbox.drain();

    expect(result.unreachable, isFalse,
        reason: 'the Mini answered — it just said no. Calling that unreachable '
            'is what stopped the queue.');
  });

  test('the sentence behind it still reaches the Mac Mini', () async {
    final outbox = queueAgainst(miniThatRefusesInHtml());
    // The order matters: the item that will be refused is queued first, so it
    // is the one the drain reaches first.
    await outbox.enqueue(
      path: '/household/entry/by-client/a-row-an-older-build-named/retire',
      body: const {},
      ownerId: 1,
      authorId: 1,
    );
    await outbox.enqueue(
      path: '/household/entry',
      body: const {'label': 'Something you said', 'kcal': 0},
      ownerId: 1,
      authorId: 1,
    );

    final result = await outbox.drain();

    expect(asked, contains('/household/entry'),
        reason: 'this is the row somebody spoke onto their day');
    expect(result.sent, 1);
  });

  test('a server in real trouble does still stop the queue', () async {
    // The other half of the rule. A 5xx means the Mini itself is unwell, and
    // working through the rest of the queue to collect the same answer fifty
    // times helps nobody. Only a refusal is stepped over.
    asked.clear();
    final outbox = queueAgainst(MockClient((request) async {
      asked.add(request.url.path);
      return http.Response('upstream is on fire', 502,
          headers: {'content-type': 'text/plain'});
    }));
    await outbox.enqueue(
        path: '/household/entry', body: const {}, ownerId: 1, authorId: 1);
    await outbox.enqueue(
        path: '/household/weight', body: const {}, ownerId: 1, authorId: 1);

    final result = await outbox.drain();

    expect(result.unreachable, isTrue);
    expect(asked, hasLength(1), reason: 'it stopped rather than working through');
  });

  test('a second drain waits for the one already running instead of saying all '
      'is well', () async {
    // Saying what you ate drains the queue and then asks the Mini about the row
    // it just queued, because a question about a row the Mini has never heard
    // of is a plain 404. That only holds if the drain it waited on was a real
    // one.
    var inFlight = 0;
    var seenAtOnce = 0;
    final outbox = queueAgainst(MockClient((request) async {
      inFlight += 1;
      if (inFlight > seenAtOnce) seenAtOnce = inFlight;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      inFlight -= 1;
      return http.Response(jsonEncode({'ok': true}), 200,
          headers: {'content-type': 'application/json'});
    }));
    await outbox.enqueue(
        path: '/household/entry', body: const {}, ownerId: 1, authorId: 1);

    final first = outbox.drain();
    final second = outbox.drain();
    final results = await Future.wait([first, second]);

    expect(seenAtOnce, 1, reason: 'the second one waited rather than starting '
        'its own');
    for (final r in results) {
      expect(r.remaining, 0,
          reason: 'both callers were told the truth about the queue');
    }
    expect(results[1].sent, 1,
        reason: 'the second caller must not be told nothing was sent — that '
            'reads exactly like an empty queue, and is what sent a question '
            'about a row still sitting in it');
  });
}
