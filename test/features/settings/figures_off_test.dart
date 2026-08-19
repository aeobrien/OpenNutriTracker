/// Turning every calorie figure off, and it staying off.
///
/// Behaviour under test (Release 1, promise 9): a person can turn every calorie
/// figure off and still have the plan and one-tap logging, while their ledger
/// keeps counting underneath.
///
/// The plan review's specific worry was leakage — figures suppressed on the
/// headline but still sitting on a picker row, a portion sheet, a meal screen
/// or an edit sheet, so the person who asked not to see calories meets one
/// unexpectedly weeks later. So this file does two different things:
///
///  * it renders the calorie-bearing surfaces and asserts nothing numeric
///    survives the switch being thrown, and that the same surfaces do show
///    their figures when it is not;
///  * it reads the app's own source and fails if a calorie figure is assembled
///    anywhere except the one formatter. That second test is the one that
///    matters in a year: a screen added later cannot leak silently, because
///    adding it the wrong way breaks the build.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget _wrap(Widget child, {required bool figuresOff}) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: FiguresScope(
      figuresOff: figuresOff,
      child: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

/// Anything that reads as a calorie figure: the word itself, or one of the
/// specific numbers this test put in.
final _calorieText = RegExp(r'\bkcal\b|\b1500\b|\b2000\b|\b500\b|\b350\b');

Finder _anyCalorieText() => find.byWidgetPredicate((widget) {
      if (widget is! Text) return false;
      final text = widget.data ?? widget.textSpan?.toPlainText() ?? '';
      return _calorieText.hasMatch(text);
    });

DashboardWidget _dashboard() => const DashboardWidget(
      totalKcalSupplied: 1500,
      totalKcalBurned: 300,
      totalKcalDaily: 2000,
      totalKcalLeft: 500,
      totalCarbsIntake: 200,
      totalFatsIntake: 50,
      totalProteinsIntake: 100,
      totalCarbsGoal: 250,
      totalFatsGoal: 60,
      totalProteinsGoal: 120,
      totalKcalBase: 1700,
      totalKcalEarned: 300,
    );

IntakeEntity _intake() => IntakeEntity(
      id: 'i-1',
      unit: 'serving',
      amount: 1.0,
      type: IntakeTypeEntity.snack,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 8, 19),
      entryType: 'quickAdd',
      quickAddLabel: 'Coffee and toast',
      snapshotKcal: 350,
    );

/// The one rule, written once and used by both the guard and the test that
/// proves the guard can fail.
bool assemblesACalorieFigure(String line) =>
    RegExp(r'kcalLabel').hasMatch(line) ||
    (line.contains(r'$') && RegExp(r'\bkcal\b').hasMatch(line));

void main() {
  group('the headline', () {
    testWidgets('shows the figures when they are on', (tester) async {
      await tester.pumpWidget(_wrap(_dashboard(), figuresOff: false));
      await tester.pumpAndSettle();

      expect(_anyCalorieText(), findsWidgets);
    });

    testWidgets('shows no calorie figure at all when they are off',
        (tester) async {
      await tester.pumpWidget(_wrap(_dashboard(), figuresOff: true));
      await tester.pumpAndSettle();

      expect(_anyCalorieText(), findsNothing);
    });

    testWidgets('keeps the macro bars, which are not calorie figures',
        (tester) async {
      await tester.pumpWidget(_wrap(_dashboard(), figuresOff: true));
      await tester.pumpAndSettle();

      // Grams of protein are not what she asked to stop seeing.
      expect(find.textContaining('g'), findsWidgets);
    });
  });

  group('a logged item', () {
    testWidgets('carries its figure when they are on', (tester) async {
      await tester.pumpWidget(_wrap(
        IntakeCard(
          key: const ValueKey('i-1'),
          intake: _intake(),
          firstListElement: true,
          usesImperialUnits: false,
        ),
        figuresOff: false,
      ));
      await tester.pumpAndSettle();

      expect(_anyCalorieText(), findsWidgets);
    });

    testWidgets('shows no figure when they are off, but is still there',
        (tester) async {
      await tester.pumpWidget(_wrap(
        IntakeCard(
          key: const ValueKey('i-1'),
          intake: _intake(),
          firstListElement: true,
          usesImperialUnits: false,
        ),
        figuresOff: true,
      ));
      await tester.pumpAndSettle();

      expect(_anyCalorieText(), findsNothing);
      // One-tap logging is the point: the item is still on the screen and
      // still says what it is.
      expect(find.text('Coffee and toast'), findsOneWidget);
    });
  });

  group('the formatter itself', () {
    testWidgets('gives nothing back when figures are off', (tester) async {
      String? withFigures;
      String? withoutFigures;
      await tester.pumpWidget(_wrap(
        Builder(builder: (context) {
          withFigures = Figures.kcal(context, 320);
          return const SizedBox.shrink();
        }),
        figuresOff: false,
      ));
      await tester.pumpWidget(_wrap(
        Builder(builder: (context) {
          withoutFigures = Figures.kcal(context, 320);
          return const SizedBox.shrink();
        }),
        figuresOff: true,
      ));

      expect(withFigures, '320 kcal');
      expect(withoutFigures, isNull);
    });

    testWidgets('a widget with no scope above it still shows figures',
        (tester) async {
      // The default has to be "shown". A screen that forgets the scope must
      // fail visibly rather than silently hiding somebody's calories.
      String? text;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          text = Figures.kcal(context, 320);
          return const SizedBox.shrink();
        }),
      ));
      expect(text, '320 kcal');
    });
  });

  group('nothing assembles a calorie figure on its own', () {
    /// Where a figure is legitimately not a figure: the label on a box the
    /// person is typing into, and lines that go to the log rather than to a
    /// screen.
    bool isAllowed(String line) {
      final trimmed = line.trim();
      if (trimmed.startsWith('//')) return true;
      if (RegExp(r'\b(suffixText|labelText|hintText|label):').hasMatch(line)) {
        return true;
      }
      if (RegExp(r'_log\.|\blog\.(fine|info|warning|severe|config)')
          .hasMatch(line)) {
        return true;
      }
      return line.contains('Figures.');
    }

    test('every calorie figure on screen comes from the one formatter', () {
      final offenders = <String>[];
      for (final entity in Directory('lib').listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        // Generated localisations and drift output are not hand-written
        // surfaces; what reaches them is governed by the formatter.
        if (entity.path.contains('/generated/') ||
            entity.path.endsWith('.g.dart') ||
            entity.path.endsWith('figures.dart')) {
          continue;
        }
        // Only screens can leak a figure to a person.
        if (!entity.path.contains('/presentation/') &&
            !entity.path.contains('/widgets/')) {
          continue;
        }
        final lines = entity.readAsStringSync().split('\n');
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (isAllowed(line)) continue;
          if (assemblesACalorieFigure(line)) {
            offenders.add('${entity.path}:${i + 1}: ${line.trim()}');
          }
        }
      }
      expect(
        offenders,
        isEmpty,
        reason: 'These build a calorie figure without going through Figures, '
            'so they would keep showing it after the switch is thrown:\n'
            '${offenders.join('\n')}',
      );
    });

    test('the guard would actually catch a leak', () {
      // A test that can never fail is worse than no test, so the rule is run
      // against the shape of line it exists to catch.
      const leak = r"        Text('${intake.totalKcal.toInt()} kcal'),";
      expect(assemblesACalorieFigure(leak), isTrue);
      const fine = r"        Figures.kcalText(context, intake.totalKcal),";
      expect(assemblesACalorieFigure(fine), isFalse);
    });
  });
}
