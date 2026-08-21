/// The Undo button itself, on screen, after the real thing a person does.
///
/// undo_only_reverses_what_this_phone_did_test.dart settles which rows the rule
/// speaks for. This file is about the thing Aidan's thumb meets: ask for a row
/// to go, and see whether the word UNDO is offered in the bar at the bottom.
///
/// It used to ask by swiping the card sideways. That gesture is gone — a meal's
/// items sit in a strip that scrolls sideways, and the swipe took every drag
/// meant for the strip, so past three items a meal could not be read at all.
/// Removing is asked for by name now: tap the row, press DELETE in the dialog
/// that opens. The offer to undo moved onto that path rather than leaving with
/// the gesture, and this file is what holds it there.
///
/// Both directions, deliberately, for the reason the rule exists: a row this
/// phone did offers Undo, and a row that came from the kitchen tablet does not.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/presentation/widgets/say_the_row_is_gone.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Stand-ins for what the dialog and the bar reach for as they are built.
/// Nothing in this file presses Undo, so nothing here has to do anything — they
/// exist so the screen can be built at all.
class _QuietHomeBloc extends Fake implements HomeBloc {
  @override
  void add(dynamic event) {}
}

class _QuietMealDetailBloc extends Fake implements MealDetailBloc {}

/// A house that has never answered. The "whose day is it" control on the edit
/// dialog asks it who else lives here; with no answer the control does not
/// appear, which is the ordinary case and not what this file is about.
class _QuietHousehold extends Fake implements HouseholdRepository {
  @override
  Future<int?> storedOwner() async => null;
}

IntakeEntity _row({
  required String id,
  required String label,
  String? externalId,
  bool thisPhoneDidIt = false,
}) =>
    IntakeEntity(
      id: id,
      unit: 'serving',
      amount: 1,
      type: IntakeTypeEntity.breakfast,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 8, 21, 8, 0),
      entryType: 'quickAdd',
      quickAddLabel: label,
      externalId: externalId,
      thisPhoneDidIt: thisPhoneDidIt,
      snapshotKcal: 350,
    );

/// The row, and the path a person takes to remove it: the dialog that opens on
/// a tap, and what Home does with the answer it gives back.
Widget _aRowYouCanTap(IntakeEntity row) => MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final edit = await showDialog<IntakeEdit>(
                context: context,
                builder: (_) =>
                    EditDialog(intakeEntity: row, usesImperialUnits: false),
              );
              if (edit != null && edit.remove && context.mounted) {
                sayTheRowIsGone(context, row);
              }
            },
            child: Text(row.quickAddLabel ?? '?'),
          ),
        ),
      ),
    );

/// Remove the row the way a person does: tap it, then press DELETE.
Future<void> removeTheRow(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
  await tester.tap(find.text('DELETE'));
  await tester.pumpAndSettle();
}

/// The bar hides itself five seconds later on a timer of its own; let it, or
/// the test ends with that timer still pending and the framework says so.
Future<void> settleTheHidingTimer(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 6));
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    GetIt.instance
      ..registerSingleton<HomeBloc>(_QuietHomeBloc())
      ..registerSingleton<MealDetailBloc>(_QuietMealDetailBloc())
      ..registerSingleton<HouseholdRepository>(_QuietHousehold());
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('a row this phone did offers Undo', (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(_row(
        id: 'mine',
        label: 'Porridge',
        externalId: 'house-1',
        thisPhoneDidIt: true)));
    await tester.pumpAndSettle();

    await removeTheRow(tester, 'Porridge');

    expect(find.widgetWithText(SnackBar, 'Undo'), findsOneWidget);

    await settleTheHidingTimer(tester);
  });

  testWidgets('a row from the kitchen tablet does not', (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(
        _row(id: 'theirs', label: 'Lasagne', externalId: 'house-2')));
    await tester.pumpAndSettle();

    await removeTheRow(tester, 'Lasagne');

    // The bar still comes up saying the row has gone — it is only the offer to
    // put it back that is withheld.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Undo'), findsNothing);

    await settleTheHidingTimer(tester);
  });
}
