/// A stand-in for the household half of the Mac Mini.
///
/// It keeps its own records the way the real server does — in particular it
/// answers "whose phone is this?" from what it was told earlier, rather than
/// echoing back whatever the caller sent. That distinction is the whole point
/// of several tests, so a fake that simply returned the last value it saw would
/// quietly make them meaningless.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class FakeHouseholdServer {
  /// The household, as the server knows it.
  final List<Map<String, dynamic>> people = [
    {'id': 1, 'name': 'Aidan'},
    {'id': 2, 'name': 'Emily'},
  ];

  /// Which phone belongs to whom, by the server's own reckoning.
  final Map<String, int> deviceOwners = {};

  /// Each person's settings. Deliberately stored per person with no shared
  /// default, mirroring the server, so a test that expects one person's change
  /// to move the other's would have to make it happen on purpose.
  final Map<int, Map<String, dynamic>> settings = {};

  /// Weights, kept so a test can show the toggle hides them without deleting.
  final List<Map<String, dynamic>> weights = [];

  /// Ledger rows the server has accepted, keyed by the id the phone minted.
  final Map<String, Map<String, dynamic>> entries = {};
  final Map<String, Map<String, dynamic>> exercise = {};
  final Map<String, Map<String, dynamic>> foods = {};

  /// What the household has planned, by day. Kept the way the server keeps it:
  /// one row per meal for the *household*, with each person's portion held
  /// separately — so a fake that stored one figure per meal could not reproduce
  /// the two people seeing different amounts, which is the thing under test.
  final List<Map<String, dynamic>> plan = [];

  /// plan id → person id → how many portions of it are theirs.
  final Map<int, Map<int, num>> portions = {};

  /// plan id → person id → 'ate' | 'skipped'. Kept per person exactly as the
  /// server keeps it, so a fake could not accidentally make one person's answer
  /// settle the meal for both — which is the mistake the tests are watching for.
  final Map<int, Map<int, String>> decisions = {};

  /// What a correction is allowed to touch, matching the real server.
  static const amendable = [
    'day', 'owner_id', 'label', 'qty', 'unit',
    'kcal', 'protein', 'fat', 'carbs', 'slot',
  ];

  /// Every request that arrived, so a test can count deliveries.
  final List<String> requests = [];

  bool reachable = true;

  /// Whether this server is new enough to understand being asked for a *search*
  /// rather than the whole food list. False reproduces an older kitchen
  /// computer, which answers every search with everything it has — the state
  /// the real machine was in on 19 August, and the reason the phone checks the
  /// match a second time.
  bool understandsFoodSearch = true;

  /// Who the food list was ordered for, recorded so a test can show the phone
  /// asked on this person's behalf rather than in general.
  int? askedFoodsFor;

  /// What a hunt around the web comes back with. Empty is the default, because
  /// finding nothing is the ordinary case and a test that wants candidates
  /// should have to say so.
  List<Map<String, dynamic>> webCandidates = [];

  /// Whether this server can look things up on the web at all. False is an
  /// older kitchen computer, which does not know the route — the phone has to
  /// treat that exactly like finding nothing.
  bool canHuntTheWeb = true;

  /// What the hunt was asked to look for, so a test can show the phone passed
  /// on what was typed rather than something of its own.
  String? huntedFor;

  /// Whether the photographs can be read at all. False is an ordinary day, not
  /// a broken server: the panel was creased, the light was poor.
  bool labelReadable = true;

  /// What a reading gives back, and which fields it could not make out.
  Map<String, dynamic> labelRead = const {'name': 'A packet', 'kcal_100': 400};
  List<String> labelUnreadable = const [];

  /// Put a food in the household's own list, the way the kitchen computer
  /// holds it.
  Map<String, dynamic> addFood({
    required String name,
    String? brand,
    String? barcode,
    num? kcal100,
    num? protein100,
    num? fat100,
    num? carbs100,
    num? servingG,
  }) {
    final id = foods.length + 1;
    final row = <String, dynamic>{
      'id': id,
      'name': name,
      'brand': brand,
      'barcode': barcode,
      'kcal_100': kcal100,
      'protein_100': protein100,
      'fat_100': fat100,
      'carbs_100': carbs100,
      'serving_g': servingG,
      'trust': 'typed',
      'source': 'typed',
    };
    foods['seeded-$id'] = row;
    return row;
  }

  int get aidan => 1;
  int get emily => 2;

  /// Put a meal on a day. [mealKcal] is one standard portion of it; null means
  /// the meal's own numbers are not known yet.
  int planMeal({
    required String day,
    required String title,
    num? mealKcal,
    Map<int, num> forPeople = const {},
  }) {
    final planId = plan.length + 1;
    plan.add({'plan_id': planId, 'day': day, 'title': title, 'meal_kcal': mealKcal});
    portions[planId] = {...forPeople};
    return planId;
  }

  void setPortion(int planId, int personId, num howMany) {
    (portions[planId] ??= {})[personId] = howMany;
  }

  String? decisionFor(int planId, int personId) => decisions[planId]?[personId];

  List<Map<String, dynamic>> plannedFor(int personId, String day) {
    return plan
        .where((p) => p['day'] == day)
        .where((p) => decisionFor(p['plan_id'] as int, personId) == null)
        .map((p) {
      final planId = p['plan_id'] as int;
      final mine = portions[planId]?[personId];
      final perPortion = p['meal_kcal'] as num?;
      return {
        'plan_id': planId,
        'title': p['title'],
        'portions': mine,
        'kcal': (mine == null || perPortion == null) ? null : perPortion * mine,
        'meal_kcal_known': perPortion != null,
      };
    }).toList();
  }

  /// The Monday of the week a date falls in — the same rule the real server
  /// uses, written here so a test can leave `start` off and still know which
  /// seven days it will get.
  static String mondayOf(String day) {
    final d = DateTime.parse(day);
    return d
        .subtract(Duration(days: d.weekday - 1))
        .toIso8601String()
        .substring(0, 10);
  }

  /// What the fake calls today. The real server decides this, not the phone,
  /// so a test that wants a past day says so here rather than waiting.
  String today = '2026-08-19';

  /// One day as the server assembles it, used by both the day route and the
  /// week route — the same reason the real server has one `day_for`: a day and
  /// a week that disagree about the same Tuesday is a bug nobody can report.
  Map<String, dynamic> dayLine(int personId, String day) {
    final mine = entries.values
        .where((e) => e['owner_id'] == personId && e['day'] == day)
        .toList();
    final myExercise = exercise.values
        .where((e) => e['owner_id'] == personId && e['day'] == day)
        .toList();
    // A day already gone is read off the ledger alone.
    final planned =
        day.compareTo(today) < 0 ? <Map<String, dynamic>>[] : plannedFor(personId, day);
    final awaiting = [
      for (final p in planned)
        if (p['kcal'] == null)
          {
            'plan_id': p['plan_id'],
            'title': p['title'],
            'why': (p['meal_kcal_known'] as bool)
                ? 'nobody has said how much of this is yours'
                : "this meal's calories have not been worked out yet",
          }
    ];
    return {
      'day': day,
      'past': day.compareTo(today) < 0,
      'entries': mine,
      'exercise': myExercise,
      'planned': planned,
      'eaten_kcal':
          mine.fold<num>(0, (sum, e) => sum + ((e['kcal'] ?? 0) as num)),
      'exercise_kcal': myExercise.fold<num>(
          0, (sum, e) => sum + ((e['kcal'] ?? 0) as num)),
      'planned_kcal':
          planned.fold<num>(0, (sum, p) => sum + ((p['kcal'] ?? 0) as num)),
      'awaiting': awaiting,
      'awaiting_count': awaiting.length,
    };
  }

  Map<String, dynamic> settingsFor(int personId) => settings.putIfAbsent(
      personId,
      () => {
            'person_id': personId,
            'daily_target_kcal': null,
            'weight_tracking_on': 0,
            'figures_off': 0,
          });

  http.Client get client => MockClient((request) async {
        if (!reachable) {
          throw http.ClientException('Connection refused', request.url);
        }
        final path = request.url.path;
        requests.add('${request.method} $path');
        final body = request.body.isEmpty
            ? <String, dynamic>{}
            : jsonDecode(request.body) as Map<String, dynamic>;

        Map<String, dynamic>? result;

        if (path == '/household/people') {
          result = {'ok': true, 'people': people};
        } else if (path == '/household/device' && request.method == 'POST') {
          deviceOwners[body['device_id'] as String] = body['person_id'] as int;
          result = {'ok': true, 'changed': true};
        } else if (path.startsWith('/household/device/')) {
          final id = path.substring('/household/device/'.length);
          final owner = deviceOwners[id];
          if (owner == null) {
            return http.Response(
                jsonEncode({'ok': false, 'error': 'unknown device'}), 404,
                headers: {'content-type': 'application/json'});
          }
          result = {'ok': true, 'device_id': id, 'person_id': owner};
        } else if (path.startsWith('/household/settings/')) {
          final personId =
              int.parse(path.substring('/household/settings/'.length));
          final current = settingsFor(personId);
          if (request.method == 'POST') {
            if (body.containsKey('daily_target_kcal')) {
              current['daily_target_kcal'] = body['daily_target_kcal'];
            }
            if (body.containsKey('weight_tracking_on')) {
              current['weight_tracking_on'] =
                  (body['weight_tracking_on'] as bool) ? 1 : 0;
            }
            if (body.containsKey('figures_off')) {
              current['figures_off'] = (body['figures_off'] as bool) ? 1 : 0;
            }
          }
          result = {'ok': true, 'settings': current};
        } else if (path == '/household/entry') {
          final id = body['client_id'] as String;
          entries.putIfAbsent(id, () => {...body, 'id': entries.length + 1});
          result = {'ok': true, 'entry': entries[id]};
        } else if (path == '/household/plan/decide') {
          final planId = body['plan_id'] as int;
          final person = body['owner_id'] as int;
          final known = plan.any((p) => p['plan_id'] == planId);
          if (!known) {
            return http.Response(
                jsonEncode({'ok': false, 'error': 'no such plan'}), 404,
                headers: {'content-type': 'application/json'});
          }
          final state = body['state'] as String;
          final settled = (decisions[planId] ??= {});
          // First answer stands, as on the real server. A resend replays it.
          final decided = settled.putIfAbsent(person, () => state);
          Map<String, dynamic>? madeEntry;
          if (decided == 'ate') {
            final entryId = '${body['client_id']}-entry';
            final row = plan.firstWhere((p) => p['plan_id'] == planId);
            final mine = portions[planId]?[person];
            final perPortion = row['meal_kcal'] as num?;
            madeEntry = entries.putIfAbsent(
                entryId,
                () => {
                      'id': entries.length + 1,
                      'client_id': entryId,
                      'day': row['day'],
                      'owner_id': person,
                      'author_id': body['author_id'],
                      'label': row['title'],
                      'qty': mine,
                      'unit': mine == null ? null : 'portion',
                      'kcal': (mine == null || perPortion == null)
                          ? null
                          : perPortion * mine,
                    });
          }
          result = {
            'ok': true,
            'decision': {
              'plan_id': planId,
              'person_id': person,
              'state': decided,
              'id': 1,
            },
            'entry': madeEntry,
          };
        } else if (path == '/household/exercise') {
          final id = body['client_id'] as String;
          exercise.putIfAbsent(id, () => {...body, 'id': exercise.length + 1});
          result = {'ok': true, 'exercise': exercise[id]};
        } else if (path == '/household/weight') {
          final id = body['client_id'] as String;
          if (!weights.any((w) => w['client_id'] == id)) {
            weights.add({...body, 'id': weights.length + 1});
          }
          result = {'ok': true, 'weight': weights.last};
        } else if (path.startsWith('/household/weights/')) {
          final personId =
              int.parse(path.substring('/household/weights/'.length));
          result = {
            'ok': true,
            'weights': weights
                .where((w) => w['owner_id'] == personId)
                .map((w) => {'day': w['day'], 'kg': w['kg']})
                .toList(),
          };
        } else if (path == '/household/label/read') {
          if (!labelReadable) {
            return http.Response(
                jsonEncode({
                  'ok': false,
                  'readable': false,
                  'error': 'nothing readable came back from the photographs',
                  'hint': 'type the numbers in instead',
                }),
                422,
                headers: {'content-type': 'application/json'});
          }
          result = {
            'ok': true,
            'candidate': labelRead,
            'trust': 'photo',
            'unreadable': labelUnreadable,
          };
        } else if (path == '/household/food') {
          final id = (body['client_id'] ?? 'food-${foods.length + 1}') as String;
          foods.putIfAbsent(id, () => {...body, 'id': foods.length + 1});
          result = {'ok': true, 'food': foods[id]};
        } else if (path.startsWith('/household/entry/by-client/')) {
          // The server keeps its rows under the id the phone minted, so the
          // phone naming a row is a lookup rather than a translation.
          final rest = path.substring('/household/entry/by-client/'.length);
          final cid = rest.substring(0, rest.lastIndexOf('/'));
          final action = rest.substring(rest.lastIndexOf('/') + 1);
          final row = entries[cid];
          if (row == null) {
            return http.Response(
                jsonEncode({'ok': false, 'error': 'no entry called $cid'}), 404,
                headers: {'content-type': 'application/json'});
          }
          if (action == 'retire') {
            // Soft, like the real server: the row and its numbers stay and stop
            // counting. What the real server also does — putting a planned meal
            // back to waiting — is its own behaviour and is held to account in
            // its own tests, not reproduced here.
            row['deleted_at'] = 'then';
          } else {
            for (final field in amendable) {
              if (body.containsKey(field)) row[field] = body[field];
            }
            row['amended_by'] = body['author_id'];
          }
          result = {'ok': true, 'entry': row};
        } else if (path == '/household/food/find') {
          huntedFor = body['name'] as String?;
          if (!canHuntTheWeb) {
            return http.Response(
                jsonEncode({
                  'ok': false,
                  'error': 'could not look that up just now',
                  'candidates': [],
                }),
                503,
                headers: {'content-type': 'application/json'});
          }
          result = {'ok': true, 'candidates': webCandidates};
        } else if (path == '/household/foods') {
          final q = request.url.queryParameters['q'];
          final barcode = request.url.queryParameters['barcode'];
          askedFoodsFor =
              int.tryParse(request.url.queryParameters['for'] ?? '');
          var found = foods.values.toList();
          if (understandsFoodSearch) {
            if (barcode != null) {
              found = found.where((f) => f['barcode'] == barcode).toList();
            }
            if (q != null && q.trim().isNotEmpty) {
              final needle = q.trim().toLowerCase();
              found = found.where((f) {
                final name = ((f['name'] ?? '') as String).toLowerCase();
                final brand = ((f['brand'] ?? '') as String).toLowerCase();
                return name.contains(needle) || brand.contains(needle);
              }).toList();
            }
          }
          result = {'ok': true, 'foods': found};
        } else if (path.startsWith('/household/day/')) {
          final parts = path.split('/');
          final personId = int.parse(parts[3]);
          final line = dayLine(personId, parts[4]);
          result = {
            'ok': true,
            'person_id': personId,
            'settings': settingsFor(personId),
            ...line,
            'planned_unknown': line['awaiting_count'],
          };
        } else if (path.startsWith('/household/week/')) {
          final personId = int.parse(path.split('/')[3]);
          final asked = request.url.queryParameters['start'];
          final start = asked ?? mondayOf(today);
          final days = [
            for (var i = 0; i < 7; i++)
              dayLine(
                  personId,
                  DateTime.parse(start)
                      .add(Duration(days: i))
                      .toIso8601String()
                      .substring(0, 10))
          ];
          result = {
            'ok': true,
            'person_id': personId,
            'start': start,
            'today': today,
            'settings': settingsFor(personId),
            'days': days,
            'counted_kcal': days.fold<num>(
                0,
                (sum, d) =>
                    sum + (d['eaten_kcal'] as num) + (d['planned_kcal'] as num)),
            'awaiting_count':
                days.fold<int>(0, (sum, d) => sum + (d['awaiting_count'] as int)),
            'target_kcal': settingsFor(personId)['daily_target_kcal'] == null
                ? null
                : (settingsFor(personId)['daily_target_kcal'] as int) * 7,
          };
        }

        if (result == null) {
          return http.Response(
              jsonEncode({'ok': false, 'error': 'no such route: $path'}), 404,
              headers: {'content-type': 'application/json'});
        }
        return http.Response(jsonEncode(result), 200,
            headers: {'content-type': 'application/json'});
      });
}
