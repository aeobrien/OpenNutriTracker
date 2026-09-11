import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';
import 'package:opennutritracker/features/label_scan/data/label_scan_offline_exception.dart';
import 'package:opennutritracker/features/label_scan/data/llm_nutrition_prompt.dart';

class OpenAiDataSource {
  final _log = Logger('OpenAiDataSource');

  static const _model = 'gpt-4o-mini';
  static const _maxTokens = 1024;
  static const _maxRetries = 2;
  static const _apiUrl = 'https://api.openai.com/v1/chat/completions';
  static const _timeout = Duration(seconds: 30);

  Future<LlmNutritionResult> extractNutrition(
    String apiKey,
    Uint8List imageBytes,
    String mimeType,
  ) async {
    _log.fine('Starting extraction: ${imageBytes.length} bytes, $mimeType');

    final base64Image = base64Encode(imageBytes);
    _log.fine('Base64 encoded: ${base64Image.length} chars');

    final dataUrl = 'data:$mimeType;base64,$base64Image';

    Exception? lastError;

    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        if (attempt > 0) {
          _log.fine('Retry attempt $attempt');
          await Future.delayed(Duration(seconds: attempt * 2));
        }

        final body = jsonEncode({
          'model': _model,
          'max_tokens': _maxTokens,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'text', 'text': llmNutritionPrompt},
                {
                  'type': 'image_url',
                  'image_url': {'url': dataUrl},
                },
              ],
            },
          ],
        });

        _log.fine('Sending request (${body.length} chars)');

        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {
                'Authorization': 'Bearer $apiKey',
                'Content-Type': 'application/json',
              },
              body: body,
            )
            .timeout(_timeout);

        _log.fine('Response status: ${response.statusCode}');

        if (response.statusCode != 200) {
          throw Exception(
              'OpenAI API error ${response.statusCode}: ${response.body}');
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = json['choices'] as List<dynamic>;
        if (choices.isEmpty) {
          throw Exception('OpenAI returned empty choices');
        }

        final message = choices[0]['message'] as Map<String, dynamic>;
        final responseText = message['content'] as String;
        _log.fine('OpenAI response: $responseText');

        return LlmNutritionResult.parse(responseText);
      } on SocketException catch (e) {
        _log.warning('Network unavailable during extraction', e);
        throw const LabelScanOfflineException();
      } on TimeoutException catch (e) {
        _log.warning('Extraction timed out (attempt $attempt)', e);
        lastError = e;
      } on http.ClientException catch (e) {
        // ClientException wraps low-level connection failures (DNS, refused).
        _log.warning('HTTP client error during extraction', e);
        throw const LabelScanOfflineException();
      } on Exception catch (e) {
        _log.warning('OpenAI API call failed (attempt $attempt)', e);
        lastError = e;
      }
    }

    throw lastError ?? Exception('Failed to extract nutrition data');
  }
}
