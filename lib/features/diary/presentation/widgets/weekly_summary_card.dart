import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class WeeklySummaryCard extends StatelessWidget {
  final WeeklySummary summary;
  final List<DailyRow> dailyRows;

  const WeeklySummaryCard({
    super.key,
    required this.summary,
    required this.dailyRows,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayFmt = DateFormat.E(); // Mon, Tue, ...
    final dateFmt = DateFormat.MMMd(); // Feb 24

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeaderRow(context, dateFmt),
            const Divider(),

            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Expanded(flex: 2, child: SizedBox()),
                  _headerCell(context, S.of(context).eatenLabel),
                  _headerCell(context, S.of(context).weeklyTargetLabel),
                  _headerCell(context, S.of(context).weeklyNetLabel),
                ],
              ),
            ),

            // Daily rows
            ...dailyRows.map((row) => _buildDayRow(context, row, dayFmt)),

            const Divider(thickness: 1.5),

            // Totals
            _buildTotalsRow(context),

            const SizedBox(height: 12),

            // Macro summary
            _buildMacroSummary(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, DateFormat dateFmt) {
    if (dailyRows.isEmpty) return const SizedBox();
    final first = dailyRows.first.date;
    final last = dailyRows.last.date;
    return Text(
      '${dateFmt.format(first)} – ${dateFmt.format(last)}',
      style: Theme.of(context).textTheme.titleMedium,
    );
  }

  Widget _headerCell(BuildContext context, String label) {
    return Expanded(
      flex: 2,
      child: Text(
        label,
        textAlign: TextAlign.end,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      ),
    );
  }

  Widget _buildDayRow(
      BuildContext context, DailyRow row, DateFormat dayFmt) {
    final theme = Theme.of(context);
    final isToday = DateUtils.isSameDay(row.date, DateTime.now());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dayFmt.format(row.date),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.tracked ? Figures.bare(context, row.kcalIntake) : '—',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.tracked ? Figures.bare(context, row.kcalTarget) : '—',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              row.tracked && !Figures.off(context) ? _formatNet(row.net) : '—',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsRow(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              S.of(context).weeklyTotalLabel,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${summary.totalIntake.round()}',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${summary.totalTarget.round()}',
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatNet(summary.totalNet),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummary(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall;
    final labelStyle =
        style?.copyWith(color: theme.colorScheme.outline);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Macros',
          style: theme.textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _macroChip(
                context,
                S.of(context).proteinLabel,
                summary.totalProtein,
                summary.proteinTarget),
            _macroChip(
                context,
                S.of(context).carbsLabel,
                summary.totalCarbs,
                summary.carbsTarget),
            _macroChip(
                context,
                S.of(context).fatLabel,
                summary.totalFat,
                summary.fatTarget),
          ],
        ),
      ],
    );
  }

  Widget _macroChip(
      BuildContext context, String label, double actual, double target) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.outline)),
        const SizedBox(height: 2),
        Text(
          '${actual.round()}g / ${target.round()}g',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  String _formatNet(double net) {
    final rounded = net.round();
    if (rounded >= 0) return '+$rounded';
    return '$rounded';
  }
}
