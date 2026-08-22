/// What a tap on a food in the picker does, on the card itself.
///
/// The picker is used for two different jobs now. Opened from the plus button
/// it is "log something", and a tap goes on to the screen that asks how much.
/// Opened from a row that already exists it is "this was the wrong thing", and
/// a tap has to come straight back with the food — everything the amount
/// screen would ask is already filled in on the dialog that opened it.
///
/// Nothing drove this card before. The wiring test reads the source and can
/// see the handing-back is written; it cannot see whether the going-on-anyway
/// underneath it still runs, which is one missing `return` away and would log
/// a second row on top of the correction.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/utils/navigation_options.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/add_meal/presentation/add_meal_type.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/meal_item_card.dart';
import 'package:opennutritracker/generated/l10n.dart';

MealEntity _whiteBread() => MealEntity(
      code: 'white-bread',
      name: 'White bread',
      url: null,
      mealQuantity: null,
      mealUnit: 'g',
      servingQuantity: null,
      servingUnit: 'g',
      servingSize: null,
      nutriments: MealNutrimentsEntity(
        energyKcal100: 300,
        proteins100: 8,
        carbohydrates100: 55,
        fat100: 4,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null,
      ),
      source: MealSourceEntity.custom,
    );

void main() {
  // No picture on this food, so the card never reaches for the image cache —
  // which is the only thing on it that wants the app's own wiring.
  /// A screen holding one card, pushed on top of a first screen, so that
  /// coming back off it is something the test can see. [handedBack] collects
  /// whatever the pushed screen returns.
  Widget aPickerWithOneCard(
          {required bool handBackInstead, required List<Object?> handedBack}) =>
      MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routes: {
          NavigationOptions.mealDetailRoute: (context) =>
              const Scaffold(body: Text('how much of it')),
        },
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final back = await Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: MealItemCard(
                      day: DateTime(2026, 8, 22),
                      mealEntity: _whiteBread(),
                      addMealType: AddMealType.breakfastType,
                      usesImperialUnits: false,
                      handBackInstead: handBackInstead,
                    ),
                  ),
                ));
                handedBack.add(back);
              },
              child: const Text('open the picker'),
            ),
          ),
        ),
      );

  Future<void> tapTheFood(WidgetTester tester) async {
    await tester.tap(find.text('open the picker'));
    await tester.pumpAndSettle();
    // The card's own name is drawn by a size-fitting text widget rather than a
    // plain one, so it is reached by the row that takes the tap.
    await tester.tap(find.descendant(
        of: find.byType(MealItemCard), matching: find.byType(InkWell)).first);
    await tester.pumpAndSettle();
  }

  testWidgets('opened to log something, a tap goes on to ask how much',
      (tester) async {
    final handedBack = <Object?>[];
    await tester.pumpWidget(
        aPickerWithOneCard(handBackInstead: false, handedBack: handedBack));
    await tapTheFood(tester);

    expect(find.text('how much of it'), findsOneWidget);
    expect(handedBack, isEmpty, reason: 'the picker is still open behind it');
  });

  testWidgets('opened to replace a food, a tap comes straight back with it',
      (tester) async {
    final handedBack = <Object?>[];
    await tester.pumpWidget(
        aPickerWithOneCard(handBackInstead: true, handedBack: handedBack));
    await tapTheFood(tester);

    expect(handedBack, hasLength(1));
    expect((handedBack.single as MealEntity).name, 'White bread');
  });

  testWidgets('and does not go on to ask how much as well', (tester) async {
    final handedBack = <Object?>[];
    await tester.pumpWidget(
        aPickerWithOneCard(handBackInstead: true, handedBack: handedBack));
    await tapTheFood(tester);

    // One missing `return` and both happen: the dialog is handed its food and
    // the amount screen opens on top of the row it was correcting, ready to
    // log a second one.
    expect(find.text('how much of it'), findsNothing);
  });
}
