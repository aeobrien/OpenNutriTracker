/// When the old search has refused five times, the newer one answers instead.
///
/// Measured on 1 September 2026, three services in one window, twenty requests
/// each at human pace:
///
///   * the old search, `world.openfoodfacts.org/cgi/search.pl`, answered
///     **7 of 20** — and it had answered 40–48% of the time that same morning,
///     so it is getting worse rather than better;
///   * the newer one, `search.openfoodfacts.org`, answered **20 of 20**;
///   * the per-product lookup, on the same host as the failing search,
///     answered **20 of 20** and is untouched by whatever ails the search.
///
/// So why fall back rather than move? Because the old one is *better when it
/// answers*, which is the thing measuring only availability missed. Same term,
/// same minute: "tesco milk" on the old service returned 50 results, all 50
/// carrying calories, including semi-skimmed milk. On the newer one it returned
/// 20, of which 10 had calories — milk chocolate lollipops, raisins, orange
/// cookies and Christmas puddings, with no milk in the top four.
///
/// Aidan chose this shape after reading both: "Yes, do the fallback for mantel."
/// The good list nine times in ten, a usable list the tenth, and the error
/// screen only when neither service will speak.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:opennutritracker/features/add_meal/data/data_sources/off_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => PackageInfo.setMockInitialValues(
        appName: 'FoodTracker',
        packageName: 'com.aeobrien.foodtracker',
        version: '1.0.0',
        buildNumber: '0',
        buildSignature: '',
      ));

  /// The old service answering with one real product.
  final oldSaysMilk = jsonEncode({
    'count': 1,
    'page': 1,
    'products': [
      {
        'code': '5000436589217',
        'product_name': 'SEMI SKIMMED MILK',
        'brands': 'TESCO',
        'quantity': '2.27 l',
        'serving_quantity': 250,
        'serving_size': '250 ml',
        'nutriments': {'energy-kcal_100g': 50},
      }
    ],
  });

  /// The newer service's own shape — `hits`, not `products`, and brands as a
  /// list rather than a string.
  final newSaysLollipops = jsonEncode({
    'count': 10000,
    'page': 1,
    'page_size': 50,
    'hits': [
      {
        'code': '5051140587956',
        'product_name': 'tesco milk chocolate lollipops',
        'product_name_en': 'tesco milk chocolate lollipops',
        'brands': ['Tesco'],
        'image_front_url': 'https://images.openfoodfacts.org/a.jpg',
        'nutriments': {'energy-kcal_100g': 451, 'proteins_100g': 5.4},
      }
    ],
  });

  /// A server that knows both addresses and can be told what each should do.
  ({http.Client client, List<Uri> old, List<Uri> other}) twoServices({
    required List<int> oldSays,
    int otherSays = 200,
  }) {
    final oldAsked = <Uri>[];
    final otherAsked = <Uri>[];
    final client = MockClient((request) async {
      if (request.url.host == 'search.openfoodfacts.org') {
        otherAsked.add(request.url);
        return otherSays == 200
            ? http.Response(newSaysLollipops, 200)
            : http.Response('no', otherSays);
      }
      final i = oldAsked.length;
      oldAsked.add(request.url);
      final code = i < oldSays.length ? oldSays[i] : oldSays.last;
      return code == 200
          ? http.Response(oldSaysMilk, 200)
          : http.Response('<html>Page temporarily unavailable</html>', code,
              headers: {'content-type': 'text/html'});
    });
    return (client: client, old: oldAsked, other: otherAsked);
  }

  group('while the old service is answering', () {
    test('the newer one is never asked at all', () async {
      final s = twoServices(oldSays: [200]);
      final got = await OFFDataSource(client: s.client)
          .fetchSearchWordResults('tesco milk');

      expect(s.other, isEmpty, reason: 'the better list was available');
      expect(got.secondChoice, isFalse);
      expect(got.response.products.single.product_name, 'SEMI SKIMMED MILK');
    });

    test('and it is still not asked when the old one answers on the fifth try',
        () async {
      final s = twoServices(oldSays: [503, 503, 503, 503, 200]);
      final got = await OFFDataSource(client: s.client)
          .fetchSearchWordResults('tesco milk');

      expect(s.old, hasLength(5));
      expect(s.other, isEmpty);
      expect(got.secondChoice, isFalse);
    });
  });

  group('when the old service has refused all five', () {
    test('the newer one is asked, once, and its results come back', () async {
      final s = twoServices(oldSays: [503, 503, 503, 503, 503]);
      final got = await OFFDataSource(client: s.client)
          .fetchSearchWordResults('tesco milk');

      expect(s.old, hasLength(5));
      expect(s.other, hasLength(1), reason: 'one ask, not another five');
      expect(got.secondChoice, isTrue);
      expect(got.response.products.single.product_name,
          'tesco milk chocolate lollipops');
    });

    test('it is asked for the same words the person typed', () async {
      final s = twoServices(oldSays: [503, 503, 503, 503, 503]);
      await OFFDataSource(client: s.client)
          .fetchSearchWordResults('waitrose milk');

      expect(s.other.single.queryParameters['q'], 'waitrose milk');
    });

    test('and what comes back is read the way that service writes it',
        () async {
      // Its answer is not the old one's answer with a different address on it.
      // The list is called `hits`, and a brand is a list of names rather than
      // one string.
      final s = twoServices(oldSays: [503, 503, 503, 503, 503]);
      final got = await OFFDataSource(client: s.client)
          .fetchSearchWordResults('tesco milk');

      final p = got.response.products.single;
      expect(p.code, '5051140587956');
      expect(p.brands, 'Tesco');
      expect(p.nutriments.energy_kcal_100g, 451);
      expect(p.image_front_url, 'https://images.openfoodfacts.org/a.jpg');
    });

    test('and it carries no serving size, which is why he is told', () async {
      // The newer service returns none, for any product. That changes what the
      // app can offer — a food with no serving size is never offered "per
      // serving" — so it is said on screen rather than left to be noticed.
      final s = twoServices(oldSays: [503, 503, 503, 503, 503]);
      final got = await OFFDataSource(client: s.client)
          .fetchSearchWordResults('tesco milk');

      final p = got.response.products.single;
      expect(p.serving_size, isNull);
      expect(p.serving_quantity, isNull);
    });
  });

  group('when neither service will speak', () {
    test('the failure is passed on, and the error screen is still right',
        () async {
      final s = twoServices(oldSays: [503, 503, 503, 503, 503], otherSays: 502);

      await expectLater(
        OFFDataSource(client: s.client).fetchSearchWordResults('tesco milk'),
        throwsA(anything),
      );
      expect(s.old, hasLength(5));
      expect(s.other, hasLength(1));
    });
  });

  group('a refusal that is not a refusal', () {
    test('a 404 does not reach the newer service', () async {
      // The fallback is for "it would not answer", which is what was measured.
      // A 404 is an answer, and a second service would not mend it.
      final s = twoServices(oldSays: [404]);

      await expectLater(
        OFFDataSource(client: s.client).fetchSearchWordResults('oats'),
        throwsA(404),
      );
      expect(s.old, hasLength(1));
      expect(s.other, isEmpty);
    });
  });
}
