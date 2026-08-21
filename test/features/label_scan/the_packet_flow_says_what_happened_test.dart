/// What a person sees after photographing a packet.
///
/// Aidan found this from the outside on 21 August, in his own words: *"there
/// was no success message. It didn't ask me if I wanted to log that food or
/// anything. It literally just stopped. Everything went grey and I had to hit
/// back."* He only found out the peanut butter had been saved at all because he
/// went and scanned its barcode afterwards.
///
/// So this file is not about whether the food is saved — [confirm_and_save_test]
/// already holds that. It is about the screen: what it says while the Mac Mini
/// is reading the photographs, what it says once the food is in the list, and
/// what it says when the reading falls over in a way nobody anticipated. A save
/// nobody is told about is indistinguishable from a save that did not happen.
///
/// **All three routes into the form are held here on purpose.** The photograph
/// route, the hand-typed route and looking a packet up online all save through
/// the same screen, so the confirmation belongs to that screen rather than to
/// any one of them — and a fix that only told the photographer would leave the
/// other two exactly as silent as they were.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/label_capture_dao.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/label_scan/data/guided_capture.dart';
import 'package:opennutritracker/features/label_scan/data/household_label_reader.dart';
import 'package:opennutritracker/features/label_scan/data/label_camera.dart';
import 'package:opennutritracker/features/label_scan/domain/label_shot.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';
import 'package:opennutritracker/features/label_scan/presentation/guided_capture_screen.dart';

import '../household/fake_household_server.dart';

/// A camera that always takes the photograph it is asked for.
class _ObligingCamera implements LabelCamera {
  var taken = 0;

  @override
  Future<String?> take(LabelShot shot, {required String intoDirectory}) async {
    taken += 1;
    return '$intoDirectory/${shot.key}.jpg';
  }
}

void main() {
  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdApi api;
  late HouseholdRepository household;
  late Outbox outbox;
  late HouseholdLogger logger;
  late GuidedCapture capture;
  late _ObligingCamera camera;
  late HouseholdLabelReader reader;

  setUp(() async {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    api = HouseholdApi(baseUrl: 'http://mini', client: mini.client);
    household = HouseholdRepository(ConfigDao(db), api);
    outbox = Outbox.of(db, api);
    logger = HouseholdLogger(household, outbox);
    await household.setOwner(mini.aidan);
    camera = _ObligingCamera();
    capture = GuidedCapture(LabelCaptureDao(db), camera, directory: '/nowhere');
    reader = HouseholdLabelReader(api, readFile: (path) async => const [1, 2, 3]);
    mini.labelRead = const {
      'name': 'Peanut butter',
      'brand': 'Meridian',
      'kcal_100': 600,
      'protein_100': 27,
      'fat_100': 50,
      'carbs_100': 12,
    };
  });

  tearDown(() async => db.close());

  /// The way in the app actually uses: Home, then the packet screen pushed on
  /// top of it — so what the person is looking at afterwards is a real answer
  /// and not an artefact of the screen being the only thing in the tree.
  Widget theApp({HouseholdLabelReader? withReader}) => MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuidedCaptureScreen(
                      capture: capture,
                      reader: withReader ?? reader,
                      logger: logger,
                    ),
                  ),
                ),
                child: const Text('Photograph a packet'),
              ),
            ),
          ),
        ),
      );

  /// A phone-shaped surface tall enough that the whole form is built. Seven
  /// fields and a button do not fit the 800x600 the test binding hands out, and
  /// a button that was never laid out cannot be pressed.
  void giveTheScreenRoom(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  Future<void> openTheCamera(WidgetTester tester) async {
    await tester.tap(find.text('Photograph a packet'));
    await tester.pumpAndSettle();
  }

  Future<void> takeAllThree(WidgetTester tester) async {
    for (final shot in LabelShot.values) {
      await tester.tap(find.widgetWithText(FilledButton, shot.instruction));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('photographing a packet says the food is in the list',
      (tester) async {
    giveTheScreenRoom(tester);
    await tester.pumpWidget(theApp());
    await openTheCamera(tester);
    await takeAllThree(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Read the packet'));
    await tester.pumpAndSettle();

    expect(find.text('Check the numbers'), findsOneWidget,
        reason: 'the numbers should be shown before anything is saved');

    await tester.tap(find.text('Save to the household list'));
    await tester.pumpAndSettle();
    await outbox.drain();

    // The food really is in the household list — that half has always worked.
    expect(mini.foods.values.map((f) => f['name']), contains('Peanut butter'));

    // And the person is told so. This is the whole of Aidan's complaint: the
    // screen closes and he is back where he started with nothing said, so a
    // save that worked and a save that did nothing look identical.
    expect(
        find.widgetWithText(
            SnackBar, ConfirmFoodScreen.savedSentence('Peanut butter')),
        findsOneWidget,
        reason: 'the food was saved and nobody said so');
  });

  testWidgets('the screen says it is reading rather than just greying out',
      (tester) async {
    final gate = Completer<void>();
    final slow = HouseholdLabelReader(api, readFile: (path) async {
      await gate.future;
      return const [1, 2, 3];
    });
    giveTheScreenRoom(tester);
    await tester.pumpWidget(theApp(withReader: slow));
    await openTheCamera(tester);
    await takeAllThree(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Read the packet'));
    await tester.pump();

    // Every button on the screen is disabled while this runs — which is right,
    // and on its own is indistinguishable from the app having died.
    expect(find.textContaining('Reading the packet'), findsOneWidget,
        reason: 'the wait is silent, so a person sees only greyed-out buttons');
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    gate.complete();
    await tester.pumpAndSettle();

    // And it stops saying it once the numbers are up.
    expect(find.textContaining('Reading the packet'), findsNothing);
  });

  testWidgets('a reading that falls over in an unforeseen way is survivable',
      (tester) async {
    // The two failures the screen knows about — unreadable, and the Mini being
    // out of reach — are both handled. This is any third thing: a photograph
    // that is no longer on disk, a reply that will not parse. There is no
    // shortage of third things.
    giveTheScreenRoom(tester);
    final broken = HouseholdLabelReader(api,
        readFile: (path) async => throw StateError('that photograph is gone'));
    await tester.pumpWidget(theApp(withReader: broken));
    await openTheCamera(tester);
    await takeAllThree(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Read the packet'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Something went wrong'), findsOneWidget,
        reason: 'the screen stopped and said nothing about why');

    // And the buttons come back, so the back button is not the only way out.
    final readAgain = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Read the packet'));
    expect(readAgain.onPressed, isNotNull,
        reason: 'every control was left dead — Aidan had to press Back');

    // The photographs are still there to try again with, which is what the
    // message promises.
    expect(find.text('Retake'), findsNWidgets(LabelShot.values.length));
  });

  testWidgets('a food typed in by hand says so too', (tester) async {
    // The sibling route — 'Add a food by hand'. Nothing pops it and nothing
    // listens for the save, so pressing Save is the same silence.
    giveTheScreenRoom(tester);
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Add a food by hand')),
        body: SingleChildScrollView(
          child: ConfirmFoodScreen(logger: logger),
        ),
      ),
    ));
    await tester.enterText(
        find.widgetWithText(TextField, 'Name').first, 'Marmite');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save to the household list'));
    await tester.pumpAndSettle();
    await outbox.drain();

    expect(mini.foods.values.map((f) => f['name']), contains('Marmite'));
    expect(
        find.widgetWithText(
            SnackBar, ConfirmFoodScreen.savedSentence('Marmite')),
        findsOneWidget,
        reason: 'nothing pops this screen, so silence here is permanent');
  });
}
