import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/home/presentation/widgets/macro_nutriments_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

Widget _wrapWidget(MacroNutrientsView widget) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: widget),
  );
}

void main() {
  testWidgets('renders three horizontal bars', (tester) async {
    await tester.pumpWidget(_wrapWidget(const MacroNutrientsView(
      totalCarbsIntake: 100,
      totalFatsIntake: 40,
      totalProteinsIntake: 80,
      totalCarbsGoal: 250,
      totalFatsGoal: 60,
      totalProteinsGoal: 120,
    )));
    await tester.pumpAndSettle();

    expect(find.byType(LinearPercentIndicator), findsNWidgets(3));
  });

  testWidgets('shows correct intake/goal text', (tester) async {
    await tester.pumpWidget(_wrapWidget(const MacroNutrientsView(
      totalCarbsIntake: 100,
      totalFatsIntake: 40,
      totalProteinsIntake: 80,
      totalCarbsGoal: 250,
      totalFatsGoal: 60,
      totalProteinsGoal: 120,
    )));
    await tester.pumpAndSettle();

    expect(find.text('100/250 g'), findsOneWidget);
    expect(find.text('40/60 g'), findsOneWidget);
    expect(find.text('80/120 g'), findsOneWidget);
  });

  testWidgets('handles zero goal gracefully', (tester) async {
    await tester.pumpWidget(_wrapWidget(const MacroNutrientsView(
      totalCarbsIntake: 0,
      totalFatsIntake: 0,
      totalProteinsIntake: 0,
      totalCarbsGoal: 0,
      totalFatsGoal: 0,
      totalProteinsGoal: 0,
    )));
    await tester.pumpAndSettle();

    // Should render without errors - bars at 0%
    expect(find.byType(LinearPercentIndicator), findsNWidgets(3));
    expect(find.text('0/0 g'), findsNWidgets(3));
  });
}
