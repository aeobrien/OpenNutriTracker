import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/recipes/data/dto/llm_recipe_result.dart';
import 'package:opennutritracker/features/recipes/data/llm_recipe_prompt.dart';

class ClaudeRecipeDataSource {
  final _log = Logger('ClaudeRecipeDataSource');

  static const _model = 'claude-sonnet-4-20250514';
  static const _maxTokens = 2048;
  static const _maxRetries = 2;
  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _timeout = Duration(seconds: 30);
  static const _anthropicVersion = '2023-06-01';

  Future<LlmRecipeResult> parseRecipeFromText(
    String apiKey,
    String ingredientText,
  ) async {
    _log.fine('Parsing recipe from text (${ingredientText.length} chars)');

    final userMessage = '$llmRecipeTextPrompt\n\nINGREDIENT TEXT:\n$ingredientText';
    return _callClaude(apiKey, userMessage);
  }

  Future<LlmRecipeResult> parseRecipeFromHtml(
    String apiKey,
    String html,
    String url,
  ) async {
    _log.fine('Parsing recipe from URL: $url (${html.length} chars)');

    final userMessage = '''
You are a recipe parsing assistant. Extract the recipe ingredients from the HTML content of a recipe page.

RULES:
1. Find the ingredients section and parse each ingredient.
2. Convert volume measurements to grams using common conversions.
3. Extract the recipe name from the page title or heading.
4. Extract servings if stated on the page, otherwise default to 4.
5. Assign a confidence for each ingredient: "high" if gram conversion is certain, "medium" if approximate, "low" if guessing.

Respond ONLY with valid JSON (no markdown fences, no explanation):
{
  "recipeName": "string",
  "servings": number,
  "ingredients": [
    {
      "name": "ingredient name (for database search)",
      "originalText": "the original ingredient text",
      "grams": number,
      "confidence": "high" | "medium" | "low"
    }
  ]
}

URL: $url

HTML CONTENT:
$html
''';

    return _callClaude(apiKey, userMessage);
  }

  Future<LlmRecipeResult> _callClaude(String apiKey, String userMessage) async {
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
              'content': userMessage,
            },
          ],
        });

        _log.fine('Sending request (${body.length} chars)');

        final response = await http
            .post(
              Uri.parse(_apiUrl),
              headers: {
                'x-api-key': apiKey,
                'anthropic-version': _anthropicVersion,
                'Content-Type': 'application/json',
              },
              body: body,
            )
            .timeout(_timeout);

        _log.fine('Response status: ${response.statusCode}');

        if (response.statusCode != 200) {
          throw Exception(
              'Claude API error ${response.statusCode}: ${response.body}');
        }

        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final content = json['content'] as List<dynamic>;
        if (content.isEmpty) {
          throw Exception('Claude returned empty content');
        }

        final textBlock = content.firstWhere(
          (block) => block['type'] == 'text',
          orElse: () => throw Exception('No text block in response'),
        );
        final responseText = textBlock['text'] as String;
        _log.fine('Claude response: $responseText');

        return LlmRecipeResult.parse(responseText);
      } on Exception catch (e) {
        _log.warning('Claude API call failed (attempt $attempt)', e);
        lastError = e;
      }
    }

    throw lastError ?? Exception('Failed to parse recipe');
  }
}
