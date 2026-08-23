/// Moving half a shared meal onto the person who already has the other half.
///
/// BC-0026's one refusal. Every other move is allowed without asking anybody —
/// two people who agreed to share a system need no permission from each other
/// — and this one is refused because nothing about the result would look
/// wrong. Two ordinary rows on one ordinary day, one dinner counted twice
/// against one person, and the other with none of it.
///
/// The Mac Mini refuses it as well, and its refusal is the authoritative one:
/// it is the only machine that can see both halves. But its answer comes back
/// through the queue, some time after this screen has gone and after the row
/// has already left this phone's day. So the phone asks first, and the person
/// hears it while they are still looking at the row.
///
/// The one thing it could still be is that the meal was never shared and this
/// half should not be on anybody's day — so the refusal offers to delete it.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/domain/what_it_was.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _QuietHomeBloc extends Fake implements HomeBloc {
  @override
  void add(dynamic event) {}
}

class _QuietMealDetailBloc extends Fake implements MealDetailBloc {}

const aidan = HouseholdPerson(id: 1, name: 'Aidan');
const emily = HouseholdPerson(id: 2, name: 'Emily');

/// A house with two people in it, so the "whose day is it" control appears.
class _TwoOfThem extends Fake implements HouseholdRepository {
  @override
  Future<int?> storedOwner() async => aidan.id;

  @override
  Future<List<HouseholdPerson>> people() async => const [aidan, emily];
}

/// A ledger that answers who else holds the other halves of a row.
class _Ledger extends Fake implements FoodLedger {
  /// Whose days the other halves are on. Empty is the ordinary row.
  final List<int> held;

  /// Set to make asking fail the way an asleep Mac Mini fails.
  final bool unreachable;

  /// Every row this was asked about, so a test can prove it was asked at all.
  final asked = <String>[];

  _Ledger({this.held = const [], this.unreachable = false});

  @override
  Future<List<WhatItWas>> historyOf(String intakeId) async => const [];

  @override
  Future<List<int>> whoElseHolds(String intakeId) async {
    asked.add(intakeId);
    if (unreachable) throw HouseholdUnreachable('it did not answer');
    return held;
  }
}

final _row = IntakeEntity(
  id: 'intake-abc',
  unit: 'serving',
  amount: 1,
  type: IntakeTypeEntity.dinner,
  meal: MealEntity.empty(),
  dateTime: DateTime(2026, 8, 22, 19, 30),
  entryType: 'quickAdd',
  quickAddLabel: "Shepherd's pie",
  snapshotKcal: 640,
  thisPhoneDidIt: true,
);

Widget _aRowYouCanTap(_Ledger ledger, List<IntakeEdit> given) => MaterialApp(
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
                builder: (_) => EditDialog(
                  intakeEntity: _row,
                  usesImperialUnits: false,
                  ledger: ledger,
                ),
              );
              if (edit != null) given.add(edit);
            },
            child: const Text("Shepherd's pie"),
          ),
        ),
      ),
    );

void main() {
  setUp(() {
    GetIt.instance
      ..registerSingleton<HomeBloc>(_QuietHomeBloc())
      ..registerSingleton<MealDetailBloc>(_QuietMealDetailBloc())
      ..registerSingleton<HouseholdRepository>(_TwoOfThem());
  });

  tearDown(() => GetIt.instance.reset());

  /// Open the row, ask for it to go onto Emily's day, and press OK.
  Future<void> moveItToEmily(WidgetTester tester, _Ledger ledger,
      List<IntakeEdit> given) async {
    await tester.pumpWidget(_aRowYouCanTap(ledger, given));
    await tester.tap(find.text("Shepherd's pie"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Emily's"));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.dialogOKLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('it says why, rather than moving it', (tester) async {
    final given = <IntakeEdit>[];

    await moveItToEmily(tester, _Ledger(held: [emily.id]), given);

    expect(find.text(EditDialog.cannotMoveOnto('Emily')), findsOneWidget);
    expect(given, isEmpty, reason: 'nothing was asked of the diary');
  });

  testWidgets('and offers to delete it, in case it was never shared',
      (tester) async {
    final given = <IntakeEdit>[];
    await moveItToEmily(tester, _Ledger(held: [emily.id]), given);

    await tester.tap(find.text(EditDialog.notReallySharedLabel));
    await tester.pumpAndSettle();

    expect(given.single.remove, isTrue);
    expect(given.single.moveTo, isNull,
        reason: 'the entry goes away; it does not go away *and* move');
  });

  testWidgets('leaving it alone changes nothing at all', (tester) async {
    final given = <IntakeEdit>[];
    await moveItToEmily(tester, _Ledger(held: [emily.id]), given);

    await tester.tap(find.text(EditDialog.leaveItLabel));
    await tester.pumpAndSettle();

    expect(given, isEmpty);
    expect(find.byType(EditDialog), findsOneWidget,
        reason: 'the person is still on the row they were correcting');
  });

  testWidgets('an ordinary row moves without any of this', (tester) async {
    final given = <IntakeEdit>[];
    final ledger = _Ledger();

    await moveItToEmily(tester, ledger, given);

    expect(ledger.asked, ['intake-abc'], reason: 'it did ask');
    expect(given.single.moveTo, emily.id);
  });

  testWidgets('a house that cannot be asked moves nothing', (tester) async {
    // Not "nobody holds it". The mistake this prevents cannot be seen once it
    // has been made, so an unanswered question is not an answer.
    final given = <IntakeEdit>[];

    await moveItToEmily(tester, _Ledger(unreachable: true), given);

    expect(given, isEmpty, reason: 'nothing moved');
    expect(find.textContaining("Can't reach the Mac Mini"), findsOneWidget);
    expect(find.text(EditDialog.notReallySharedLabel), findsOneWidget,
        reason: 'the way out is still offered — a row that should not be on '
            'anybody\'s day can still be taken off one');
  });

  testWidgets('a correction that moves nothing never asks', (tester) async {
    final given = <IntakeEdit>[];
    final ledger = _Ledger(held: [emily.id]);
    await tester.pumpWidget(_aRowYouCanTap(ledger, given));
    await tester.tap(find.text("Shepherd's pie"));
    await tester.pumpAndSettle();

    await tester.tap(find.text(S.current.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(ledger.asked, isEmpty,
        reason: 'a round trip on every save, for a question about a move '
            'nobody asked for');
    expect(given, hasLength(1));
  });
}
