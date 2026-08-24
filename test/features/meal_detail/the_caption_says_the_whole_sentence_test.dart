/// The line under the amount box, in full rather than in part.
///
/// Aidan, walking build 53 on 22 August: *"The 'one of them' text is cut off.
/// It reads 'one of them, worked out from what a pac…'"*. He marked the step a
/// pass because the figures were right — but the sentence is the only thing on
/// that screen that says where his number came from, and a sentence that stops
/// mid-word says nothing.
///
/// It was the amount field's own helper text, so it was pinned to half the
/// sheet's width and capped at two lines. Three of the six explanations are
/// longer than the one he happened to hit.
///
/// The carrying test is [the longest explanation there is fits on the screen].
/// Testing the sentence is *present* would have passed all along — Flutter
/// keeps the whole string in the widget and ellipsises it only when painting.
/// What has to be asserted is that the paragraph did not run out of lines.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/config_dao.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_nutriments_entity.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/meal_detail/domain/default_portion.dart';
import 'package:opennutritracker/features/meal_detail/presentation/bloc/meal_detail_bloc.dart';
import 'package:opennutritracker/features/meal_detail/presentation/widgets/meal_detail_bottom_sheet.dart';
import 'package:opennutritracker/generated/l10n.dart';

import '../household/fake_household_server.dart';

class QuietMealDetailBloc extends Fake implements MealDetailBloc {}

void main() {
  final food = MealEntity(
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
    nutriments: const MealNutrimentsEntity(
        energyKcal100: 200,
        carbohydrates100: 18,
        fat100: 9,
        proteins100: 11,
        sugars100: null,
        saturatedFat100: null,
        fiber100: null),
    source: MealSourceEntity.custom,
  );

  late AppDatabase db;
  late HouseholdRepository household;
  late TextEditingController amount;

  /// The sheet on a phone, not on the test binding's wide default surface. The
  /// caption's whole problem is width, so a 800px-wide screen would hide it.
  void aPhoneSizedScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  setUp(() {
    db = AppDatabase.createInMemory();
    final mini = FakeHouseholdServer();
    household = HouseholdRepository(ConfigDao(db),
        HouseholdApi(baseUrl: 'http://mini', client: mini.client));
    amount = TextEditingController(text: '1');
  });

  tearDown(() async {
    amount.dispose();
    await db.close();
  });

  Future<void> theSheet(WidgetTester tester, DefaultPortion portion,
      {String? typedInstead}) async {
    amount.text = typedInstead ?? portion.amount;
    aPhoneSizedScreen(tester);
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
          portion: portion,
          onQuantityOrUnitChanged: (_, __) {},
          mealDetailBloc: QuietMealDetailBloc(),
          selectedUnit: UnitDropdownItem.item.toString(),
          household: household,
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  /// True when the paragraph ran out of room and painted an ellipsis.
  bool cutOff(WidgetTester tester, String sentence) {
    final paragraph =
        tester.renderObject<RenderParagraph>(find.text(sentence));
    return paragraph.didExceedMaxLines;
  }

  testWidgets('the sentence he saw cut off is whole', (tester) async {
    const portion = DefaultPortion('1', PortionSource.oneOfThem);
    await theSheet(tester, portion);

    expect(find.text(portion.explanation), findsOneWidget);
    expect(cutOff(tester, portion.explanation), isFalse,
        reason: 'he read "one of them, worked out from what a pac..."');
  });

  testWidgets('the longest explanation there is fits on the screen',
      (tester) async {
    const portion = DefaultPortion('100', PortionSource.aStandIn);
    await theSheet(tester, portion);

    expect(cutOff(tester, portion.explanation), isFalse,
        reason: 'the stand-in sentence is thirteen characters longer than the '
            'one he happened to hit, so fixing only his case fixes nothing');
  });

  testWidgets('and it goes when the figure stops being ours', (tester) async {
    const portion = DefaultPortion('1', PortionSource.oneOfThem);
    await theSheet(tester, portion, typedInstead: '3');

    expect(find.text(portion.explanation), findsNothing,
        reason: 'a caption describing a number no longer on the screen is '
            'worse than no caption');
  });
}
