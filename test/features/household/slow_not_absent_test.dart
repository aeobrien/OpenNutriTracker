/// A Mini that is being slow must not be described as a Mini that is not there.
///
/// On 19 August Aidan photographed a packet, tapped "read the packet", and was
/// told the phone could not reach the kitchen computer. The server had read the
/// packet and answered him; the phone had stopped waiting after fifteen
/// seconds, because a three-photograph reading job was given the same allowance
/// as fetching one number. He had seen the identical sentence earlier that
/// morning when the cause really was the network, so the app had spent the day
/// telling him the same thing about two different faults.
///
/// These tests hold both halves of the fix: reading a packet gets its own,
/// much longer allowance, and running out of time says so in its own words.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/label_scan/data/household_label_reader.dart';

/// A server that takes [delay] to answer anything, then answers [body].
http.Client slowServer(Duration delay, {Map<String, dynamic> body = const {}}) {
  return MockClient((request) async {
    await Future<void>.delayed(delay);
    return http.Response(jsonEncode(body), 200);
  });
}

void main() {
  group('an ordinary call', () {
    test('gives up after ten seconds, not fifteen', () {
      expect(HouseholdApi.ordinary, const Duration(seconds: 10));
    });

    test('running out of time is reported as slowness, not absence', () async {
      final api = HouseholdApi(
        baseUrl: 'http://mini.test',
        client: slowServer(const Duration(seconds: 30)),
      );
      await expectLater(
        api.get('/household/people', timeout: const Duration(milliseconds: 20)),
        throwsA(isA<HouseholdTooSlow>()),
      );
    });

    test('and the sentence the person is shown says which one it was',
        () async {
      final api = HouseholdApi(
        baseUrl: 'http://mini.test',
        client: slowServer(const Duration(seconds: 30)),
      );
      try {
        await api.get('/household/people',
            timeout: const Duration(milliseconds: 20));
        fail('should not have answered');
      } on HouseholdUnreachable catch (e) {
        expect(e.headline, 'The kitchen computer is taking too long to answer');
        expect(e.headline, isNot(contains("Can't reach")));
      }
    });

    test('a Mini that really is not there still says so', () {
      final absent = HouseholdUnreachable('no route to host');
      expect(absent.headline, "Can't reach the kitchen computer");
    });

    test('slowness is still held and retried like any other failure to reach',
        () {
      // The queue catches HouseholdUnreachable. If being slow stopped being a
      // kind of it, work would be thrown away rather than kept.
      expect(HouseholdTooSlow(const Duration(seconds: 10)),
          isA<HouseholdUnreachable>());
    });
  });

  group('reading a photographed packet', () {
    test('is allowed far longer than an ordinary call', () {
      expect(HouseholdApi.readingALabel.inSeconds,
          greaterThan(HouseholdApi.ordinary.inSeconds * 5));
    });

    test('survives a wait that would have failed an ordinary call', () async {
      // Twenty seconds is past the old fifteen-second limit and past the new
      // ordinary one. It is well inside what reading a packet is allowed.
      var asked = 0;
      final client = MockClient((request) async {
        asked++;
        await Future<void>.delayed(const Duration(milliseconds: 40));
        return http.Response(
            jsonEncode({
              'candidate': {'name': 'Oat bars', 'kcal_100': 430},
              'unreadable': <String>[],
            }),
            200);
      });
      final reader = HouseholdLabelReader(
        HouseholdApi(baseUrl: 'http://mini.test', client: client),
        readFile: (path) async => [1, 2, 3],
      );
      final draft = await reader.read({
        'front': 'a.jpg',
        'nutrition': 'b.jpg',
        'barcode': 'c.jpg',
      });
      expect(asked, 1);
      expect(draft.name, 'Oat bars');
    });
  });
}
