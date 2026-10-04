import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/label_scan/data/data_source/openai_data_source.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';
import 'package:opennutritracker/features/label_scan/domain/usecase/extract_nutrition_usecase.dart';
import 'dart:io';

import 'package:opennutritracker/features/label_scan/data/label_scan_offline_exception.dart';
import 'package:opennutritracker/features/label_scan/data/pending_label_scan_queue.dart';
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
  ImageSource? lastSource;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    lastSource = source;
    return fileToReturn;
  }
}

/// Writes a small temp image so XFile.readAsBytes() works in tests.
Future<XFile> _tempImage() async {
  final dir = await Directory.systemTemp.createTemp('bloc_img');
  final file = File('${dir.path}/label.jpg');
  await file.writeAsBytes([1, 2, 3]);
  return XFile(file.path);
}

void main() {
  group('LabelScanBloc', () {
    late MockExtractNutritionUsecase mockUsecase;
    late MockImagePicker mockImagePicker;
    late LabelScanBloc bloc;

    late PendingLabelScanQueue queue;
    late Directory queueTempDir;

    setUp(() async {
      mockUsecase = MockExtractNutritionUsecase();
      mockImagePicker = MockImagePicker();
      queueTempDir =
          await Directory.systemTemp.createTemp('bloc_queue');
      queue = PendingLabelScanQueue(
          baseDirProvider: () async => Directory('${queueTempDir.path}/q'));
      bloc = LabelScanBloc(mockUsecase,
          imagePicker: mockImagePicker, pendingQueue: queue);
    });

    tearDown(() async {
      await bloc.close();
      if (await queueTempDir.exists()) {
        await queueTempDir.delete(recursive: true);
      }
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

    test('gallery source is passed through to the image picker', () async {
      mockImagePicker.fileToReturn = null;

      bloc.add(const CaptureAndExtractEvent(source: ImageSource.gallery));
      await Future.delayed(const Duration(milliseconds: 100));

      expect(mockImagePicker.lastSource, ImageSource.gallery);
    });

    test('emits not-found state when the label cannot be parsed', () async {
      mockImagePicker.fileToReturn = await _tempImage();
      mockUsecase.resultToReturn = const ExtractionResult(
        nutrition: LlmNutritionResult(
          caloriesPer100g: 0,
          proteinPer100g: 0,
          carbsPer100g: 0,
          fatPer100g: 0,
          error: 'Not a nutrition label',
        ),
        validation: ValidationResult(
          calculatedKcal: 0,
          deviationPct: 0,
          status: ValidationStatus.ok,
        ),
      );

      bloc.add(const CaptureAndExtractEvent());
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<LabelScanNotFoundState>());
    });

    test('queues the photo and emits queued state when offline', () async {
      mockImagePicker.fileToReturn = await _tempImage();
      mockUsecase.errorToThrow = const LabelScanOfflineException();

      bloc.add(const CaptureAndExtractEvent());
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<LabelScanQueuedState>());
      expect((bloc.state as LabelScanQueuedState).queuedCount, 1);
      expect(await queue.count(), 1);
    });

    test('processes a queued scan when back online', () async {
      // Pre-seed the queue with one offline scan.
      await queue.enqueue(Uint8List.fromList([9, 9, 9]), 'image/jpeg');

      mockUsecase.resultToReturn = ExtractionResult(
        nutrition: const LlmNutritionResult(
          name: 'Beans',
          caloriesPer100g: 100,
          proteinPer100g: 5,
          carbsPer100g: 15,
          fatPer100g: 1,
        ),
        validation: NutritionValidator.validateConsistency(
          reportedKcal: 100,
          proteinGrams: 5,
          carbsGrams: 15,
          fatGrams: 1,
        ),
      );

      bloc.add(const ProcessQueuedScansEvent());
      await Future.delayed(const Duration(milliseconds: 200));

      expect(bloc.state, isA<LabelScanResultState>());
      expect(await queue.count(), 0);
    });
  });
}
