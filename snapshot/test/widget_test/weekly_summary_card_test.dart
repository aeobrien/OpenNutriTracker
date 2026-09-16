import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/widgets/weekly_summary_card.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:opennutritracker/generated/l10n.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  final monday = DateTime(2026, 2, 23); // Monday

  final dailyRows = List.generate(7, (i) {
    final date = monday.add(Duration(days: i));
    final tracked = i < 5; // Mon-Fri tracked, Sat-Sun not
    return DailyRow(
      date: date,
      kcalIntake: tracked ? 2000 : 0,
      kcalTarget: tracked ? 2200 : 0,
      net: tracked ? -200 : 0,
      tracked: tracked,
    );
  });

  final summary = WeeklySummary(
    totalIntake: 10000,
    totalTarget: 11000,
    totalNet: -1000,
    totalProtein: 500,
    totalCarbs: 1200,
    totalFat: 400,
    proteinTarget: 550,
    carbsTarget: 1350,
    fatTarget: 490,
  );

  testWidgets('renders 7 day rows and totals', (tester) async {
    await tester.pumpWidget(_wrap(
      WeeklySummaryCard(summary: summary, dailyRows: dailyRows),
    ));
    await tester.pumpAndSettle();

    // Should show day abbreviations
    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    // Total row
    expect(find.text('10000'), findsOneWidget); // total intake
    expect(find.text('11000'), findsOneWidget); // total target
    expect(find.text('-1000'), findsOneWidget); // total net

    // Untracked days show dashes (Sat/Sun each have 3 dashes: intake, target, net)
    // Count dash texts — 6 dashes for 2 untracked days (3 columns each)
    final dashFinder = find.text('—');
    expect(dashFinder, findsAtLeast(6));
  });

  testWidgets('shows macro summary', (tester) async {
    await tester.pumpWidget(_wrap(
      WeeklySummaryCard(summary: summary, dailyRows: dailyRows),
    ));
    await tester.pumpAndSettle();

    expect(find.text('500g / 550g'), findsOneWidget); // protein
    expect(find.text('1200g / 1350g'), findsOneWidget); // carbs
    expect(find.text('400g / 490g'), findsOneWidget); // fat
  });

  testWidgets('tracked day shows kcal values', (tester) async {
    await tester.pumpWidget(_wrap(
      WeeklySummaryCard(summary: summary, dailyRows: dailyRows),
    ));
    await tester.pumpAndSettle();

    // Monday is tracked: 2000 intake, 2200 target, -200 net
    expect(find.text('2000'), findsNWidgets(5)); // 5 tracked days
    expect(find.text('2200'), findsNWidgets(5));
    expect(find.text('-200'), findsNWidgets(5));
  });
}
