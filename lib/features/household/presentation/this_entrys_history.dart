/// What this row said before somebody changed it, on the dialog that changes
/// it.
library;

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/household/data/food_ledger.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/domain/what_it_was.dart';

/// Everything one logged row has been, with a way back to any of it.
///
/// Release 7, TM-0023 / BC-0024. It sits on the dialog that corrects the row
/// rather than on a screen of its own, for the same reason "whose day is it"
/// does: it is looked at in the moment of making a correction, and the whole
/// point of it is to make that correction safe to make.
///
/// **Absent entirely when the row has never been changed**, which is the usual
/// case. A dialog that always carried an empty "History" heading would put a
/// change in front of somebody where none was made.
///
/// **Not absent when the house cannot be reached.** That is the one distinction
/// this control exists to keep: "this was never corrected" is a fact about the
/// row and "I could not ask" is a fact about the network, and showing the second
/// as the first would tell somebody their correction never happened. So an
/// unreachable house says so, in one quiet line.
class ThisEntrysHistory extends StatefulWidget {
  static const heading = 'What this used to say';

  /// The diary row's own id. The household row is named from it — see
  /// [FoodLedger.nameFor] — so nothing here has to know how.
  final String intakeId;

  /// Called with the version somebody asked to have back. The dialog turns it
  /// into an ordinary correction and saves it the way it saves any other, so
  /// there is no second way of writing to a row.
  final void Function(WhatItWas) onPutBack;

  /// Only so a test can hand in a ledger. The running app leaves it null and
  /// the control fetches its own.
  final FoodLedger? ledger;

  const ThisEntrysHistory({
    super.key,
    required this.intakeId,
    required this.onPutBack,
    this.ledger,
  });

  @override
  State<ThisEntrysHistory> createState() => _ThisEntrysHistoryState();
}

class _ThisEntrysHistoryState extends State<ThisEntrysHistory> {
  List<WhatItWas>? _versions;
  bool _couldNotAsk = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  Future<void> _read() async {
    final ledger = widget.ledger ?? locator<FoodLedger>();
    try {
      final versions = await ledger.historyOf(widget.intakeId);
      if (!mounted) return;
      setState(() => _versions = versions);
    } on HouseholdRefused {
      // A row the house has never heard of — anything logged before the two
      // machines shared a name for a row, and anything logged only here. It
      // was reached and it answered: there is no history, and saying "couldn't
      // reach the house" about a machine that just replied would be a lie in
      // the other direction.
      if (!mounted) return;
      setState(() => _versions = const []);
    } catch (_) {
      // Unreachable, too slow, or anything else that means the question was
      // not answered. All of it must read differently from "no history".
      if (!mounted) return;
      setState(() => _couldNotAsk = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_couldNotAsk) {
      return _quietly(
          context,
          "Couldn't reach the house, so what this used to say isn't here.");
    }
    final versions = _versions;
    // Still asking, or nothing to say. Both show nothing: a spinner on a
    // dialog somebody opened to type a number into is noise.
    if (versions == null || versions.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          Text(
            ThisEntrysHistory.heading,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 4.0),
          for (final was in versions) _oneVersion(context, was),
          const SizedBox(height: 4.0),
          // Said once, plainly, rather than worked out per version. Every one
          // of these fields is one this dialog can change; nothing else on the
          // row is, so nothing else comes back.
          _quietly(
              context,
              'Putting one back restores its amount, its name, its calories '
              'and whose day it is. Which meal of the day and which date stay '
              'as they are now.'),
        ],
      ),
    );
  }

  Widget _oneVersion(BuildContext context, WhatItWas was) {
    // 'corrected' | 'taken off' | 'put back' — the house's own words, and
    // already plain, so they are shown rather than translated.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Semantics(
              label: 'Before it was ${was.what}: ${was.line}',
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(was.line,
                        style: Theme.of(context).textTheme.bodyMedium),
                    Text(
                      'before it was ${was.what}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => widget.onPutBack(was),
            child: const Text('Put this back'),
          ),
        ],
      ),
    );
  }

  Widget _quietly(BuildContext context, String words) => Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          words,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.6),
              ),
        ),
      );
}
