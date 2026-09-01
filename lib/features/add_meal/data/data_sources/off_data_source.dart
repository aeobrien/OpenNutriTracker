import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/ont_http_client.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_product_response_dto.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_word_response_dto.dart';
import 'package:opennutritracker/features/scanner/data/product_not_found_exception.dart';

class OFFDataSource {
  static const _timeoutDuration = Duration(seconds: 20); // TODO lower timeout

  /// How many times a refused search is asked, and how long is left between.
  ///
  /// Measured on 24 August 2026 rather than guessed. Thirty-nine searches
  /// spread across an hour, against this exact address: fourteen came back
  /// first time and twenty-five were refused. Of those twenty-five, thirteen
  /// came back on a second ask a second later and five more on a third — so
  /// three asks turn 36% into 82%, and the second ask alone does most of the
  /// work. A fourth was not measured and is not claimed.
  ///
  /// Three was not enough. On 1 September 2026 the search failed in front of
  /// Aidan mid-test with three asks already in place. Measured again that
  /// morning against the same address: fifteen searches, nine good and six
  /// refused, the refusals scattered through the run rather than bunched into
  /// an outage — so a refusal says nothing about whether the next ask will be
  /// refused too, which is exactly the shape asking again is for.
  ///
  /// At that refusal rate three asks still show an error on about one search in
  /// sixteen; five bring it to about one in a hundred.
  ///
  /// It costs four seconds at worst, and only on a search that was going to
  /// show an error anyway: their refusal is a page of HTML returned in about a
  /// fifth of a second, carrying no instruction to wait.
  static const _attempts = 5;
  static const _betweenAttempts = Duration(seconds: 1);

  final log = Logger('OFFDataSource');

  /// Only ever passed in by a test. The running app makes its own.
  final http.Client? _client;

  OFFDataSource({http.Client? client}) : _client = client;

  Future<OFFWordResponseDTO> fetchSearchWordResults(String searchString) async {
    try {
      final searchUrlString = OFFConst.getOffWordSearchUrl(searchString);
      final userAgentString = await AppConst.getUserAgentString();
      final httpClient = ONTHttpClient(userAgentString, _client ?? http.Client());

      var response =
          await httpClient.get(searchUrlString).timeout(_timeoutDuration);
      // Only their three "we are not answering" codes are worth asking again.
      // A 404 or a wrong answer is not something a second ask would mend, and a
      // request that timed out throws out of here rather than reaching this.
      for (var asked = 1;
          asked < _attempts &&
              OFFConst.offHttpDownCodes.contains(response.statusCode);
          asked++) {
        log.warning('OFF refused with ${response.statusCode}, asking again');
        await Future.delayed(_betweenAttempts);
        response =
            await httpClient.get(searchUrlString).timeout(_timeoutDuration);
      }
      log.fine('Fetching OFF results from: $searchUrlString');
      if (response.statusCode == OFFConst.offHttpSuccessCode) {
        final wordResponse =
            OFFWordResponseDTO.fromJson(jsonDecode(response.body));
        log.fine('Successful response from OFF');
        return wordResponse;
      } else {
        log.warning('Failed OFF call: ${response.statusCode}');
        return Future.error(response.statusCode);
      }
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF word search $exception');
      return Future.error(exception);
    }
  }

  Future<OFFProductResponseDTO> fetchBarcodeResults(String barcode) async {
    try {
      final searchUrl = OFFConst.getOffBarcodeSearchUri(barcode);
      final userAgentString = await AppConst.getUserAgentString();
      final httpClient = ONTHttpClient(userAgentString, http.Client());

      final response =
          await httpClient.get(searchUrl).timeout(_timeoutDuration);
      log.fine('Fetching OFF result from: $searchUrl');
      if (response.statusCode == OFFConst.offHttpSuccessCode) {
        final productResponse =
            OFFProductResponseDTO.fromJson(jsonDecode(response.body));
        log.fine('Successful response from OFF');
        return productResponse;
      } else if (response.statusCode == OFFConst.offProductNotFoundCode) {
        log.warning("404 OFF Product not found");
        return Future.error(ProductNotFoundException);
      } else {
        log.warning('Failed OFF call: ${response.statusCode}');
        return Future.error(response.statusCode);
      }
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF barcode search $exception');
      return Future.error(exception);
    }
  }
}
