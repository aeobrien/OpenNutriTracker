/// Four things about photographing a packet, met where a person meets them.
///
/// Three of the four are checked by driving the real scan screen and reading
/// what is on it — the words, the buttons, and what pressing one does. The
/// fourth (re-photographing a packet you already have) has no screen of its
/// own: what a person sees is their food list holding one entry instead of
/// two, and the thing that decides which of those happens is the identity the
/// entry is stored under. So that one is checked one step below the screen, on
/// the identity itself, and this is said out loud rather than dressed up as a
/// screen test.
///
/// The point of writing them this way is that every one of these can fail, and
/// each was watched failing before it was believed. Put the old scan screen
/// back and the three screen cases go red — no library button, no separate
/// answer for a photo with no label in it, nothing kept when the phone has no
/// signal — while the two that do not touch the screen stay green. Put the old
/// food identity back and only the last one goes red, with the other four
/// untouched. Neither run had to be argued with.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:opennutritracker/core/utils/calc/nutrition_validator.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/label_scan/data/data_source/openai_data_source.dart';
import 'package:opennutritracker/features/label_scan/data/dto/llm_nutrition_result.dart';
import 'package:opennutritracker/features/label_scan/data/label_scan_offline_exception.dart';
import 'package:opennutritracker/features/label_scan/data/pending_label_scan_queue.dart';
import 'package:opennutritracker/features/label_scan/domain/usecase/extract_nutrition_usecase.dart';
import 'package:opennutritracker/features/label_scan/presentation/bloc/label_scan_bloc.dart';
import 'package:opennutritracker/features/label_scan/presentation/label_scan_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Stands in for the model. It can answer with a packet, say it could not find
/// a label in the photo, or refuse because the phone has no signal.
class _TheModel extends ExtractNutritionUsecase {
  _TheModel() : super(_NoDataSource(), _NoKeyNeeded());

  LlmNutritionResult? answer;
  Object? refusal;
  int calls = 0;

  @override
  Future<ExtractionResult> execute(Uint8List bytes, String mimeType) async {
    calls++;
    if (refusal != null) throw refusal!;
    return ExtractionResult(
      nutrition: answer!,
      validation: const ValidationResult(
        calculatedKcal: 0,
        deviationPct: 0,
        status: ValidationStatus.ok,
      ),
    );
  }
}

class _NoDataSource extends OpenAiDataSource {}

class _NoKeyNeeded extends SecureAppStorageProvider {
  @override
  Future<String?> getOpenAiApiKey() async => 'not-used';
}

/// Stands in for the camera roll and the camera. Records which one was asked
/// for, because that is the whole of the first claim.
class _ThePicker extends ImagePicker {
  XFile? photo;
  ImageSource? askedFor;

  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    askedFor = source;
    return photo;
  }
}

/// A photo held in memory rather than on disk. A widget test runs its clock
/// by hand, and a real file read never finishes under it — see
/// [letTheDiskCatchUp] for the places where disk is unavoidable.
XFile _aPhoto() => XFile.fromData(
      Uint8List.fromList([9, 9, 9]),
      mimeType: 'image/jpeg',
      name: 'label.jpg',
    );

/// The offline queue genuinely writes to disk, and disk work does not happen
/// while a widget test is holding the clock. This hands the clock back for a
/// moment so the write can land, then draws the screen again.
Future<void> letTheDiskCatchUp(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)));
    for (var j = 0; j < 5; j++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
  }
}

LlmNutritionResult _aPacket({String name = 'Oat Crunch', String? brand}) =>
    LlmNutritionResult(
      name: name,
      brand: brand,
      caloriesPer100g: 412,
      proteinPer100g: 8,
      carbsPer100g: 62,
      fatPer100g: 14,
    );

void main() {
  late _TheModel model;
  late _ThePicker picker;
  late Directory queueDir;
  late PendingLabelScanQueue queue;

  setUp(() async {
    model = _TheModel();
    picker = _ThePicker();
    picker.photo = _aPhoto();
    queueDir = await Directory.systemTemp.createTemp('pending_scans');
    queue = PendingLabelScanQueue(baseDirProvider: () async => queueDir);

    await locator.reset();
    locator.registerFactory<LabelScanBloc>(() => LabelScanBloc(
          model,
          imagePicker: picker,
          pendingQueue: queue,
        ));
  });

  tearDown(() async {
    await locator.reset();
    if (await queueDir.exists()) await queueDir.delete(recursive: true);
  });

  Widget theScanScreen() => MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const LabelScanScreen(),
      );

  testWidgets('he can pick a photo he already took, not only take a new one',
      (tester) async {
    model.answer = _aPacket();

    await tester.pumpWidget(theScanScreen());
    await tester.pumpAndSettle();

    // The way in has to be on the screen and readable, not buried.
    expect(find.text('Choose from library'), findsOneWidget);

    await tester.tap(find.text('Choose from library'));
    await letTheDiskCatchUp(tester);

    // And it has to actually open the library rather than the camera.
    expect(picker.askedFor, ImageSource.gallery);
  });

  testWidgets('a photo with no label in it says so, and offers a way on',
      (tester) async {
    // The model read the photo perfectly well. There was no nutrition label
    // in it.
    model.answer = const LlmNutritionResult(
      caloriesPer100g: 0,
      proteinPer100g: 0,
      carbsPer100g: 0,
      fatPer100g: 0,
      error: 'No nutrition information visible',
    );

    await tester.pumpWidget(theScanScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await letTheDiskCatchUp(tester);

    expect(find.textContaining("Couldn't read a nutrition label"),
        findsOneWidget);
    // Two ways on, both of which make sense for this fault: another photo, or
    // stop photographing and look the thing up.
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
  });

  testWidgets('an offline photo is kept, and Try now picks it up',
      (tester) async {
    model.refusal = const LabelScanOfflineException();

    await tester.pumpWidget(theScanScreen());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take Photo'));
    await letTheDiskCatchUp(tester);

    expect(find.textContaining("You're offline"), findsOneWidget);
    expect(find.text('Try now'), findsOneWidget);
    // Kept, not merely announced — there is a photo on disk to come back to.
    // Reading the disk has to be done on the real clock, hence runAsync.
    expect(await tester.runAsync(() => queue.count()), 1);

    // Signal comes back. He presses the button rather than starting again,
    // and that press sends the kept photo off to be read — one more call than
    // the single failed one he made a moment ago.
    model.refusal = null;
    model.answer = _aPacket();
    await tester.tap(find.text('Try now'));
    await letTheDiskCatchUp(tester);

    expect(model.calls, 2,
        reason: 'Try now re-read the photo it kept, rather than doing nothing');
  });

  // What that press then produces is checked below rather than on the screen.
  // A widget test drives the clock by hand, and the last few steps of reading
  // the photo back off disk do not finish under it — so asserting the result
  // screen there would be asserting the harness, not the app. Run on the real
  // clock instead, driving the same event the button sends.
  test('the photo it kept turns into a packet, and stops being kept', () async {
    final model = _TheModel()..answer = _aPacket();
    final dir = await Directory.systemTemp.createTemp('pending_scans_real');
    final queue = PendingLabelScanQueue(baseDirProvider: () async => dir);
    await queue.enqueue(Uint8List.fromList([9, 9, 9]), 'image/jpeg');
    expect(await queue.count(), 1);

    final bloc = LabelScanBloc(model, pendingQueue: queue);
    final seen = <LabelScanState>[];
    final sub = bloc.stream.listen(seen.add);

    bloc.add(const ProcessQueuedScansEvent());
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(seen.last, isA<LabelScanResultState>());
    expect((seen.last as LabelScanResultState).result.name, 'Oat Crunch');
    expect(await queue.count(), 0, reason: 'the kept photo has been used up');

    await sub.cancel();
    await bloc.close();
    await dir.delete(recursive: true);
  });

  test('photographing the same packet twice gives one food, not two', () {
    // Two separate scans, minutes or weeks apart. What decides whether his
    // food list ends up with one Oat Crunch or two is the identity each scan
    // stores it under.
    final first = _aPacket(brand: 'Store own').toMealEntity();
    final second = _aPacket(brand: 'Store own').toMealEntity();
    expect(second.code, first.code);

    // And it must not be so blunt that two different things collide.
    final somethingElse = _aPacket(name: 'Rye Crisp').toMealEntity();
    expect(somethingElse.code, isNot(first.code));

    // Case and stray spacing are how the same packet gets typed differently,
    // not how two packets differ.
    final sameShouted = _aPacket(name: 'OAT  CRUNCH', brand: 'STORE OWN')
        .toMealEntity();
    expect(sameShouted.code, first.code);
  });
}
