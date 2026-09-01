import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/app_const.dart';
import 'package:opennutritracker/core/utils/off_const.dart';
import 'package:opennutritracker/core/utils/ont_http_client.dart';
import 'package:opennutritracker/features/add_meal/data/dto/off/off_fallback_search.dart';
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

  /// A search, and which of the two services answered it.
  ///
  /// [secondChoice] is true when the old service refused every ask and the
  /// newer one answered instead. The screen needs to know, because those
  /// results are worse and Aidan should be able to tell that from the app
  /// getting worse — see [OFFFallbackSearch] and the banner on the results.
  Future<({OFFWordResponseDTO response, bool secondChoice})>
      fetchSearchWordResults(String searchString) async {
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
        return (response: wordResponse, secondChoice: false);
      }
      // Five refusals is where the retry gives up and, until 1 September 2026,
      // where an error screen went up. Measured that day: the old address
      // answered 7 of 20 asks at human pace and the newer one 20 of 20, so
      // there is a service willing to answer standing right next to the one
      // that will not. It is asked only here, and only for the codes that mean
      // "not answering" — the same narrowness as the retry above.
      if (OFFConst.offHttpDownCodes.contains(response.statusCode)) {
        log.warning('OFF refused ${_attempts} times, trying the other service');
        return (
          response: await _fetchFromTheOtherService(httpClient, searchString),
          secondChoice: true,
        );
      }
      log.warning('Failed OFF call: ${response.statusCode}');
      return Future.error(response.statusCode);
    } catch (exception, stacktrace) {
      log.severe('Exception while getting OFF word search $exception');
      return Future.error(exception);
    }
  }

  /// Asked once, not five times. Its refusal rate is not the other one's, and
  /// a person who has already waited out five asks has waited long enough.
  Future<OFFWordResponseDTO> _fetchFromTheOtherService(
      ONTHttpClient httpClient, String searchString) async {
    final url = OFFConst.getOffFallbackSearchUrl(searchString);
    final response = await httpClient.get(url).timeout(_timeoutDuration);
    if (response.statusCode != OFFConst.offHttpSuccessCode) {
      log.warning('The other service refused too: ${response.statusCode}');
      throw response.statusCode;
    }
    return OFFFallbackSearch.read(jsonDecode(response.body));
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
