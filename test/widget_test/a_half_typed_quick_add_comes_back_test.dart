import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/quick_add/data/repository/quick_add_draft_repository.dart';
import 'package:opennutritracker/features/quick_add/domain/usecase/quick_add_draft_usecase.dart';
import 'package:opennutritracker/features/quick_add/presentation/quick_add_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// He is halfway through typing a quick entry when the phone rings.
///
/// The two cases below are two runs of the app over one database, in order:
/// the first types and lets the app go to the background, the second opens the
/// screen again from nothing. They are deliberately not one test — a second
/// `pumpWidget` inside a single test does not reliably throw the old screen
/// away, and a check that cannot fail is worse than no check. Two tests get a
/// genuinely new widget tree, which is the thing being claimed.
///
/// Nothing here reads the stored draft to see a value was written. The only
/// question asked is the one he would ask: is my typing still on the screen.
void main() {
  late AppDatabase db;

  setUpAll(() async {
    db = AppDatabase.createInMemory();
    await locator.reset();
    locator.registerLazySingleton<QuickAddDraftUsecase>(
      () => QuickAddDraftUsecase(QuickAddDraftRepository(ConfigDao(db))),
    );
  });

  tearDownAll(() async {
    await locator.reset();
    await db.close();
  });

  Widget theScreen() => MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: const QuickAddScreen(),
      );

  /// What is actually in the boxes, in the order they sit on the screen:
  /// calories, protein, carbs, fat, then the label.
  List<String> whatIsTyped(WidgetTester tester) => tester
      .widgetList<EditableText>(find.byType(EditableText))
      .map((field) => field.controller.text)
      .toList();

  testWidgets('first run: he types a bit and the phone rings', (tester) async {
    await tester.pumpWidget(theScreen());
    await tester.pumpAndSettle();

    expect(whatIsTyped(tester), everyElement(isEmpty),
        reason: 'a fresh install opens on empty boxes');

    final boxes = find.byType(EditableText);
    await tester.enterText(boxes.at(0), '250');
    await tester.enterText(boxes.at(1), '12');
    await tester.enterText(boxes.at(4), 'Cereal');
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pumpAndSettle();
  });

  testWidgets('second run: it is still there when he comes back',
      (tester) async {
    await tester.pumpWidget(theScreen());
    await tester.pumpAndSettle();

    final typed = whatIsTyped(tester);
    expect(typed[0], '250');
    expect(typed[1], '12');
    expect(typed[4], 'Cereal');
  });
}
