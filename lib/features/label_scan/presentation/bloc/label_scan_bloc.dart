import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';
import 'package:opennutritracker/features/label_scan/domain/usecase/extract_nutrition_usecase.dart';

// Events
abstract class LabelScanEvent extends Equatable {
  const LabelScanEvent();
  @override
  List<Object?> get props => [];
}

class CaptureAndExtractEvent extends LabelScanEvent {
  const CaptureAndExtractEvent();
}

class UpdateFieldEvent extends LabelScanEvent {
  final String field;
  final dynamic value;
  const UpdateFieldEvent(this.field, this.value);
  @override
  List<Object?> get props => [field, value];
}

// States
abstract class LabelScanState extends Equatable {
  const LabelScanState();
  @override
  List<Object?> get props => [];
}

class LabelScanInitialState extends LabelScanState {
  const LabelScanInitialState();
}

class LabelScanProcessingState extends LabelScanState {
  const LabelScanProcessingState();
}

class LabelScanResultState extends LabelScanState {
  final LlmNutritionResult result;
  final ValidationResult validation;
  final MealEntity meal;

  const LabelScanResultState({
    required this.result,
    required this.validation,
    required this.meal,
  });

  @override
  List<Object?> get props => [result, validation, meal];
}

class LabelScanErrorState extends LabelScanState {
  final String message;
  final bool isApiKeyMissing;

  const LabelScanErrorState(this.message, {this.isApiKeyMissing = false});

  @override
  List<Object?> get props => [message, isApiKeyMissing];
}

// BLoC
class LabelScanBloc extends Bloc<LabelScanEvent, LabelScanState> {
  final _log = Logger('LabelScanBloc');
  final ExtractNutritionUsecase _extractNutritionUsecase;
  final ImagePicker _imagePicker;

  LabelScanBloc(this._extractNutritionUsecase, {ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker(),
        super(const LabelScanInitialState()) {
    on<CaptureAndExtractEvent>(_onCaptureAndExtract);
    on<UpdateFieldEvent>(_onUpdateField);
  }

  Future<void> _onCaptureAndExtract(
      CaptureAndExtractEvent event, Emitter<LabelScanState> emit) async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 2048,
      );

      if (image == null) {
        // User cancelled camera — stay in current state
        return;
      }

      emit(const LabelScanProcessingState());

      final imageBytes = await image.readAsBytes();
      final mimeType = _mimeTypeFromPath(image.path);

      final extractionResult =
          await _extractNutritionUsecase.execute(imageBytes, mimeType);

      if (extractionResult.nutrition.hasError) {
        emit(LabelScanErrorState(
            extractionResult.nutrition.error ?? 'Label unreadable'));
        return;
      }

      final meal = extractionResult.nutrition.toMealEntity();
      emit(LabelScanResultState(
        result: extractionResult.nutrition,
        validation: extractionResult.validation,
        meal: meal,
      ));
    } catch (e, stackTrace) {
      _log.severe('Error during label scan', e, stackTrace);
      final message = e.toString();
      final isApiKeyMissing = message.contains('API key not configured');
      emit(LabelScanErrorState(
        isApiKeyMissing ? 'OpenAI API key not set' : 'Error: $message',
        isApiKeyMissing: isApiKeyMissing,
      ));
    }
  }

  void _onUpdateField(UpdateFieldEvent event, Emitter<LabelScanState> emit) {
    final currentState = state;
    if (currentState is! LabelScanResultState) return;

    final r = currentState.result;
    LlmNutritionResult updated;

    switch (event.field) {
      case 'name':
        updated = r.copyWith(name: event.value as String);
        break;
      case 'brand':
        updated = r.copyWith(brand: event.value as String);
        break;
      case 'caloriesPer100g':
        updated = r.copyWith(caloriesPer100g: _parseDouble(event.value));
        break;
      case 'proteinPer100g':
        updated = r.copyWith(proteinPer100g: _parseDouble(event.value));
        break;
      case 'carbsPer100g':
        updated = r.copyWith(carbsPer100g: _parseDouble(event.value));
        break;
      case 'fatPer100g':
        updated = r.copyWith(fatPer100g: _parseDouble(event.value));
        break;
      case 'fiberPer100g':
        updated = r.copyWith(fiberPer100g: _parseDouble(event.value));
        break;
      case 'sugarPer100g':
        updated = r.copyWith(sugarPer100g: _parseDouble(event.value));
        break;
      case 'saturatedFatPer100g':
        updated = r.copyWith(saturatedFatPer100g: _parseDouble(event.value));
        break;
      case 'servingSizeG':
        updated = r.copyWith(servingSizeG: _parseDouble(event.value));
        break;
      default:
        return;
    }

    final validation = NutritionValidator.validateConsistency(
      reportedKcal: updated.caloriesPer100g,
      proteinGrams: updated.proteinPer100g,
      carbsGrams: updated.carbsPer100g,
      fatGrams: updated.fatPer100g,
      fibreGrams: updated.fiberPer100g,
    );

    emit(LabelScanResultState(
      result: updated,
      validation: validation,
      meal: updated.toMealEntity(),
    ));
  }

  double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    }
    return 0;
  }

  String _mimeTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }
}
