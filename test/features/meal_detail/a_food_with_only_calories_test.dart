/// A food you typed in yourself, with its calories on it and nothing else.
///
/// Behaviour under test: what the amount sheet will and will not accept onto a
/// day. Aidan typed a packet of fish cakes in by hand on 22 August — name,
/// calories per 100g, what the pack weighs, how many are in it — saved it, and
/// then could not put it on his day. The Add button was dead, the amount box
/// was dead with it, and the only explanation on screen was "Product missing
/// required kcal or macronutrients information". The form had never asked him
/// for protein, fat or carbohydrate; the sheet demanded all three anyway.
///
/// The carrying test is [a food with calories and no macros can be added]. The
/// two halves of the rule pull in opposite directions and both matter: a food
/// with no calories at all must still be refused, because it would sit on the
/// day looking exactly like food while adding nothing to the total, and a food
/// with calories and no macros must be accepted while *saying* that the day's
/// protein, fat and carbohydrate will be short by whatever was in it. A silent
/// acceptance would be a quieter version of the same lie.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../household/fake_household_server.dart';

class QuietMealDetailBloc extends Fake implements MealDetailBloc {}

void main() {
  /// Six fish cakes in a 400g pack at 200 kcal per 100g — the packet he typed
  /// in, with the three boxes he was never asked for left empty.
  MealEntity fishCakes(
          {double? kcal = 200,
          double? protein,
          double? fat,
          double? carbs}) =>
      MealEntity(
        code: 'fish-cakes',
        name: 'Fish cakes',
        url: null,
        mealQuantity: null,
        mealUnit: 'g',
        servingQuantity: null,
        servingUnit: null,
        servingSize: null,
        packGrams: 400,
        perPack: 6,
        nutriments: MealNutrimentsEntity(
            energyKcal100: kcal,
            carbohydrates100: carbs,
            fat100: fat,
            proteins100: protein,
            sugars100: null,
            saturatedFat100: null,
            fiber100: null),
        source: MealSourceEntity.custom,
      );

  late AppDatabase db;
  late FakeHouseholdServer mini;
  late HouseholdRepository household;
  late TextEditingController amount;

  setUp(() {
    db = AppDatabase.createInMemory();
    mini = FakeHouseholdServer();
    household = HouseholdRepository(
        ConfigDao(db), HouseholdApi(baseUrl: 'http://mini', client: mini.client));
    amount = TextEditingController(text: '2');
  });

  tearDown(() async {
    amount.dispose();
    await db.close();
  });

  Future<void> theSheet(WidgetTester tester, MealEntity food) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: const [
        S.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: S.delegate.supportedLocales,
      home: Scaffold(
        body: MealDetailBottomSheet(
          product: food,
          day: DateTime(2026, 8, 24),
          intakeTypeEntity: IntakeTypeEntity.lunch,
          quantityTextController: amount,
          onQuantityOrUnitChanged: (_, __) {},
          mealDetailBloc: QuietMealDetailBloc(),
          selectedUnit: UnitDropdownItem.item.toString(),
          household: household,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  bool addIsAlive(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).enabled;

  bool amountBoxIsAlive(WidgetTester tester) =>
      tester.widget<TextFormField>(find.byType(TextFormField)).enabled ?? true;

  group('the rule on its own', () {
    test('a packet with calories and nothing else is allowed on a day', () {
      expect(MealDetailBottomSheet.whyThisCannotGoOnADay(fishCakes()), isNull);
    });

    test('a food with no calories at all is not', () {
      expect(MealDetailBottomSheet.whyThisCannotGoOnADay(fishCakes(kcal: null)),
          contains('no calories'));
    });

    test('and the calories-only note is only said when something is missing',
        () {
      expect(MealDetailBottomSheet.caloriesOnlyNote(fishCakes()),
          contains('protein, fat or carbohydrate'));
      expect(
          MealDetailBottomSheet.caloriesOnlyNote(
              fishCakes(protein: 12, fat: 8, carbs: 20)),
          isNull);
    });
  });

  group('the sheet he was actually looking at', () {
    testWidgets('a food with calories and no macros can be added',
        (tester) async {
      await theSheet(tester, fishCakes());

      expect(addIsAlive(tester), isTrue,
          reason: 'this is the packet he typed in himself and could not use');
      expect(amountBoxIsAlive(tester), isTrue,
          reason: 'the amount box was greyed out by the same flag, which is '
              'why he could only change the number with the +0.5 and +1 '
              'buttons and never by typing');
      expect(find.textContaining('count as zero towards those'), findsOneWidget,
          reason: 'accepting it silently would leave the day short on protein '
              'with nothing on screen saying why');
    });

    testWidgets('a food with no calories is still refused, and says why',
        (tester) async {
      await theSheet(tester, fishCakes(kcal: null));

      expect(addIsAlive(tester), isFalse);
      expect(amountBoxIsAlive(tester), isFalse);
      expect(find.textContaining('no calories recorded'), findsOneWidget);
    });

    testWidgets('a complete food says nothing extra at all', (tester) async {
      await theSheet(tester, fishCakes(protein: 12, fat: 8, carbs: 20));

      expect(addIsAlive(tester), isTrue);
      expect(find.textContaining('count as zero towards those'), findsNothing);
      expect(find.textContaining('no calories recorded'), findsNothing);
    });
  });
}
