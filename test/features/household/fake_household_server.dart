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

  /// Every request that arrived, so a test can count deliveries.
  final List<String> requests = [];

  bool reachable = true;

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

  List<Map<String, dynamic>> plannedFor(int personId, String day) {
    return plan.where((p) => p['day'] == day).map((p) {
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
        } else if (path == '/household/food') {
          final id = (body['client_id'] ?? 'food-${foods.length + 1}') as String;
          foods.putIfAbsent(id, () => {...body, 'id': foods.length + 1});
          result = {'ok': true, 'food': foods[id]};
        } else if (path == '/household/foods') {
          result = {'ok': true, 'foods': foods.values.toList()};
        } else if (path.startsWith('/household/day/')) {
          final parts = path.split('/');
          final personId = int.parse(parts[3]);
          final day = parts[4];
          final mine = entries.values
              .where((e) => e['owner_id'] == personId && e['day'] == day)
              .toList();
          final myExercise = exercise.values
              .where((e) => e['owner_id'] == personId && e['day'] == day)
              .toList();
          final planned = plannedFor(personId, day);
          result = {
            'ok': true,
            'day': day,
            'person_id': personId,
            'settings': settingsFor(personId),
            'entries': mine,
            'exercise': myExercise,
            'planned': planned,
            'eaten_kcal':
                mine.fold<num>(0, (sum, e) => sum + ((e['kcal'] ?? 0) as num)),
            'exercise_kcal': myExercise.fold<num>(
                0, (sum, e) => sum + ((e['kcal'] ?? 0) as num)),
            'planned_kcal': planned.fold<num>(
                0, (sum, p) => sum + ((p['kcal'] ?? 0) as num)),
            'planned_unknown':
                planned.where((p) => p['kcal'] == null).length,
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
