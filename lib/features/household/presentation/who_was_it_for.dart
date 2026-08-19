/// "Just me" or "both of us", on the sheet that already asks how much.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';

/// Who a food being logged was for.
///
/// Two words and, when the answer is both of you, one more amount. It is not a
/// screen of its own because it is not a separate decision: how much, and for
/// whom, are the same sentence, and splitting them across two screens is how
/// one of them gets forgotten.
///
/// It reports the other person's amount **as typed**, not converted. The unit
/// belongs to the sheet this sits on — grams, ounces, servings — and a control
/// that did its own arithmetic would be a second place for the two people's
/// dinners to disagree.
///
/// Absent entirely until the house has said there is somebody else, so a fresh
/// install, a phone nobody has claimed, or a Mac Mini that has never answered
/// all leave the sheet looking exactly as it always did.
class WhoWasItFor extends StatefulWidget {
  static const justMeLabel = 'Just me';
  static const bothOfUsLabel = 'Both of us';

  /// What the person holding the phone has typed for themselves. Read once, to
  /// start the other person off at the same amount — the usual case — and then
  /// left alone, because it often is not.
  final TextEditingController myAmount;

  /// Called with the other person and their typed amount while "both of us",
  /// and with two nulls while "just me". The amount is exactly what they typed
  /// — see the note above about whose arithmetic this is.
  final void Function(HouseholdPerson? other, double? amount) onChanged;

  /// Only so a test can hand in a household. The running app leaves it null
  /// and the control fetches its own.
  final HouseholdRepository? household;

  const WhoWasItFor({
    super.key,
    required this.myAmount,
    required this.onChanged,
    this.household,
  });

  @override
  State<WhoWasItFor> createState() => _WhoWasItForState();
}

class _WhoWasItForState extends State<WhoWasItFor> {
  HouseholdPerson? _other;

  /// Starts at "just me" every time and is never remembered. A stored answer
  /// is how one shared dinner turns every later breakfast into two.
  bool _bothOfUs = false;

  final _theirAmount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _theirAmount.addListener(_report);
    _findTheOtherPerson();
  }

  @override
  void dispose() {
    _theirAmount.dispose();
    super.dispose();
  }

  Future<void> _findTheOtherPerson() async {
    final household = widget.household ?? locator<HouseholdRepository>();
    try {
      final owner = await household.storedOwner();
      if (owner == null) return;
      final everyone = await household.people();
      final others = everyone.where((p) => p.id != owner).toList();
      if (others.length != 1) return;
      if (!mounted) return;
      setState(() => _other = others.first);
    } catch (_) {
      // Not being able to name the other person is not a failure worth showing
      // anybody. The control does not appear and the sheet works as it always
      // has.
    }
  }

  void _report() {
    final other = _other;
    if (!_bothOfUs || other == null) {
      widget.onChanged(null, null);
      return;
    }
    widget.onChanged(
        other, double.tryParse(_theirAmount.text.replaceAll(',', '.')));
  }

  @override
  Widget build(BuildContext context) {
    final other = _other;
    if (other == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: _bothOfUs
                ? "For both of us — this goes on your day and on ${other.name}'s"
                : 'Just for me — this goes on your day only',
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                    value: false, label: Text(WhoWasItFor.justMeLabel)),
                ButtonSegment(
                    value: true, label: Text(WhoWasItFor.bothOfUsLabel)),
              ],
              selected: {_bothOfUs},
              showSelectedIcon: false,
              onSelectionChanged: (choice) {
                setState(() {
                  _bothOfUs = choice.first;
                  if (_bothOfUs && _theirAmount.text.isEmpty) {
                    _theirAmount.text = widget.myAmount.text;
                  }
                });
                _report();
              },
            ),
          ),
          if (_bothOfUs) ...[
            const SizedBox(height: 8.0),
            TextFormField(
              controller: _theirAmount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                    RegExp(r'^\d+([.,]\d{0,2})?$'))
              ],
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: "${other.name}'s amount",
              ),
            ),
          ],
        ],
      ),
    );
  }
}
