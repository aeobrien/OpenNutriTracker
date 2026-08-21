/// A stored address shows what it is stored as.
///
/// Aidan, 21 August 2026: *"the server URL has reverted to the old one, which
/// we changed specifically to fix this."* It had not. His phone had been
/// talking to the right machine all evening — dozens of successful calls a
/// minute — and the real fault was somewhere else entirely.
///
/// What he was looking at was a row that said only "Configured", and a dialog
/// that opened on an empty box with the *old* address sitting in it as
/// greyed-out placeholder text. There is no way to tell that apart from a
/// setting that has emptied itself, so the placeholder reads as the answer,
/// and the next move is to retype something that was never wrong.
///
/// So: a setting that is not a secret shows its value on the row and opens on
/// its value in the box. A secret does neither, because a token is not
/// something to put on a screen somebody may be holding up, and "Configured"
/// is all anybody needs to know about one.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/settings/settings_screen.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget _aSettingHolding(String stored, {required bool secret}) => MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: ApiKeyTile(
          icon: Icons.sync_alt_outlined,
          label: 'Mantel server URL',
          configuredText: 'Configured',
          notSetText: 'Not set',
          hintText: 'http://<machine>:8770',
          obscure: secret,
          getKey: () async => stored,
          setKey: (_) async {},
          deleteKey: () async {},
          hasKey: () async => stored.isNotEmpty,
        ),
      ),
    );

void main() {
  testWidgets('the row says what the address is, not merely that there is one',
      (tester) async {
    await tester.pumpWidget(
        _aSettingHolding('http://Aidans-Mac-mini.local:8770', secret: false));
    await tester.pumpAndSettle();

    expect(find.text('http://Aidans-Mac-mini.local:8770'), findsOneWidget);
    expect(find.text('Configured'), findsNothing,
        reason: '"Configured" tells you nothing you did not already assume');
  });

  testWidgets('the box opens on the address, not on nothing', (tester) async {
    await tester.pumpWidget(
        _aSettingHolding('http://Aidans-Mac-mini.local:8770', secret: false));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Mantel server URL'));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, 'http://Aidans-Mac-mini.local:8770',
        reason: 'an empty box under an example address reads as an empty '
            'setting, which is how a working address gets retyped');
  });

  testWidgets('the old address is not sitting there as an example',
      (tester) async {
    // The specific placeholder that caused this. It was a real address this
    // phone used to use, which is exactly what made an empty box convincing.
    await tester.pumpWidget(_aSettingHolding('', secret: false));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mantel server URL'));
    await tester.pumpAndSettle();

    expect(find.text('http://100.71.40.51:8770'), findsNothing);
  });

  testWidgets('a secret says it is set and nothing more', (tester) async {
    await tester.pumpWidget(_aSettingHolding('a-real-token', secret: true));
    await tester.pumpAndSettle();

    expect(find.text('Configured'), findsOneWidget);
    expect(find.text('a-real-token'), findsNothing);

    await tester.tap(find.text('Mantel server URL'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, isEmpty);
  });
}
