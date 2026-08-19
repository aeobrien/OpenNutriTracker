import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';

/// The Mac Mini could not be reached — no network, wrong address, the server is
/// down, or it took too long. Work stays in the queue and is tried again.
class HouseholdUnreachable implements Exception {
  final String message;
  HouseholdUnreachable(this.message);
  @override
  String toString() => 'HouseholdUnreachable: $message';
}

/// The Mini was reached and said no. Trying the identical request again will
/// get the identical answer, so the queue stops hammering it and keeps the item
/// with the reason attached rather than throwing the person's work away.
class HouseholdRefused implements Exception {
  final int status;
  final String message;
  HouseholdRefused(this.status, this.message);
  @override
  String toString() => 'HouseholdRefused($status): $message';
}

/// The phone's side of the /household/ endpoints on the Mac Mini.
class HouseholdApi {
  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final http.Client _client;
  final _log = Logger('HouseholdApi');

  HouseholdApi({required this.baseUrl, http.Client? client})
      : _client = client ?? http.Client();

  String get _base {
    var b = baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }

  static const _headers = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  Future<Map<String, dynamic>> _decode(http.Response response) async {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw HouseholdUnreachable(
          'the server answered with something that was not JSON');
    }
    if (response.statusCode >= 500) {
      throw HouseholdUnreachable('the server is having trouble '
          '(${response.statusCode})');
    }
    if (response.statusCode >= 400) {
      throw HouseholdRefused(
          response.statusCode, (body['error'] ?? 'refused').toString());
    }
    return body;
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final r = await _client
          .get(Uri.parse('$_base$path'), headers: _headers)
          .timeout(_timeout);
      return _decode(r);
    } on TimeoutException {
      throw HouseholdUnreachable('the server did not answer in time');
    } on http.ClientException catch (e) {
      throw HouseholdUnreachable(e.message);
    }
  }

  /// The one way anything is sent to the server. The outbox calls this and
  /// nothing else does, so there is a single place where "sent" is decided.
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    try {
      final r = await _client
          .post(Uri.parse('$_base$path'), headers: _headers, body: jsonEncode(body))
          .timeout(_timeout);
      return _decode(r);
    } on TimeoutException {
      throw HouseholdUnreachable('the server did not answer in time');
    } on http.ClientException catch (e) {
      throw HouseholdUnreachable(e.message);
    }
  }

  Future<List<HouseholdPerson>> people() async {
    final body = await get('/household/people');
    return (body['people'] as List)
        .map((p) => HouseholdPerson.fromJson(p as Map<String, dynamic>))
        .toList();
  }

  Future<void> registerDevice(String deviceId, int personId) async {
    await post('/household/device',
        {'device_id': deviceId, 'person_id': personId});
    _log.info('[HOUSE] device $deviceId registered to person $personId');
  }

  /// Whose phone the *server* thinks this is. Asked rather than asserted: the
  /// server holds the answer, the phone does not send one and hope.
  Future<int> deviceOwner(String deviceId) async {
    final body = await get('/household/device/$deviceId');
    return body['person_id'] as int;
  }

  Future<PersonSettings> settings(int personId) async {
    final body = await get('/household/settings/$personId');
    return PersonSettings.fromJson(body['settings'] as Map<String, dynamic>);
  }

  Future<PersonSettings> updateSettings(int personId, Map<String, dynamic> changes) async {
    final body = await post('/household/settings/$personId', changes);
    return PersonSettings.fromJson(body['settings'] as Map<String, dynamic>);
  }

  /// Everything this person has weighed in at. Asked for regardless of the
  /// weight-tracking switch — the switch decides what is shown, never what is
  /// kept.
  Future<List<Map<String, dynamic>>> weights(int personId) async {
    final body = await get('/household/weights/$personId');
    return (body['weights'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> day(int personId, String day) async {
    return get('/household/day/$personId/$day');
  }
}
