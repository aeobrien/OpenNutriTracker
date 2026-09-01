import 'package:flutter/material.dart';
import 'package:opennutritracker/features/add_meal/presentation/bloc/products_bloc.dart';

/// Said above a list of results that came from the second food database.
///
/// The usual database refuses about two asks in three at the moment, and since
/// 1 September a search that has been refused all five times asks a different
/// service rather than showing the cannot-help screen. That trade is worth
/// making — usable results beat no results — but it is a trade, and this is
/// where the screen owns up to it.
///
/// Two costs, both measured on 1 September 2026 and both invisible to whoever
/// is looking at the list:
///
///  * The second service matches worse. "tesco milk" returned milk chocolate
///    lollipops, milk chocolate raisins and milk chocolate orange cookies, with
///    no milk in the top four. The usual service, asked the same words in the
///    same minute, returned semi-skimmed milk.
///  * It carries no serving sizes. Not empty ones — the fields are absent from
///    every record it returns, so the amount always has to be typed in.
///
/// Without this notice both of those read as the app having got worse, which is
/// a completely different repair from the source having refused.
class SecondChoiceNotice extends StatelessWidget {
  static const heading = 'These are second-choice results';

  static const why =
      'The usual food database refused, so these came from a different one. '
      'They match what you typed less well, and none of them carry a serving '
      "size, so you'll need to set the amount yourself.";

  const SecondChoiceNotice({super.key});

  /// The notice for [state], or nothing when there is nothing to own up to.
  ///
  /// The screen asks this rather than deciding for itself, so that what is
  /// tested is the decision the screen actually makes.
  static Widget? forState(ProductsState state) =>
      state is ProductsLoadedState && state.secondChoice
          ? const SecondChoiceNotice()
          : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(heading,
                      style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(why,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
