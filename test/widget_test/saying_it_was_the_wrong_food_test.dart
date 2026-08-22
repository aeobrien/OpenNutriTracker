/// Saying the row was the wrong food, on the dialog itself.
///
/// changing_the_food_behind_a_row_test.dart settles what happens to the row
/// once the dialog has asked for it. This file is the dialog's own half: that
/// the offer is there on a row that has a food behind it and absent on one
/// that does not, that choosing a food changes the calories on screen before
/// anything is saved, and that the choice is what gets handed back.
///
/// The calories moving before OK is pressed is the one worth holding. It is
/// the only way somebody can tell whether the food they picked out of a list of
/// similar names is the one they meant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/edit_dialog.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/what_it_was.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class _QuietHomeBloc extends Fake implements HomeBloc {
  @override
  void add(dynamic event) {}
}

class _QuietMealDetailBloc extends Fake implements MealDetailBloc {}

class _QuietHousehold extends Fake implements HouseholdRepository {
  @override
  Future<int?> storedOwner() async => null;
}

class _QuietLedger extends Fake implements FoodLedger {
  final List<WhatItWas> versions;

  _QuietLedger([this.versions = const []]);

  @override
  Future<List<WhatItWas>> historyOf(String intakeId) async => versions;
}

/// One earlier version of the row, offering its own way back.
final _anOlderVersion = WhatItWas(
  version: 0,
  what: 'corrected',
  snapshot: const {'label': 'Brown bread', 'qty': 60, 'kcal': 150},
  putBack: const {'label': 'Brown bread', 'qty': 60, 'kcal': 150},
);

MealEntity _aFood(String name, double kcalPer100) => MealEntity(
      code: name,
      name: name,
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: kcalPer100,
        proteins100: 8,
        carbohydrates100: 45,
        fat100: 3,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    );

/// 80 g of brown bread at 250 kcal per 100 g — 200 kcal.
IntakeEntity _breadRow() => IntakeEntity(
      id: 'intake-abc',
      unit: 'g',
      amount: 80,
      type: IntakeTypeEntity.lunch,
      meal: _aFood('Brown bread', 250),
      dateTime: DateTime(2026, 8, 22, 13, 5),
    );

IntakeEntity _spokenRow() => IntakeEntity(
      id: 'intake-xyz',
      unit: 'serving',
      amount: 1,
      type: IntakeTypeEntity.breakfast,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 8, 22, 8, 15),
      entryType: 'quickAdd',
      quickAddLabel: 'Porridge',
      snapshotKcal: 350,
    );

/// Two servings of a recipe. It has an amount and a unit like a food row, so
/// it takes the same shape of dialog — but there is no food underneath it,
/// and its amount counts servings of the recipe rather than grams of
/// anything.
IntakeEntity _recipeRow() => IntakeEntity(
      id: 'intake-pie',
      unit: 'serving',
      amount: 2,
      type: IntakeTypeEntity.dinner,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 8, 22, 19, 30),
      entryType: 'recipe',
      quickAddLabel: "Shepherd's pie",
      recipeId: 'pie',
      snapshotKcal: 900,
    );

/// The row, plus a stand-in for the picker: whatever [handsBack] holds is what
/// tapping a food in it would have given.
Widget _aRowYouCanTap(IntakeEntity row, List<IntakeEdit> given,
        {MealEntity? handsBack, List<WhatItWas> history = const []}) =>
    MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      onGenerateRoute: (settings) {
        if (settings.name == NavigationOptions.addMealRoute) {
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(handsBack),
                  child: const Text('pick'),
                ),
              ),
            ),
          );
        }
        return null;
      },
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              final edit = await showDialog<IntakeEdit>(
                context: context,
                builder: (_) => EditDialog(
                  intakeEntity: row,
                  usesImperialUnits: false,
                  ledger: _QuietLedger(history),
                ),
              );
              if (edit != null) given.add(edit);
            },
            child: const Text('open it'),
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
    await tester.tap(find.text('open it'));
    await tester.pumpAndSettle();
  }

  Future<void> pickAFood(WidgetTester tester) async {
    await tester.tap(find.text(EditDialog.changeTheFoodLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text('pick'));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  testWidgets('a row with a food behind it can be told it was another one',
      (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(_breadRow(), []));
    await openIt(tester);

    expect(find.text(EditDialog.changeTheFoodLabel), findsOneWidget);
    expect(find.text('Brown bread'), findsOneWidget);
  });

  testWidgets('a row with nothing behind it is not offered it', (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(_spokenRow(), []));
    await openIt(tester);

    expect(find.text(EditDialog.changeTheFoodLabel), findsNothing,
        reason: 'there is no food to replace — that row is corrected by what '
            'it was called and what it came to');
  });

  testWidgets('a recipe row is not offered it either', (tester) async {
    await tester.pumpWidget(_aRowYouCanTap(_recipeRow(), []));
    await openIt(tester);

    // This row does have an amount and a unit, so it gets the same shape of
    // dialog as a food row and the offer would look at home on it. What it
    // does not have is a food — two servings of a recipe measures nothing a
    // food knows about, so the correction would be refused after the tap.
    expect(find.text(EditDialog.changeTheFoodLabel), findsNothing,
        reason: 'the picker would open, take a choice, and the whole '
            'correction would then be dropped without a word');
  });

  testWidgets('the calories move before anything is saved', (tester) async {
    await tester.pumpWidget(
        _aRowYouCanTap(_breadRow(), [], handsBack: _aFood('White bread', 300)));
    await openIt(tester);

    // 80 g of the bread it arrived as.
    expect(find.textContaining('200'), findsWidgets);

    await pickAFood(tester);

    // The same 80 g, of the bread it now is.
    expect(find.textContaining('240'), findsWidgets);
    expect(find.text('Now: White bread'), findsOneWidget);
  });

  testWidgets('the chosen food is what gets handed back', (tester) async {
    final given = <IntakeEdit>[];
    await tester.pumpWidget(_aRowYouCanTap(_breadRow(), given,
        handsBack: _aFood('White bread', 300)));
    await openIt(tester);
    await pickAFood(tester);
    await save(tester);

    expect(given.single.nowItIs?.name, 'White bread');
    expect(given.single.amount, 80, reason: 'the amount was not touched');
  });

  testWidgets('coming back from the picker without choosing changes nothing',
      (tester) async {
    final given = <IntakeEdit>[];
    await tester
        .pumpWidget(_aRowYouCanTap(_breadRow(), given, handsBack: null));
    await openIt(tester);
    await pickAFood(tester);
    await save(tester);

    expect(given.single.nowItIs, isNull);
    expect(find.text('Now: Brown bread'), findsNothing);
  });

  testWidgets('putting an older version back does not carry the new food',
      (tester) async {
    // Restoring says what the row said. What the row *is* is a different
    // correction and one somebody has to make on purpose — a version from
    // before a swap must not undo the swap by the back door.
    final given = <IntakeEdit>[];
    await tester.pumpWidget(_aRowYouCanTap(_breadRow(), given,
        handsBack: _aFood('White bread', 300),
        history: [_anOlderVersion]));
    await openIt(tester);
    // Picked first, so this cannot pass simply by nothing having been chosen.
    await pickAFood(tester);
    await tester.tap(find.text('Put this back'));
    await tester.pumpAndSettle();

    expect(given.single.kcal, 150, reason: 'sanity: it really did restore');
    expect(given.single.nowItIs, isNull);
  });
}
