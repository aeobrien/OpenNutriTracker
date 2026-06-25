import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/intake/data/dto/mantel_intake_dto.dart';

/// Base type for all Mantel meal-sync failures.
class MantelException implements Exception {
  final String message;
  MantelException(this.message);

  @override
  String toString() => 'MantelException: $message';
}

/// Thrown on 401/403 — usually a missing or wrong per-actor intake token.
class MantelAuthException extends MantelException {
  MantelAuthException()
      : super('Unauthorized — check the Mantel intake token for this actor');
}

/// Talks to Mantel's intake sync endpoints over the tailnet.
///
/// `GET /intake/pending?actor=&limit=&after_id=` returns the actor's resolved,
/// not-yet-synced meals oldest-first; `POST /intake/ack {actor, ids}` confirms a
/// local insert so Mantel marks them consumed. Auth is an optional per-actor
/// `X-Intake-Token` (blank on the tailnet). [baseUrl] is the server root, e.g.
/// `http://100.71.40.51:8770`. An [http.Client] can be injected for testing.
class MantelDataSource {
  final _log = Logger('MantelDataSource');
  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final String actor;
  final String? token;
  final http.Client _client;

  MantelDataSource({
    required this.baseUrl,
    required this.actor,
    this.token,
    http.Client? client,
  }) : _client = client ?? http.Client();

  String get _base {
    var b = baseUrl.trim();
    while (b.endsWith('/')) {
      b = b.substring(0, b.length - 1);
    }
    return b;
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (token != null && token!.isNotEmpty) 'X-Intake-Token': token!,
      };

  /// Fetches one page of pending intakes, oldest first. [afterId] is exclusive —
  /// pass the last id seen to page forward.
  Future<List<MantelIntakeDto>> getPending({
    int limit = 50,
    String? afterId,
  }) async {
    final qp = <String, String>{
      'actor': actor,
      'limit': '$limit',
      if (afterId != null && afterId.isNotEmpty) 'after_id': afterId,
    };
    final uri = Uri.parse('$_base/intake/pending').replace(queryParameters: qp);
    _log.fine('GET $uri');

    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(_timeout);
    } catch (e) {
      _log.warning('Mantel pending request failed: $e');
      throw MantelException('Could not reach Mantel at $_base: $e');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw MantelAuthException();
    }
    if (response.statusCode != 200) {
      _log.warning('Mantel returned ${response.statusCode} for $uri');
      throw MantelException('Mantel returned HTTP ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['ok'] != true) {
      throw MantelException('Mantel reported: ${body['error'] ?? 'unknown error'}');
    }
    final items = (body['pending'] as List? ?? const []);
    return items
        .whereType<Map<String, dynamic>>()
        .map(MantelIntakeDto.fromJson)
        .where((d) => d.id.isNotEmpty)
        .toList();
  }

  /// Confirms a batch of locally-inserted intake ids so Mantel marks them
  /// consumed. Idempotent server-side. Returns the number Mantel acked.
  Future<int> ack(List<String> ids) async {
    if (ids.isEmpty) return 0;
    final uri = Uri.parse('$_base/intake/ack');
    _log.fine('POST $uri (${ids.length} ids)');

    final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {..._headers, 'Content-Type': 'application/json'},
            body: jsonEncode({'actor': actor, 'ids': ids}),
          )
          .timeout(_timeout);
    } catch (e) {
      _log.warning('Mantel ack request failed: $e');
      throw MantelException('Could not ack to Mantel at $_base: $e');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw MantelAuthException();
    }
    if (response.statusCode != 200) {
      throw MantelException('Mantel ack returned HTTP ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['acked'] as num?)?.toInt() ?? 0;
  }
}
