/// When the second food database answers, the screen says so.
///
/// The fallback built on 1 September 2026 means a search never shows the
/// cannot-help screen: when the usual database has refused all five asks, a
/// second one is asked instead and its results are shown. That is better than
/// nothing, and it is worse than the usual list, which is the whole reason this
/// file exists.
///
/// Measured the same afternoon, same minute, same words typed into both:
///
///  * "tesco milk" — the usual service returned fifty results, all fifty with
///    calories, semi-skimmed milk among them. The second one returned twenty,
///    ten with calories, and the top four were milk chocolate lollipops, milk
///    chocolate raisins, milk chocolate orange cookies and Christmas puddings.
///  * At 15:09 the same day, not one record the second service returned carried
///    a serving size, a serving quantity or a pack quantity — the fields are
///    absent from its answers entirely, not merely empty.
///
/// So a person looking at a second-choice list is looking at something that
/// will often miss what they typed and will never tell them what one portion
/// weighs. If the screen does not say which list it is, they read that as the
/// app having got worse rather than as the source having refused, and the two
/// call for completely different repairs.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';
import 'package:opennutritracker/features/add_meal/presentation/widgets/second_choice_notice.dart';

import 'dart:io';

void main() {
  /// The screen asks this one question and shows what it hands back, so
  /// driving it with real states is driving the screen's own decision rather
  /// than a copy of it.
  group('whether anything is said at all', () {
    test('a second-choice list gets a notice', () {
      expect(
          SecondChoiceNotice.forState(
              const ProductsLoadedState(products: [], secondChoice: true)),
          isNotNull);
    });

    test('the usual list gets none', () {
      expect(
          SecondChoiceNotice.forState(
              const ProductsLoadedState(products: [], secondChoice: false)),
          isNull);
    });

    test("the household's own foods are nobody's second choice", () {
      expect(
          SecondChoiceNotice.forState(const ProductsLoadedState(
              products: [], ours: true, secondChoice: false)),
          isNull);
    });

    test('nothing is said while a search is still running', () {
      expect(SecondChoiceNotice.forState(ProductsLoadingState()), isNull);
      expect(SecondChoiceNotice.forState(ProductsInitial()), isNull);
      expect(SecondChoiceNotice.forState(ProductsFailedState()), isNull);
      expect(SecondChoiceNotice.forState(OurFoodsUnreachableState()), isNull);
    });
  });

  group('what it says', () {
    testWidgets('it names the two things he cannot see for himself',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(body: SecondChoiceNotice())));

      // That this is not the usual list.
      expect(find.text(SecondChoiceNotice.heading), findsOneWidget);
      // Why, and what it costs him.
      expect(find.text(SecondChoiceNotice.why), findsOneWidget);
    });

    test('the words themselves say all three things', () {
      final said =
          '${SecondChoiceNotice.heading} ${SecondChoiceNotice.why}'.toLowerCase();
      expect(said, contains('refus'),
          reason: 'he cannot tell a refused source from a broken app unless '
              'the screen says a source refused');
      expect(said, contains('serving size'),
          reason: 'every one of these results is missing one and he will meet '
              'that on the next screen either way');
      expect(said.contains('match') || said.contains('relevan'), isTrue,
          reason: 'he typed "tesco milk" and got chocolate lollipops; being '
              'told the list is second-choice without being told it matches '
              'worse leaves the surprise intact');
    });
  });

  group('the screen actually shows it', () {
    test('the results list asks for the notice and puts it above the results',
        () {
      final screen = File(
              'lib/features/add_meal/presentation/add_meal_screen.dart')
          .readAsStringSync();
      expect(screen.contains('SecondChoiceNotice.forState'), isTrue,
          reason: 'the notice exists but nothing on the screen asks for it');
      expect(
          screen.indexOf('SecondChoiceNotice.forState') <
              screen.indexOf('_productsSliver(state)'),
          isTrue,
          reason: 'a notice underneath twenty results is a notice he scrolls '
              'past');
    });
  });
}
