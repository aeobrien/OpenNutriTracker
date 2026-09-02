import 'dart:io';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';
import 'package:opennutritracker/features/label_scan/data/label_scan_offline_exception.dart';
import 'package:opennutritracker/features/label_scan/data/pending_label_scan_queue.dart';
import 'package:opennutritracker/features/label_scan/domain/usecase/extract_nutrition_usecase.dart';

// Events
abstract class LabelScanEvent extends Equatable {
  const LabelScanEvent();
  @override
  List<Object?> get props => [];
}

class CaptureAndExtractEvent extends LabelScanEvent {
  /// Where to take the photo from — camera (default) or the photo library.
  final ImageSource source;
  const CaptureAndExtractEvent({this.source = ImageSource.camera});

  @override
  List<Object?> get props => [source];
}

/// Process any photos that were queued while the device was offline.
class ProcessQueuedScansEvent extends LabelScanEvent {
  const ProcessQueuedScansEvent();
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

/// The photo was processed but the label could not be read or parsed. Distinct
/// from a transport error: the user should retake the photo or fall back to
/// manual entry / search-by-name rather than just retrying the same shot.
class LabelScanNotFoundState extends LabelScanState {
  final String message;
  const LabelScanNotFoundState(this.message);

  @override
  List<Object?> get props => [message];
}

/// The device was offline, so the photo has been queued for processing once
/// connectivity returns.
class LabelScanQueuedState extends LabelScanState {
  final int queuedCount;
  const LabelScanQueuedState(this.queuedCount);

  @override
  List<Object?> get props => [queuedCount];
}

// BLoC
class LabelScanBloc extends Bloc<LabelScanEvent, LabelScanState> {
  final _log = Logger('LabelScanBloc');
  final ExtractNutritionUsecase _extractNutritionUsecase;
  final ImagePicker _imagePicker;
  final PendingLabelScanQueue _pendingQueue;

  LabelScanBloc(
    this._extractNutritionUsecase, {
    ImagePicker? imagePicker,
    PendingLabelScanQueue? pendingQueue,
  })  : _imagePicker = imagePicker ?? ImagePicker(),
        _pendingQueue = pendingQueue ?? PendingLabelScanQueue(),
        super(const LabelScanInitialState()) {
    on<CaptureAndExtractEvent>(_onCaptureAndExtract);
    on<ProcessQueuedScansEvent>(_onProcessQueuedScans);
    on<UpdateFieldEvent>(_onUpdateField);
  }

  Future<void> _onCaptureAndExtract(
      CaptureAndExtractEvent event, Emitter<LabelScanState> emit) async {
    try {
      final image = await _imagePicker.pickImage(
        source: event.source,
        imageQuality: 85,
        maxWidth: 2048,
      );

      if (image == null) {
        // User cancelled the picker — stay in current state
        return;
      }

      emit(const LabelScanProcessingState());

      final imageBytes = await image.readAsBytes();
      final mimeType = _mimeTypeFromPath(image.path);

      await _extractAndEmit(imageBytes, mimeType, emit);
    } on LabelScanOfflineException catch (e) {
      _log.warning('Offline during capture — queueing photo', e);
      // The image bytes are re-read inside _extractAndEmit's caller; here the
      // exception escaped before we could queue, so fall through to a generic
      // queued state with whatever is already pending.
      final count = await _pendingQueue.count();
      emit(LabelScanQueuedState(count));
    } catch (e, stackTrace) {
      _log.severe('Error during label scan', e, stackTrace);
      _emitErrorFor(e, emit);
    }
  }

  /// Runs extraction on the given image, emitting the appropriate state.
  /// On an offline failure the image is persisted to the pending queue.
  Future<void> _extractAndEmit(Uint8List imageBytes, String mimeType,
      Emitter<LabelScanState> emit) async {
    try {
      final extractionResult =
          await _extractNutritionUsecase.execute(imageBytes, mimeType);

      if (extractionResult.nutrition.hasError) {
        // The model could read the image but could not parse a nutrition
        // label out of it — this is the "not found" path, not a transport
        // error.
        emit(LabelScanNotFoundState(
            extractionResult.nutrition.error ?? 'Label could not be read'));
        return;
      }

      emit(LabelScanResultState(
        result: extractionResult.nutrition,
        validation: extractionResult.validation,
        meal: extractionResult.nutrition.toMealEntity(),
      ));
    } on LabelScanOfflineException catch (e) {
      _log.warning('Offline — queueing photo for later processing', e);
      await _pendingQueue.enqueue(imageBytes, mimeType);
      final count = await _pendingQueue.count();
      emit(LabelScanQueuedState(count));
    }
  }

  /// Attempts to process every photo queued while offline. Successfully
  /// processed photos are removed from the queue; the first one that yields a
  /// usable result is surfaced. If still offline, the queue is left intact.
  Future<void> _onProcessQueuedScans(
      ProcessQueuedScansEvent event, Emitter<LabelScanState> emit) async {
    final pending = await _pendingQueue.pending();
    if (pending.isEmpty) return;

    _log.fine('Processing ${pending.length} queued label scan(s)');
    emit(const LabelScanProcessingState());

    for (final scan in pending) {
      try {
        final bytes = await File(scan.imagePath).readAsBytes();
        final extractionResult =
            await _extractNutritionUsecase.execute(bytes, scan.mimeType);
        await _pendingQueue.remove(scan.id);

        if (extractionResult.nutrition.hasError) {
          // Skip unreadable queued photos rather than blocking the rest.
          continue;
        }

        emit(LabelScanResultState(
          result: extractionResult.nutrition,
          validation: extractionResult.validation,
          meal: extractionResult.nutrition.toMealEntity(),
        ));
        return;
      } on LabelScanOfflineException {
        // Still offline — keep everything queued and report back.
        emit(LabelScanQueuedState(await _pendingQueue.count()));
        return;
      } catch (e, st) {
        _log.severe('Failed to process queued scan ${scan.id}', e, st);
        // Drop the broken entry so it does not wedge the queue forever.
        await _pendingQueue.remove(scan.id);
      }
    }

    // Nothing yielded a usable result — return to a clean initial state.
    emit(const LabelScanInitialState());
  }

  void _emitErrorFor(Object e, Emitter<LabelScanState> emit) {
    final message = e.toString();
    final isApiKeyMissing = message.contains('API key not configured');
    emit(LabelScanErrorState(
      isApiKeyMissing ? 'OpenAI API key not set' : 'Error: $message',
      isApiKeyMissing: isApiKeyMissing,
    ));
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
