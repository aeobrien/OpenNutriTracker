/// Typing a weight, and seeing that it saved.
///
/// The fault of 20 August 2026, in Aidan's words: "Just went in and entered my
/// weight as 114.8kg and hit ok. In profile, weight still shows as 115kg …
/// Saving weight did not appear to save weight."
///
/// He was right about what he saw and wrong about the cause, and the cause was
/// worse: there was no way to type a weight at all. The dialog was a hundred-
/// kilogram ruler, 114.8 kg is one division in a thousand of it, and the value
/// never left the centre — the household ledger recorded exactly 115.0. A
/// control that silently stores something other than what you told it is worse
/// than one that refuses, because there is nothing to notice.
///
/// (The second half of what he saw is fixed on the profile row itself, which
/// used to round to the whole unit — so a weight that *had* saved correctly
/// still showed the same "115" as before.)
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/profile/presentation/widgets/set_weight_dialog.dart';
import 'package:opennutritracker/generated/l10n.dart';

void main() {
  Widget host(void Function(double?) took, {double from = 115.0}) => MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                took(await showDialog<double>(
                  context: context,
                  builder: (_) =>
                      SetWeightDialog(userWeight: from, usesImperialUnits: false),
                ));
              },
              child: const Text('open'),
            ),
          ),
        ),
      );

  Future<void> open(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('the number can be typed, and it is what comes back',
      (tester) async {
    double? got;
    await tester.pumpWidget(host((v) => got = v));
    await open(tester);

    await tester.enterText(find.byType(TextField), '114.8');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(got, 114.8);
  });

  testWidgets('it opens showing the weight it is about to change',
      (tester) async {
    await tester.pumpWidget(host((_) {}));
    await open(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller!.text, '115.0');
  });

  testWidgets('a comma for a decimal point is still a weight', (tester) async {
    double? got;
    await tester.pumpWidget(host((v) => got = v));
    await open(tester);

    await tester.enterText(find.byType(TextField), '114,8');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(got, 114.8);
  });

  testWidgets('OK will not save something that is not a weight',
      (tester) async {
    var returned = false;
    await tester.pumpWidget(host((_) => returned = true));
    await open(tester);

    await tester.enterText(find.byType(TextField), '');
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Still open, nothing saved — rather than quietly keeping the old number,
    // which is the exact failure this dialog exists to stop.
    expect(returned, isFalse);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('cancel saves nothing', (tester) async {
    double? got;
    var returned = false;
    await tester.pumpWidget(host((v) {
      got = v;
      returned = true;
    }));
    await open(tester);

    await tester.enterText(find.byType(TextField), '114.8');
    await tester.pump();
    await tester.tap(find.text('CANCEL'));
    await tester.pumpAndSettle();

    expect(returned, isTrue);
    expect(got, isNull);
  });
}
