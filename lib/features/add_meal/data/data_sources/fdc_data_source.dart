import 'dart:convert';

import 'package:logging/logging.dart';

import 'package:http/http.dart' as http;
import 'package:opennutritracker/core/utils/env.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_const.dart';
import 'package:opennutritracker/features/add_meal/data/dto/fdc/fdc_word_response_dto.dart';

/// The food database this tab searches will not accept the key it was asked
/// with, so no search on this tab can ever work until somebody puts a real one
/// in. Kept apart from every other failure because it is the only one where
/// pressing Retry is a waste of the person's time.
class FoodDatabaseNotSetUp implements Exception {
  const FoodDatabaseNotSetUp();

  @override
  String toString() =>
      'The USDA food database refused the key this app was built with.';
}

class FDCDataSource {
  static const _timeoutDuration = Duration(seconds: 10);

  /// What the USDA answers when it does not recognise the key.
  static const _keyRefusedCode = 403;

  final log = Logger('FDCDataSource');

  /// Only ever passed in by a test. The running app makes its own.
  final http.Client? _client;

  FDCDataSource({http.Client? client}) : _client = client;

  Future<FDCWordResponseDTO> fetchSearchWordResults(String searchString) async {
    try {
      final searchUrlString =
          FDCConst.getFDCWordSearchUrl(searchString, Env.fdcApiKey);

      final client = _client ?? http.Client();
      final response =
          await client.get(searchUrlString).timeout(_timeoutDuration);
      log.fine('Fetching FDC results from: $searchUrlString');

      // Checked before the body is read as results. It used to be parsed
      // straight through, so a refusal became whatever the parser made of an
      // error object — which is how "this was never set up" and "the line is
      // down" arrived on the screen wearing the same words.
      if (response.statusCode == _keyRefusedCode) {
        log.severe('FDC refused the key this app was built with');
        return Future.error(const FoodDatabaseNotSetUp());
      }

      final wordResponse =
          FDCWordResponseDTO.fromJson(jsonDecode(response.body));
      log.fine('Successful response from FDC');
      return wordResponse;
    } on FoodDatabaseNotSetUp {
      rethrow;
    } catch (exception, stacktrace) {
      log.severe('Exception while getting FDC word search $exception');
      return Future.error(exception);
    }
  }
}
