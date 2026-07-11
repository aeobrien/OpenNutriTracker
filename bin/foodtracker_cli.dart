import 'dart:convert';
import 'dart:io';

import 'package:opennutritracker/features/recipes/data/data_source/claude_recipe_data_source.dart';
import 'package:opennutritracker/features/recipes/data/dto/llm_recipe_result.dart';

void main(List<String> args) async {
  try {
    final options = _parseOptions(args);
    final recipeText = options['--recipe-text'];
    final apiKey = options['--api-key'];

    if (recipeText == null || apiKey == null) {
      _printUsage();
      exitCode = 64;
      return;
    }

    final result = await ClaudeRecipeDataSource().parseRecipeFromText(
      apiKey,
      recipeText,
    );
    stdout.writeln(jsonEncode(_recipeToJson(result)));
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    _printUsage();
    exitCode = 64;
  } on Exception catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

Map<String, String> _parseOptions(List<String> args) {
  const supportedOptions = {'--recipe-text', '--api-key'};
  final options = <String, String>{};

  for (var index = 0; index < args.length; index += 2) {
    final option = args[index];
    if (!supportedOptions.contains(option)) {
      throw FormatException('Unknown option: $option');
    }
    if (index + 1 >= args.length) {
      throw FormatException('Missing value for $option');
    }
    options[option] = args[index + 1];
  }

  return options;
}

Map<String, Object?> _recipeToJson(LlmRecipeResult recipe) => {
      'recipeName': recipe.recipeName,
      'servings': recipe.servings,
      'ingredients': recipe.ingredients
          .map(
            (ingredient) => {
              'name': ingredient.name,
              'originalText': ingredient.originalText,
              'grams': ingredient.grams,
              'confidence': ingredient.confidence,
            },
          )
          .toList(),
      if (recipe.error != null) 'error': recipe.error,
    };

void _printUsage() {
  stderr.writeln(
    'Usage: dart run foodtracker_cli --recipe-text <text> --api-key <key>',
  );
}
