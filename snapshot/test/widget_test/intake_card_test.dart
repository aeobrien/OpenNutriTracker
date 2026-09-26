import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opennutritracker/core/domain/entity/intake_entity.dart';
import 'package:opennutritracker/core/domain/entity/intake_type_entity.dart';
import 'package:opennutritracker/core/presentation/widgets/intake_card.dart';
import 'package:opennutritracker/features/add_meal/domain/entity/meal_entity.dart';
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
    home: Scaffold(body: child),
  );
}

IntakeEntity _quickAdd({String? label}) => IntakeEntity(
      id: 'qa-1',
      unit: 'serving',
      amount: 1.0,
      type: IntakeTypeEntity.snack,
      meal: MealEntity.empty(),
      dateTime: DateTime(2026, 2, 23),
      entryType: 'quickAdd',
      quickAddLabel: label,
      snapshotKcal: 350,
    );

void main() {
  group('IntakeCard quick-add visual distinction', () {
    testWidgets('renders bolt badge icon for quick-add entries',
        (tester) async {
      await tester.pumpWidget(_wrap(
        IntakeCard(
          key: const ValueKey('qa-1'),
          intake: _quickAdd(),
          firstListElement: true,
          usesImperialUnits: false,
        ),
      ));
      await tester.pumpAndSettle();

      // The subtle visual distinction is the bolt icon.
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });

    testWidgets('shows the quick-add label when provided', (tester) async {
      await tester.pumpWidget(_wrap(
        IntakeCard(
          key: const ValueKey('qa-1'),
          intake: _quickAdd(label: 'Coffee and toast'),
          firstListElement: true,
          usesImperialUnits: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Coffee and toast'), findsOneWidget);
      expect(find.text('350 kcal'), findsOneWidget);
    });

    testWidgets('falls back to "Quick add" label when none provided',
        (tester) async {
      await tester.pumpWidget(_wrap(
        IntakeCard(
          key: const ValueKey('qa-1'),
          intake: _quickAdd(),
          firstListElement: true,
          usesImperialUnits: false,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Quick add'), findsOneWidget);
    });
  });
}
