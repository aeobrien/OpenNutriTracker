import 'package:animated_flip_counter/animated_flip_counter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/home/presentation/widgets/macro_nutriments_widget.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:opennutritracker/generated/l10n.dart';

class DashboardWidget extends StatelessWidget {
  final double totalKcalDaily;
  final double totalKcalLeft;
  final double totalKcalSupplied;
  final double totalKcalBurned;
  final double totalCarbsIntake;
  final double totalFatsIntake;
  final double totalProteinsIntake;
  final double totalCarbsGoal;
  final double totalFatsGoal;
  final double totalProteinsGoal;
  final double totalKcalBase;
  final double totalKcalEarned;
  final double? weeklyRemaining;
  final double activeCaloriesToday;
  final DateTime? activeCaloriesUpdatedAt;
  final bool healthKitConnected;

  const DashboardWidget({
    super.key,
    required this.totalKcalSupplied,
    required this.totalKcalBurned,
    required this.totalKcalDaily,
    required this.totalKcalLeft,
    required this.totalCarbsIntake,
    required this.totalFatsIntake,
    required this.totalProteinsIntake,
    required this.totalCarbsGoal,
    required this.totalFatsGoal,
    required this.totalProteinsGoal,
    required this.totalKcalBase,
    required this.totalKcalEarned,
    this.weeklyRemaining,
    this.activeCaloriesToday = 0.0,
    this.activeCaloriesUpdatedAt,
    this.healthKitConnected = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOver = totalKcalLeft < 0;
    final gaugeValue = _getGaugeValue();
    final displayKcal = isOver ? totalKcalLeft.abs() : totalKcalLeft;

    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final subdued = onSurface.withAlpha(153);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Date row
              _buildDateRow(context, subdued),
              const SizedBox(height: 12),
              // Calorie circle. Hidden entirely when this person has figures
              // switched off — and so is the gauge, because a ring whose fill
              // is your calorie total is a calorie figure drawn as a picture.
              if (!Figures.off(context))
                CircularPercentIndicator(
                radius: 90.0,
                lineWidth: 13.0,
                animation: true,
                percent: gaugeValue,
                arcType: ArcType.FULL,
                progressColor: theme.colorScheme.primary,
                arcBackgroundColor:
                    theme.colorScheme.primary.withAlpha(50),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedFlipCounter(
                      duration: const Duration(milliseconds: 1000),
                      value: displayKcal.toInt(),
                      textStyle: theme.textTheme.headlineMedium?.copyWith(
                        color: onSurface,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      isOver
                          ? S.of(context).overTargetLabel
                          : S.of(context).kcalLeftLabel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: onSurface,
                      ),
                    ),
                    // NOTE: everything in this centre column is inside the
                    // `if (!Figures.off(context))` above.
                  ],
                ),
                circularStrokeCap: CircularStrokeCap.round,
              ),
              const SizedBox(height: 12),
              // Allowance breakdown row
              if (!Figures.off(context))
                _buildAllowanceRow(context, onSurface, subdued),
              // Active calories line (HealthKit)
              if (!Figures.off(context) &&
                  healthKitConnected &&
                  activeCaloriesToday > 0) ...[
                const SizedBox(height: 4),
                _buildActiveCaloriesLine(context, subdued),
              ],
              // Weekly context line — a calories-remaining figure of its own.
              if (!Figures.off(context) && weeklyRemaining != null) ...[
                const SizedBox(height: 8),
                _buildWeeklyLine(context, subdued),
              ],
              const SizedBox(height: 8),
              // Macro bars
              MacroNutrientsView(
                totalCarbsIntake: totalCarbsIntake,
                totalFatsIntake: totalFatsIntake,
                totalProteinsIntake: totalProteinsIntake,
                totalCarbsGoal: totalCarbsGoal,
                totalFatsGoal: totalFatsGoal,
                totalProteinsGoal: totalProteinsGoal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getGaugeValue() {
    if (totalKcalLeft > totalKcalDaily) return 0;
    if (totalKcalLeft < 0) return 1;
    if (totalKcalDaily <= 0) return 0;
    return (totalKcalDaily - totalKcalLeft) / totalKcalDaily;
  }

  Widget _buildDateRow(BuildContext context, Color subdued) {
    final now = DateTime.now();
    final formatted = DateFormat('EEE d MMM').format(now);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Today',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: subdued,
              ),
        ),
        Text(
          formatted,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: subdued,
              ),
        ),
      ],
    );
  }

  Widget _buildAllowanceRow(
      BuildContext context, Color onSurface, Color subdued) {
    // Bare numbers rather than "1700 kcal" three times over — the row's own
    // labels say what they are. Still routed through the one formatter, which
    // is what keeps them off the screen when figures are switched off.
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildAllowanceColumn(
          context,
          Figures.bare(context, totalKcalBase),
          S.of(context).baseLabel,
          onSurface,
          subdued,
        ),
        _buildAllowanceColumn(
          context,
          Figures.bare(context, totalKcalEarned, sign: true),
          S.of(context).earnedLabel,
          onSurface,
          subdued,
        ),
        _buildAllowanceColumn(
          context,
          Figures.bare(context, totalKcalSupplied),
          S.of(context).eatenLabel,
          onSurface,
          subdued,
        ),
      ],
    );
  }

  Widget _buildAllowanceColumn(
    BuildContext context,
    String value,
    String label,
    Color valueColor,
    Color labelColor,
  ) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: valueColor,
              ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: labelColor,
              ),
        ),
      ],
    );
  }

  Widget _buildActiveCaloriesLine(BuildContext context, Color subdued) {
    String text =
        '${S.of(context).activeCaloriesLabel}: ${Figures.kcal(context, activeCaloriesToday) ?? ''}';
    if (activeCaloriesUpdatedAt != null) {
      final minutesAgo =
          DateTime.now().difference(activeCaloriesUpdatedAt!).inMinutes;
      if (minutesAgo > 15) {
        text +=
            ' (${S.of(context).lastUpdatedLabel('$minutesAgo min')})';
      }
    }
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: subdued,
          ),
    );
  }

  Widget _buildWeeklyLine(BuildContext context, Color subdued) {
    final remaining = weeklyRemaining!;
    final text = remaining >= 0
        ? S.of(context).weeklyUnderLabel(remaining.abs().toInt().toString())
        : S.of(context).weeklyOverLabel(remaining.abs().toInt().toString());
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: subdued,
          ),
    );
  }
}
