import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/recipes/data/dto/mealie/mealie_recipe_dto.dart';

/// Base type for all Mealie integration failures.
class MealieException implements Exception {
  final String message;
  MealieException(this.message);

  @override
  String toString() => 'MealieException: $message';
}

/// Thrown on 401/403 — usually a missing, wrong, or expired API token.
class MealieAuthException extends MealieException {
  MealieAuthException() : super('Unauthorized — check the Mealie server URL and API token');
}

/// Thrown on 404 for a specific recipe slug.
class MealieNotFoundException extends MealieException {
  final String slug;
  MealieNotFoundException(this.slug) : super('Recipe not found on Mealie: $slug');
}

/// Talks to a self-hosted Mealie server's REST API.
///
/// Auth is a long-lived API token (Mealie: User → Profile → API Tokens), sent
/// as a Bearer token. [baseUrl] is the server root, e.g.
/// `http://100.71.40.51:9000` (the mini over Tailscale). An [http.Client] can be
/// injected for testing.
class MealieDataSource {
  final _log = Logger('MealieDataSource');
  static const _timeout = Duration(seconds: 15);

  final String baseUrl;
  final String token;
  final http.Client _client;

  MealieDataSource({
    required this.baseUrl,
    required this.token,
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
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      };

  /// Fetches one page of recipe summaries. [search] filters by name/text.
  Future<MealieRecipePage> fetchRecipes({
    int page = 1,
    int perPage = 50,
    String? search,
  }) async {
    final qp = <String, String>{
      'page': '$page',
      'perPage': '$perPage',
      if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
    };
    final uri = Uri.parse('$_base/api/recipes').replace(queryParameters: qp);
    final body = await _get(uri);
    return MealieRecipePage.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  /// Fetches a full recipe (with ingredients + nutrition) by its slug.
  Future<MealieRecipeDto> fetchRecipe(String slug) async {
    final uri = Uri.parse('$_base/api/recipes/$slug');
    final body = await _get(uri, notFoundSlug: slug);
    return MealieRecipeDto.fromJson(jsonDecode(body) as Map<String, dynamic>);
  }

  Future<String> _get(Uri uri, {String? notFoundSlug}) async {
    _log.fine('GET $uri');
    final http.Response response;
    try {
      response = await _client.get(uri, headers: _headers).timeout(_timeout);
    } catch (e) {
      _log.warning('Mealie request failed: $e');
      throw MealieException('Could not reach Mealie at $_base: $e');
    }

    if (response.statusCode == 200) return response.body;
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw MealieAuthException();
    }
    if (response.statusCode == 404 && notFoundSlug != null) {
      throw MealieNotFoundException(notFoundSlug);
    }
    _log.warning('Mealie returned ${response.statusCode} for $uri');
    throw MealieException('Mealie returned HTTP ${response.statusCode}');
  }
}
