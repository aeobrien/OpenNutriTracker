/// The history panel on the edit dialog — on screen, the way a thumb meets it.
///
/// Release 7, TM-0023 / BC-0024. what_this_row_used_to_say_test.dart settles
/// what the house sends back and what the ledger makes of it. This file is
/// about the other half: tap a row, see what it used to say, and press "Put
/// this back" — and what the dialog hands to Home when you do.
///
/// The thing being held here is that restoring goes out as an **ordinary
/// correction**. There is one path that writes to a row and putting a version
/// back is that path replayed, not a second way in. If that ever stops being
/// true, the two paths will drift and one of them will be the wrong one.
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
import 'package:opennutritracker/features/household/domain/what_it_was.dart';
import 'package:opennutritracker/features/household/presentation/this_entrys_history.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _QuietHomeBloc extends Fake implements HomeBloc {
  @override
  void add(dynamic event) {}
}

class _QuietMealDetailBloc extends Fake implements MealDetailBloc {}

/// A house that has never said who else lives here, so the "whose day is it"
/// control stays away and this file is only about the history.
class _QuietHousehold extends Fake implements HouseholdRepository {
  @override
  Future<int?> storedOwner() async => null;
}

/// A ledger that answers with whatever the test put in it — or refuses, or
/// cannot be reached.
class _ALedger extends Fake implements FoodLedger {
  final List<WhatItWas> versions;
  final Object? throws;

  _ALedger(this.versions, {this.throws});

  @override
  Future<List<WhatItWas>> historyOf(String intakeId) async {
    if (throws != null) throw throws!;
    return versions;
  }
}

WhatItWas _aVersion({
  int version = 0,
  String what = 'corrected',
  String label = 'Oat biscuits',
  num qty = 40,
  num kcal = 180,
  int? owner,
}) =>
    WhatItWas(
      version: version,
      what: what,
      snapshot: {
        'label': label,
        'qty': qty,
        'unit': 'g',
        'kcal': kcal,
        if (owner != null) 'owner_id': owner,
      },
      putBack: {
        'label': label,
        'qty': qty,
        'unit': 'g',
        'kcal': kcal,
        if (owner != null) 'owner_id': owner,
      },
    );

IntakeEntity _row() => IntakeEntity(
      id: 'intake-abc',
      unit: 'serving',
      amount: 1,
      type: IntakeTypeEntity.snack,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 8, 22, 19, 30),
      entryType: 'quickAdd',
      quickAddLabel: 'Oat biscuits',
      snapshotKcal: 337,
      thisPhoneDidIt: true,
    );

/// The row, and what Home does with the answer the dialog gives back. [given]
/// is written into by the test so it can read what was actually asked for.
Widget _aRowYouCanTap(FoodLedger ledger, List<IntakeEdit> given,
        {int? currentOwner}) =>
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
                  intakeEntity: _row(),
                  usesImperialUnits: false,
                  currentOwner: currentOwner,
                  ledger: ledger,
                ),
              );
              if (edit != null) given.add(edit);
            },
            child: const Text('Oat biscuits'),
          ),
        ),
      ),
    );

void main() {
  setUp(() {
    GetIt.instance
      ..registerSingleton<HomeBloc>(_QuietHomeBloc())
      ..registerSingleton<MealDetailBloc>(_QuietMealDetailBloc())
      ..registerSingleton<HouseholdRepository>(_QuietHousehold());
  });

  tearDown(() => GetIt.instance.reset());

  Future<void> openIt(WidgetTester tester) async {
    await tester.tap(find.text('Oat biscuits').first);
    await tester.pumpAndSettle();
  }

  testWidgets('a row nobody has changed shows no history at all',
      (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(_ALedger(const []), []));
    await tester.pumpAndSettle();
    await openIt(tester);

    expect(find.text(ThisEntrysHistory.heading), findsNothing);
    expect(find.text('Put this back'), findsNothing);
  });

  testWidgets('a row that has been changed shows what it used to say',
      (tester) async {
    await tester
        .pumpWidget(_aRowYouCanTap(_ALedger([_aVersion()]), []));
    await tester.pumpAndSettle();
    await openIt(tester);

    expect(find.text(ThisEntrysHistory.heading), findsOneWidget);
    expect(find.text('Oat biscuits, 40 g, 180 kcal'), findsOneWidget);
    expect(find.text('before it was corrected'), findsOneWidget);
  });

  testWidgets('a removal reads as one, in the house\'s own words',
      (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(
        _ALedger([_aVersion(what: 'taken off')]), []));
    await tester.pumpAndSettle();
    await openIt(tester);

    expect(find.text('before it was taken off'), findsOneWidget);
  });

  testWidgets('every version has its own way back', (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(
        _ALedger([
          _aVersion(version: 1, qty: 75, kcal: 337),
          _aVersion(version: 0, qty: 40, kcal: 180),
        ]),
        []));
    await tester.pumpAndSettle();
    await openIt(tester);

    expect(find.text('Put this back'), findsNWidgets(2));
  });

  testWidgets('pressing it hands back an ordinary correction', (tester) async {
    final given = <IntakeEdit>[];
    await tester
        .pumpWidget(_aRowYouCanTap(_ALedger([_aVersion()]), given));
    await tester.pumpAndSettle();
    await openIt(tester);

    await tester.tap(find.text('Put this back'));
    await tester.pumpAndSettle();

    // The same shape anything typed into this dialog comes back as, so Home
    // saves it down the one path it already has.
    expect(given, hasLength(1));
    expect(given.single.amount, 40);
    expect(given.single.label, 'Oat biscuits');
    expect(given.single.kcal, 180);
    expect(given.single.remove, isFalse);
    expect(given.single.fields,
        {'amount': 40.0, 'label': 'Oat biscuits', 'kcal': 180.0});
  });

  testWidgets('only the fields the house offered back are sent', (tester) async {
    // Written on 22 August after a deliberate break proved nothing: every
    // other test here gives a version the same fields in its snapshot and in
    // its put_back, so reading either one passes. Which fields a correction
    // may touch is the house's rule, and a phone reading the whole row instead
    // would go quietly wrong the day that rule changed — sending a field the
    // house will refuse, and looking exactly like a restore that worked.
    final given = <IntakeEdit>[];
    const houseWillNotTakeTheAmount = WhatItWas(
      version: 0,
      what: 'corrected',
      snapshot: {'label': 'Oat biscuits', 'qty': 40, 'unit': 'g', 'kcal': 180},
      putBack: {'label': 'Oat biscuits', 'kcal': 180},
    );
    await tester.pumpWidget(_aRowYouCanTap(
        _ALedger(const [houseWillNotTakeTheAmount]), given));
    await tester.pumpAndSettle();
    await openIt(tester);

    await tester.tap(find.text('Put this back'));
    await tester.pumpAndSettle();

    expect(given.single.amount, isNull,
        reason: 'the amount is read off the whole row rather than off what '
            'the house said may be replayed');
    expect(given.single.fields, {'label': 'Oat biscuits', 'kcal': 180.0});
  });

  testWidgets('putting back a version from the other person moves it there',
      (tester) async {
    final given = <IntakeEdit>[];
    await tester.pumpWidget(_aRowYouCanTap(
        _ALedger([_aVersion(owner: 2)]), given,
        currentOwner: 1));
    await tester.pumpAndSettle();
    await openIt(tester);

    await tester.tap(find.text('Put this back'));
    await tester.pumpAndSettle();

    expect(given.single.moveTo, 2);
  });

  testWidgets('putting back a version from the same day is not a move',
      (tester) async {
    final given = <IntakeEdit>[];
    await tester.pumpWidget(_aRowYouCanTap(
        _ALedger([_aVersion(owner: 1)]), given,
        currentOwner: 1));
    await tester.pumpAndSettle();
    await openIt(tester);

    await tester.tap(find.text('Put this back'));
    await tester.pumpAndSettle();

    // Saying "move it to whoever already has it" would write a change nobody
    // asked for, and on the house's side that is a version bump which throws
    // away anything still on the wire for the row.
    expect(given.single.moveTo, isNull);
  });

  testWidgets('an unreachable house says so rather than "never changed"',
      (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(
        _ALedger(const [], throws: HouseholdUnreachable('no route')), []));
    await tester.pumpAndSettle();
    await openIt(tester);

    expect(
        find.textContaining("Couldn't reach the house"), findsOneWidget);
    expect(find.text('Put this back'), findsNothing);
  });

  testWidgets('a row the house has never heard of shows nothing',
      (tester) async {
    // Reached, and answered. There is no history — and "couldn't reach the
    // house" about a machine that just replied would be a lie the other way.
    await tester.pumpWidget(_aRowYouCanTap(
        _ALedger(const [],
            throws: HouseholdRefused(404, 'no entry called intake-abc')),
        []));
    await tester.pumpAndSettle();
    await openIt(tester);

    expect(find.textContaining("Couldn't reach"), findsNothing);
    expect(find.text(ThisEntrysHistory.heading), findsNothing);
  });

  testWidgets('the dialog still deletes and cancels as it did', (tester) async {
    final given = <IntakeEdit>[];
    await tester
        .pumpWidget(_aRowYouCanTap(_ALedger([_aVersion()]), given));
    await tester.pumpAndSettle();
    await openIt(tester);

    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();

    expect(given.single.remove, isTrue);
  });
}
