/// Opening the app puts you on your day, and nothing in front of it.
///
/// A fresh install had never accepted the medical disclaimer, so Home put a
/// dialog over itself on the way in. Aidan, 1 September 2026, on build 62:
///
///   "On loading it showed me a disclaimer that I had to dismiss, I think, four
///   or five separate times. Every single time I saw the page behind it
///   starting to load and then it reappeared. I don't want that disclaimer in
///   there at all."
///
/// Two things in that and this covers both. It came back repeatedly because it
/// was asked for from inside the build method: every redraw while the flag was
/// still unset scheduled another one, and confirming it triggers a reload,
/// which redraws. And he does not want it at all — his own app, his own
/// judgement, and the wording is still there to read on purpose in Settings.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/presentation/widgets/disclaimer_dialog.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';

import 'a_home_that_can_be_driven.dart';

void main() {
  tearDown(() async => GetIt.instance.reset());

  testWidgets('a phone that has never accepted the disclaimer is not asked to',
      (tester) async {
    giveTheScreenRoom(tester);
    final home = ADrivableHome(disclaimerAccepted: false);
    home.register();

    await tester.pumpWidget(home.widget);
    await tester.pumpAndSettle();

    expect(find.byType(DisclaimerDialog), findsNothing);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('and it does not come back on a redraw either', (tester) async {
    giveTheScreenRoom(tester);
    final home = ADrivableHome(disclaimerAccepted: false);
    home.register();

    await tester.pumpWidget(home.widget);
    await tester.pumpAndSettle();
    // The reload that used to put it back: the screen redraws with the flag
    // still unset, because nothing has been accepted.
    home.bloc.add(const LoadItemsEvent());
    await tester.pumpAndSettle();

    expect(find.byType(DisclaimerDialog), findsNothing);
  });
}
