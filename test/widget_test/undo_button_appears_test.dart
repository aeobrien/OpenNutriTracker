/// The Undo button itself, on screen, after the real gesture.
///
/// undo_only_reverses_what_this_phone_did_test.dart settles which rows the rule
/// speaks for. This file is about the thing Aidan's thumb meets: swipe a row
/// away and see whether the word UNDO is offered in the bar at the bottom. The
/// two are joined by one line in intake_vertical_list.dart, and a line is
/// exactly the sort of thing that can be right in a getter and wrong on screen.
///
/// Both directions, deliberately, for the reason the rule exists: a row this
/// phone did offers Undo, and a row that came from the kitchen panel does not.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/home/presentation/widgets/intake_vertical_list.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Stand-ins for the two blocs the list reaches for as it is built. Nothing in
/// this file presses Undo, so nothing here has to do anything — they exist so
/// the widget can be built at all.
class _QuietHomeBloc extends Fake implements HomeBloc {
  @override
  void add(dynamic event) {}
}

class _QuietMealDetailBloc extends Fake implements MealDetailBloc {}

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

Widget _aDayWith(List<IntakeEntity> rows) => MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: IntakeVerticalList(
          day: DateTime(2026, 8, 21),
          title: 'Breakfast',
          listIcon: Icons.bakery_dining_outlined,
          addMealType: AddMealType.breakfastType,
          intakeList: rows,
          usesImperialUnits: false,
          onDeleteIntakeCallback: (_, __) {},
        ),
      ),
    );

/// Swipe the named row off the day, the way a person does.
Future<void> swipeAway(WidgetTester tester, String id) async {
  await tester.drag(
      find.byKey(ValueKey('dismiss_$id')), const Offset(-400, 0));
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
      ..registerSingleton<MealDetailBloc>(_QuietMealDetailBloc());
  });

  tearDown(() => GetIt.instance.reset());

  testWidgets('a row this phone did offers Undo', (tester) async {
    await tester.pumpWidget(_aDayWith([
      _row(id: 'mine', label: 'Porridge', externalId: 'house-1',
          thisPhoneDidIt: true),
    ]));
    await tester.pumpAndSettle();

    await swipeAway(tester, 'mine');

    expect(find.widgetWithText(SnackBar, 'Undo'), findsOneWidget);

    await settleTheHidingTimer(tester);
  });

  testWidgets('a row from the kitchen panel does not', (tester) async {
    await tester.pumpWidget(_aDayWith([
      _row(id: 'theirs', label: 'Lasagne', externalId: 'house-2'),
    ]));
    await tester.pumpAndSettle();

    await swipeAway(tester, 'theirs');

    // The bar still comes up saying the row has gone — it is only the offer to
    // put it back that is withheld.
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Undo'), findsNothing);

    await settleTheHidingTimer(tester);
  });
}
