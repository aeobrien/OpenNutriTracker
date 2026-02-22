import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class MacroNutrientsView extends StatelessWidget {
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;

  const MacroNutrientsView({
    super.key,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildMacroBar(
          context,
          label: S.of(context).carbsLabel,
          intake: totalCarbsIntake,
          goal: totalCarbsGoal,
        ),
        const SizedBox(height: 8),
        _buildMacroBar(
          context,
          label: S.of(context).fatLabel,
          intake: totalFatsIntake,
          goal: totalFatsGoal,
        ),
        const SizedBox(height: 8),
        _buildMacroBar(
          context,
          label: S.of(context).proteinLabel,
          intake: totalProteinsIntake,
          goal: totalProteinsGoal,
        ),
      ],
    );
  }

  Widget _buildMacroBar(
    BuildContext context, {
    required String label,
    required double intake,
    required double goal,
  }) {
    final percent = _getPercentage(goal, intake);
    final theme = Theme.of(context);

    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Expanded(
          child: LinearPercentIndicator(
            lineHeight: 8.0,
            animation: true,
            percent: percent,
            barRadius: const Radius.circular(4),
            progressColor: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withAlpha(50),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72,
          child: Text(
            '${intake.toInt()}/${goal.toInt()} g',
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  double _getPercentage(double goal, double intake) {
    if (intake <= 0 || goal <= 0) return 0;
    if (intake > goal) return 1;
    return intake / goal;
  }
}
