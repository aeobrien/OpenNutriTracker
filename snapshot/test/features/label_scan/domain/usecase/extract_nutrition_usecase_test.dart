import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/label_scan/data/data_source/openai_data_source.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';
import 'package:opennutritracker/features/label_scan/domain/usecase/extract_nutrition_usecase.dart';

// Simple manual mocks
class MockOpenAiDataSource extends OpenAiDataSource {
  LlmNutritionResult? resultToReturn;
  Exception? errorToThrow;

  @override
  Future<LlmNutritionResult> extractNutrition(
    String apiKey,
    Uint8List imageBytes,
    String mimeType,
  ) async {
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

class MockSecureStorage extends SecureAppStorageProvider {
  String? apiKey;

  @override
  Future<String?> getOpenAiApiKey() async => apiKey;
}

void main() {
  group('ExtractNutritionUsecase', () {
    late MockOpenAiDataSource mockDataSource;
    late MockSecureStorage mockStorage;
    late ExtractNutritionUsecase usecase;

    setUp(() {
      mockDataSource = MockOpenAiDataSource();
      mockStorage = MockSecureStorage();
      usecase = ExtractNutritionUsecase(mockDataSource, mockStorage);
    });

    test('returns result with validation on success', () async {
      mockStorage.apiKey = 'sk-test';
      mockDataSource.resultToReturn = const LlmNutritionResult(
        name: 'Oatmeal',
        caloriesPer100g: 389,
        proteinPer100g: 16.9,
        carbsPer100g: 66.3,
        fatPer100g: 6.9,
        confidence: 'high',
      );

      final result = await usecase.execute(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );

      expect(result.nutrition.name, 'Oatmeal');
      expect(result.nutrition.caloriesPer100g, 389);
      expect(result.validation.status, isA<ValidationStatus>());
    });

    test('throws when API key is missing', () async {
      mockStorage.apiKey = null;

      expect(
        () => usecase.execute(Uint8List.fromList([1, 2, 3]), 'image/jpeg'),
        throwsException,
      );
    });

    test('throws when API key is empty', () async {
      mockStorage.apiKey = '';

      expect(
        () => usecase.execute(Uint8List.fromList([1, 2, 3]), 'image/jpeg'),
        throwsException,
      );
    });

    test('returns error result when OpenAI returns error', () async {
      mockStorage.apiKey = 'sk-test';
      mockDataSource.resultToReturn = const LlmNutritionResult(
        caloriesPer100g: 0,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 0,
        error: 'Label is blurry',
      );

      final result = await usecase.execute(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );

      expect(result.nutrition.hasError, true);
      expect(result.nutrition.error, 'Label is blurry');
    });

    test('propagates API errors', () async {
      mockStorage.apiKey = 'sk-test';
      mockDataSource.errorToThrow = Exception('Network error');

      expect(
        () => usecase.execute(Uint8List.fromList([1, 2, 3]), 'image/jpeg'),
        throwsException,
      );
    });
  });

  group('ExtractNutritionUsecase serving size inference', () {
    late MockOpenAiDataSource mockDataSource;
    late MockSecureStorage mockStorage;
    late ExtractNutritionUsecase usecase;

    setUp(() {
      mockDataSource = MockOpenAiDataSource();
      mockStorage = MockSecureStorage();
      mockStorage.apiKey = 'sk-test';
      usecase = ExtractNutritionUsecase(mockDataSource, mockStorage);
    });

    test('infers servingSizeG from caloriesPerServing ratio', () async {
      // 110 kcal/100g, 206 kcal/pack → pack = (206/110)*100 ≈ 187.3g
      mockDataSource.resultToReturn = const LlmNutritionResult(
        name: 'Sandwich',
        caloriesPer100g: 110,
        caloriesPerServing: 206,
        proteinPer100g: 8,
        carbsPer100g: 15,
        fatPer100g: 3,
        servingUnit: 'pack',
      );

      final result = await usecase.execute(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );

      expect(result.nutrition.servingSizeG, closeTo(187.3, 0.1));
    });

    test('overrides LLM servingSizeG with computed value from ratio', () async {
      // LLM says 40g but ratio says (150/375)*100 = 40g — same, so no change
      mockDataSource.resultToReturn = const LlmNutritionResult(
        name: 'Cereal',
        caloriesPer100g: 375,
        caloriesPerServing: 150,
        servingSizeG: 40,
        proteinPer100g: 10,
        carbsPer100g: 65,
        fatPer100g: 7,
      );

      final result = await usecase.execute(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );

      expect(result.nutrition.servingSizeG, 40);
    });

    test('overrides wrong LLM servingSizeG with correct computed value', () async {
      // LLM says 200g but ratio says (385/206)*100 ≈ 186.9g
      mockDataSource.resultToReturn = const LlmNutritionResult(
        name: 'Sandwich',
        caloriesPer100g: 206,
        caloriesPerServing: 385,
        servingSizeG: 200,
        proteinPer100g: 9.7,
        carbsPer100g: 24.7,
        fatPer100g: 7.1,
        servingUnit: 'pack',
      );

      final result = await usecase.execute(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );

      expect(result.nutrition.servingSizeG, closeTo(186.9, 0.1));
    });

    test('does not infer when caloriesPerServing is null', () async {
      mockDataSource.resultToReturn = const LlmNutritionResult(
        name: 'Test',
        caloriesPer100g: 200,
        proteinPer100g: 10,
        carbsPer100g: 30,
        fatPer100g: 5,
      );

      final result = await usecase.execute(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );

      expect(result.nutrition.servingSizeG, isNull);
    });

    test('does not infer when caloriesPer100g is zero', () async {
      mockDataSource.resultToReturn = const LlmNutritionResult(
        name: 'Test',
        caloriesPer100g: 0,
        caloriesPerServing: 100,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 0,
      );

      final result = await usecase.execute(
        Uint8List.fromList([1, 2, 3]),
        'image/jpeg',
      );

      expect(result.nutrition.servingSizeG, isNull);
    });
  });
}
