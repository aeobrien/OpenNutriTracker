/// A refused search is asked again before anybody is told it failed.
///
/// Open Food Facts spent 24 August 2026 refusing a good share of what it was
/// asked, at random rather than in outages: 39 searches spread across an hour,
/// against the address this app actually uses, came back 14 good and 25
/// refused, and the refusals arrived in runs of one to four with no stretch
/// longer than about six minutes. Of the 25 refusals, 13 came back on a second
/// ask a second later and 5 more on a third. So three asks turn 36% into 82%,
/// and the second ask alone does most of the work.
///
/// The refusal is theirs and it is quick — a page of HTML in about a fifth of a
/// second, carrying no instruction to wait — so asking again costs a second at
/// worst, and only on a search that was going to show an error anyway.
///
/// It is deliberately narrow. Only their three "we are not answering" codes are
/// asked again. A 404, a wrong answer, or a request that timed out are all
/// things a second ask would not mend, and the measurement covered none of them.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // The data source names itself to Open Food Facts in its user agent, and the
  // version it uses comes from the app bundle, which does not exist here.
  setUpAll(() => PackageInfo.setMockInitialValues(
        appName: 'FoodTracker',
        packageName: 'com.aeobrien.foodtracker',
        version: '1.0.0',
        buildNumber: '0',
        buildSignature: '',
      ));

  /// A search result with nothing in it, which is a perfectly good 200.
  final emptyButFine = jsonEncode({'count': 0, 'page': 1, 'products': []});

  /// A client that answers with [answers] in order, and records how many times
  /// it was asked.
  ({http.Client client, List<Uri> asked}) serverThatSays(List<int> answers) {
    final asked = <Uri>[];
    final client = MockClient((request) async {
      final i = asked.length;
      asked.add(request.url);
      final code = i < answers.length ? answers[i] : answers.last;
      return code == 200
          ? http.Response(emptyButFine, 200)
          : http.Response('<html>Page temporarily unavailable</html>', code,
              headers: {'content-type': 'text/html'});
    });
    return (client: client, asked: asked);
  }

  group('a search Open Food Facts refuses', () {
    test('is asked again, and the second answer is the one used', () async {
      final server = serverThatSays([503, 200]);
      final result = await OFFDataSource(client: server.client)
          .fetchSearchWordResults('peanut butter');

      expect(server.asked, hasLength(2));
      expect(result.products, isEmpty);
    });

    test('is asked a third time if the second is refused too', () async {
      final server = serverThatSays([503, 503, 200]);
      await OFFDataSource(client: server.client)
          .fetchSearchWordResults('peanut butter');

      expect(server.asked, hasLength(3));
    });

    test('is not asked a fourth time, and the failure is passed on', () async {
      final server = serverThatSays([503, 503, 503]);

      await expectLater(
        OFFDataSource(client: server.client)
            .fetchSearchWordResults('peanut butter'),
        throwsA(503),
      );
      expect(server.asked, hasLength(3));
    });

    test('asks for exactly the same thing each time', () async {
      final server = serverThatSays([503, 503, 200]);
      await OFFDataSource(client: server.client)
          .fetchSearchWordResults('peanut butter');

      expect(server.asked.toSet(), hasLength(1));
      expect(server.asked.first.queryParameters['search_terms'],
          'peanut butter');
    });

    test('and their other two down codes are asked again as well', () async {
      for (final code in [500, 502]) {
        final server = serverThatSays([code, 200]);
        await OFFDataSource(client: server.client)
            .fetchSearchWordResults('oats');
        expect(server.asked, hasLength(2), reason: '$code should be retried');
      }
    });
  });

  group('a search that is not refused', () {
    test('is asked once', () async {
      final server = serverThatSays([200]);
      await OFFDataSource(client: server.client)
          .fetchSearchWordResults('peanut butter');

      expect(server.asked, hasLength(1));
    });

    test('and a plain refusal that is not theirs is not asked again', () async {
      final server = serverThatSays([404, 200]);

      await expectLater(
        OFFDataSource(client: server.client).fetchSearchWordResults('oats'),
        throwsA(404),
      );
      expect(server.asked, hasLength(1),
          reason: 'a second ask would not mend a 404');
    });
  });
}
