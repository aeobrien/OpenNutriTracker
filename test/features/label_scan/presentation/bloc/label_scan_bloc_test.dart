import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/label_scan/data/data_source/openai_data_source.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';
import 'package:opennutritracker/features/label_scan/domain/usecase/extract_nutrition_usecase.dart';
import 'package:opennutritracker/features/label_scan/presentation/bloc/label_scan_bloc.dart';

// Manual mocks
class MockExtractNutritionUsecase extends ExtractNutritionUsecase {
  ExtractionResult? resultToReturn;
  Exception? errorToThrow;

  MockExtractNutritionUsecase()
      : super(MockOpenAiDataSource(), MockSecureStorage());

  @override
  Future<ExtractionResult> execute(
      Uint8List imageBytes, String mimeType) async {
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

class MockOpenAiDataSource extends OpenAiDataSource {}

class MockSecureStorage extends SecureAppStorageProvider {
  @override
  Future<String?> getOpenAiApiKey() async => 'test-key';
}

class MockImagePicker extends ImagePicker {
  XFile? fileToReturn;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return fileToReturn;
  }
}

void main() {
  group('LabelScanBloc', () {
    late MockExtractNutritionUsecase mockUsecase;
    late MockImagePicker mockImagePicker;
    late LabelScanBloc bloc;

    setUp(() {
      mockUsecase = MockExtractNutritionUsecase();
      mockImagePicker = MockImagePicker();
      bloc = LabelScanBloc(mockUsecase, imagePicker: mockImagePicker);
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is LabelScanInitialState', () {
      expect(bloc.state, isA<LabelScanInitialState>());
    });

    test('stays in current state when camera is cancelled', () async {
      mockImagePicker.fileToReturn = null;

      bloc.add(const CaptureAndExtractEvent());
      await Future.delayed(const Duration(milliseconds: 100));

      expect(bloc.state, isA<LabelScanInitialState>());
    });

    test('UpdateFieldEvent updates result and re-validates', () async {
      // First set up a result state
      const result = LlmNutritionResult(
        name: 'Test',
        caloriesPer100g: 400,
        proteinPer100g: 20,
        carbsPer100g: 50,
        fatPer100g: 15,
        confidence: 'high',
      );
      final validation = NutritionValidator.validateConsistency(
        reportedKcal: 400,
        proteinGrams: 20,
        carbsGrams: 50,
        fatGrams: 15,
      );

      // Manually emit a result state
      bloc.emit(LabelScanResultState(
        result: result,
        validation: validation,
        meal: result.toMealEntity(),
      ));

      // Now update a field
      bloc.add(const UpdateFieldEvent('caloriesPer100g', '500'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state;
      expect(state, isA<LabelScanResultState>());
      final resultState = state as LabelScanResultState;
      expect(resultState.result.caloriesPer100g, 500);
      // Validation should be recalculated
      expect(resultState.validation, isNotNull);
    });

    test('UpdateFieldEvent updates name', () async {
      const result = LlmNutritionResult(
        name: 'Old Name',
        caloriesPer100g: 100,
        proteinPer100g: 5,
        carbsPer100g: 20,
        fatPer100g: 3,
      );
      final validation = NutritionValidator.validateConsistency(
        reportedKcal: 100,
        proteinGrams: 5,
        carbsGrams: 20,
        fatGrams: 3,
      );

      bloc.emit(LabelScanResultState(
        result: result,
        validation: validation,
        meal: result.toMealEntity(),
      ));

      bloc.add(const UpdateFieldEvent('name', 'New Name'));
      await Future.delayed(const Duration(milliseconds: 100));

      final state = bloc.state as LabelScanResultState;
      expect(state.result.name, 'New Name');
    });

    test('UpdateFieldEvent does nothing when not in result state', () async {
      bloc.add(const UpdateFieldEvent('name', 'Test'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Should still be initial
      expect(bloc.state, isA<LabelScanInitialState>());
    });
  });
}
