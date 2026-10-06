import 'dart:typed_data';

import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/label_scan/data/data_source/openai_data_source.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';

class ExtractionResult {
  final LlmNutritionResult nutrition;
  final ValidationResult validation;

  const ExtractionResult({
    required this.nutrition,
    required this.validation,
  });
}

class ExtractNutritionUsecase {
  final OpenAiDataSource _openAiDataSource;
  final SecureAppStorageProvider _secureStorage;
  final _log = Logger('ExtractNutritionUsecase');

  ExtractNutritionUsecase(this._openAiDataSource, this._secureStorage);

  Future<ExtractionResult> execute(
      Uint8List imageBytes, String mimeType) async {
    final apiKey = await _secureStorage.getOpenAiApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('OpenAI API key not configured');
    }

    _log.fine('Extracting nutrition from image (${imageBytes.length} bytes)');

    var result =
        await _openAiDataSource.extractNutrition(apiKey, imageBytes, mimeType);

    if (result.hasError) {
      _log.warning('OpenAI returned error: ${result.error}');
      return ExtractionResult(
        nutrition: result,
        validation: const ValidationResult(
          calculatedKcal: 0,
          deviationPct: 0,
          status: ValidationStatus.ok,
        ),
      );
    }

    // Infer serving size from per-serving / per-100g calorie ratio if missing
    result = _inferServingSize(result);

    final validation = NutritionValidator.validateConsistency(
      reportedKcal: result.caloriesPer100g,
      proteinGrams: result.proteinPer100g,
      carbsGrams: result.carbsPer100g,
      fatGrams: result.fatPer100g,
      fibreGrams: result.fiberPer100g,
    );

    _log.fine('Extraction complete: ${result.name}, validation: $validation');

    return ExtractionResult(nutrition: result, validation: validation);
  }

  /// When caloriesPerServing and caloriesPer100g are both available, always
  /// compute servingSizeG from the ratio — LLMs can't do arithmetic reliably.
  LlmNutritionResult _inferServingSize(LlmNutritionResult result) {
    final perServing = result.caloriesPerServing;
    final per100g = result.caloriesPer100g;
    if (perServing == null || perServing <= 0 || per100g <= 0) return result;

    final computed = (perServing / per100g) * 100;
    final rounded = (computed * 10).roundToDouble() / 10; // 1 decimal place

    if (result.servingSizeG != null && result.servingSizeG != rounded) {
      _log.fine(
          'Overriding LLM servingSizeG ${result.servingSizeG} → $rounded '
          '(from $perServing kcal/serving, $per100g kcal/100g)');
    } else if (result.servingSizeG == null) {
      _log.fine(
          'Inferred servingSizeG: $rounded '
          '(from $perServing kcal/serving, $per100g kcal/100g)');
    }

    return result.copyWith(servingSizeG: rounded);
  }
}
