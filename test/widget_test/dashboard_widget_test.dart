import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/features/home/presentation/widgets/dashboard_widget.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget _wrapWidget(DashboardWidget widget) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: widget)),
  );
}

DashboardWidget _defaultDashboard({
  double totalKcalLeft = 500,
  double totalKcalSupplied = 1500,
  double totalKcalDaily = 2000,
  double totalKcalBurned = 300,
  double totalKcalBase = 1700,
  double totalKcalEarned = 300,
  double? weeklyRemaining,
}) {
  return DashboardWidget(
    totalKcalSupplied: totalKcalSupplied,
    totalKcalBurned: totalKcalBurned,
    totalKcalDaily: totalKcalDaily,
    totalKcalLeft: totalKcalLeft,
    totalCarbsIntake: 200,
    totalFatsIntake: 50,
    totalProteinsIntake: 100,
    totalCarbsGoal: 250,
    totalFatsGoal: 60,
    totalProteinsGoal: 120,
    totalKcalBase: totalKcalBase,
    totalKcalEarned: totalKcalEarned,
    weeklyRemaining: weeklyRemaining,
  );
}

void main() {
  testWidgets('renders today\'s date', (tester) async {
    await tester.pumpWidget(_wrapWidget(_defaultDashboard()));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
  });

  testWidgets('shows "kcal left" when under target', (tester) async {
    await tester.pumpWidget(_wrapWidget(_defaultDashboard(totalKcalLeft: 500)));
    await tester.pumpAndSettle();

    expect(find.text('kcal left'), findsOneWidget);

    final flipCounter = tester
        .firstWidget<AnimatedFlipCounter>(find.byType(AnimatedFlipCounter));
    expect(flipCounter.value, 500);
  });

  testWidgets('shows "over target" when over (neutral styling)', (tester) async {
    await tester.pumpWidget(
        _wrapWidget(_defaultDashboard(totalKcalLeft: -200)));
    await tester.pumpAndSettle();

    expect(find.text('over target'), findsOneWidget);

    final flipCounter = tester
        .firstWidget<AnimatedFlipCounter>(find.byType(AnimatedFlipCounter));
    expect(flipCounter.value, 200);
  });

  testWidgets('shows allowance breakdown row (base + earned + eaten)',
      (tester) async {
    await tester.pumpWidget(_wrapWidget(_defaultDashboard(
      totalKcalBase: 1700,
      totalKcalEarned: 300,
      totalKcalSupplied: 1500,
    )));
    await tester.pumpAndSettle();

    expect(find.text('1700'), findsOneWidget);
    expect(find.text('+300'), findsOneWidget);
    expect(find.text('1500'), findsOneWidget);
    expect(find.text('base'), findsOneWidget);
    expect(find.text('earned'), findsOneWidget);
    expect(find.text('eaten'), findsOneWidget);
  });

  testWidgets('shows weekly context line when under target', (tester) async {
    await tester.pumpWidget(
        _wrapWidget(_defaultDashboard(weeklyRemaining: 1500)));
    await tester.pumpAndSettle();

    expect(find.text('This week: 1500 kcal under target'), findsOneWidget);
  });

  testWidgets('shows weekly context line when over target', (tester) async {
    await tester.pumpWidget(
        _wrapWidget(_defaultDashboard(weeklyRemaining: -500)));
    await tester.pumpAndSettle();

    expect(find.text('This week: 500 kcal over target'), findsOneWidget);
  });

  testWidgets('over-target gauge uses primary colour, never the error colour',
      (tester) async {
    await tester.pumpWidget(
        _wrapWidget(_defaultDashboard(totalKcalLeft: -200)));
    await tester.pumpAndSettle();

    final BuildContext context =
        tester.element(find.byType(DashboardWidget));
    final scheme = Theme.of(context).colorScheme;

    final indicator = tester.firstWidget<CircularPercentIndicator>(
        find.byType(CircularPercentIndicator));
    expect(indicator.progressColor, scheme.primary);
    expect(indicator.progressColor, isNot(scheme.error));
  });

  testWidgets('over-target text "over target" is not coloured red/error',
      (tester) async {
    await tester.pumpWidget(
        _wrapWidget(_defaultDashboard(totalKcalLeft: -200)));
    await tester.pumpAndSettle();

    final BuildContext context =
        tester.element(find.byType(DashboardWidget));
    final scheme = Theme.of(context).colorScheme;

    final overText = tester.firstWidget<Text>(find.text('over target'));
    expect(overText.style?.color, isNot(scheme.error));
    expect(overText.style?.color, scheme.onSurface);
  });

  testWidgets('hides weekly context when null', (tester) async {
    await tester.pumpWidget(
        _wrapWidget(_defaultDashboard(weeklyRemaining: null)));
    await tester.pumpAndSettle();

    expect(find.textContaining('This week'), findsNothing);
  });
}
