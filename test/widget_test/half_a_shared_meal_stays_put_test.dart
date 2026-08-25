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

  /// The one name the house knows this row by. When set, asking about any
  /// other name is refused the way the Mac Mini refuses one — it has no row of
  /// that name, so it answers 404 rather than "nobody else holds it".
  final String? knownAs;

  _Ledger({this.held = const [], this.unreachable = false, this.knownAs});

  /// Every row the "what this used to say" control asked about. Separate from
  /// [asked] because the two questions are asked by different parts of the
  /// dialog and have gone wrong independently.
  final askedForHistory = <String>[];

  @override
  Future<List<WhatItWas>> historyOf(String intakeId) async {
    askedForHistory.add(intakeId);
    if (knownAs != null && intakeId != knownAs) {
      throw HouseholdRefused(404, 'no row called $intakeId has reached here');
    }
    return const [];
  }

  @override
  Future<List<int>> whoElseHolds(String intakeId) async {
    asked.add(intakeId);
    if (unreachable) throw HouseholdUnreachable('it did not answer');
    if (knownAs != null && intakeId != knownAs) {
      throw HouseholdRefused(404, 'no row called $intakeId has reached here');
    }
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

/// The same meal, but logged at the kitchen panel rather than here.
///
/// It came down from the house, so this phone minted a fresh local id for its
/// own copy and the house has never heard that name. The only name that
/// reaches the row at the house is [IntakeEntity.externalId].
final _rowFromTheHouse = IntakeEntity(
  id: 'intake-this-phones-copy',
  externalId: 'house-row-9',
  unit: 'serving',
  amount: 1,
  type: IntakeTypeEntity.dinner,
  meal: MealEntity.empty(),
  dateTime: DateTime(2026, 8, 22, 19, 30),
  entryType: 'quickAdd',
  quickAddLabel: "Shepherd's pie",
  snapshotKcal: 640,
);

Widget _aRowYouCanTap(_Ledger ledger, List<IntakeEdit> given,
        {IntakeEntity? row}) =>
    MaterialApp(
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
                  intakeEntity: row ?? _row,
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

/// The dialog built the way the app builds it.
///
/// [_aRowYouCanTap] hands the ledger in, which no screen in this app does —
/// the `ledger:` argument exists so a test can supply a fake, and the running
/// app leaves it null. Every test above passed on a code path production never
/// took: the refusal read `if (ledger == null) return null` and let the move
/// through. Aidan found it on the phone at the first attempt, on 24 August.
///
/// So this one takes the argument away and makes the dialog find its own
/// ledger, which is the only arrangement the person holding the phone ever
/// gets.
Widget _theRowAsTheAppBuildsIt(List<IntakeEdit> given,
        {IntakeEntity? row}) =>
    MaterialApp(
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
                  intakeEntity: row ?? _row,
                  usesImperialUnits: false,
                  currentOwner: aidan.id,
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

  testWidgets('the refusal happens on the dialog the app actually builds',
      (tester) async {
    // No `ledger:` anywhere here, because there is none anywhere in the app.
    final ledger = _Ledger(held: [emily.id]);
    GetIt.instance.registerSingleton<FoodLedger>(ledger);
    final given = <IntakeEdit>[];

    await tester.pumpWidget(_theRowAsTheAppBuildsIt(given));
    await tester.tap(find.text("Shepherd's pie"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Emily's"));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(ledger.asked, ['intake-abc'],
        reason: 'the dialog found its own ledger and asked');
    expect(find.text(EditDialog.cannotMoveOnto('Emily')), findsOneWidget);
    expect(given, isEmpty, reason: 'nothing moved');
  });

  testWidgets('and an ordinary row still moves, with no ledger handed in',
      (tester) async {
    GetIt.instance.registerSingleton<FoodLedger>(_Ledger());
    final given = <IntakeEdit>[];

    await tester.pumpWidget(_theRowAsTheAppBuildsIt(given));
    await tester.tap(find.text("Shepherd's pie"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Emily's"));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.dialogOKLabel));
    await tester.pumpAndSettle();

    expect(given.single.moveTo, emily.id);
  });

  /// The two tests below are the ones the phone failed on 25 August.
  ///
  /// Every test above uses a row this phone logged, where the name the phone
  /// minted and the name the house knows are the same string — so asking by
  /// the wrong one of the two still reaches the row, and the mistake cannot
  /// show. A row that came down from the kitchen panel has two different
  /// names, and only one of them reaches the house.
  ///
  /// What Aidan saw: the row simply moved onto Emily's day, with no refusal at
  /// all. The house had been asked about a name it had never heard, had said
  /// so, and being told "there is no such row" was being read as "nobody else
  /// holds it".
  Future<void> moveTheHousesRowToEmily(
      WidgetTester tester, _Ledger ledger, List<IntakeEdit> given) async {
    GetIt.instance.registerSingleton<FoodLedger>(ledger);
    await tester.pumpWidget(
        _theRowAsTheAppBuildsIt(given, row: _rowFromTheHouse));
    await tester.tap(find.text("Shepherd's pie"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Emily's"));
    await tester.pumpAndSettle();
    await tester.tap(find.text(S.current.dialogOKLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('a row from the house is asked about by the house\'s name',
      (tester) async {
    final ledger = _Ledger(held: [emily.id], knownAs: 'house-row-9');

    await moveTheHousesRowToEmily(tester, ledger, <IntakeEdit>[]);

    expect(ledger.asked, ['house-row-9'],
        reason: 'this phone\'s own id for its copy means nothing at the house');
  });

  testWidgets('so half of a shared meal from the house stays put too',
      (tester) async {
    final given = <IntakeEdit>[];

    await moveTheHousesRowToEmily(
        tester, _Ledger(held: [emily.id], knownAs: 'house-row-9'), given);

    expect(find.text(EditDialog.cannotMoveOnto('Emily')), findsOneWidget);
    expect(given, isEmpty, reason: 'nothing moved');
  });

  /// The same mistake, in the other question the dialog asks the house.
  ///
  /// Found on 25 August while fixing the refusal above, in the line right next
  /// to it. Both questions go out through [FoodLedger.nameFor], which hands
  /// back whatever name it was given — so asking with this phone's own id
  /// reaches nothing at the house, and "what this used to say" comes back
  /// empty for exactly the rows most likely to have been corrected: the ones
  /// somebody logged at the kitchen panel.
  ///
  /// Nothing about it looks wrong on the screen. An empty history and a row
  /// nobody has ever touched are the same picture.
  testWidgets('its past is asked for by the house\'s name too', (tester) async {
    final ledger = _Ledger(knownAs: 'house-row-9');

    await tester.pumpWidget(
        _aRowYouCanTap(ledger, <IntakeEdit>[], row: _rowFromTheHouse));
    await tester.tap(find.text("Shepherd's pie"));
    await tester.pumpAndSettle();

    expect(ledger.askedForHistory, ['house-row-9'],
        reason: 'this phone\'s own id for its copy means nothing at the house');
  });
}
