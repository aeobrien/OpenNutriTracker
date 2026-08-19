/// "Mine" or the other person's, on the dialog that already asks how much.
library;

import 'package:flutter/material.dart';
import 'package:opennutritracker/core/utils/locator.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';

/// Whose day a row already logged should count against.
///
/// It sits on the dialog that edits the amount rather than on a screen of its
/// own, and it saves with it. "I put that on the wrong day" and "I put that on
/// the wrong person" are the same mistake noticed at the same moment, and a
/// move that saved separately from the corrected amount could land without it —
/// leaving both people's totals wrong with nothing to say so.
///
/// Absent entirely until the house has said there is somebody else, so a fresh
/// install, an unclaimed phone, or a Mac Mini that has never answered all leave
/// the dialog looking exactly as it always did.
class WhoseDayIsIt extends StatefulWidget {
  static const mineLabel = 'Mine';

  /// Called with the person to move it to, or null for "leave it on mine".
  final void Function(HouseholdPerson? moveTo) onChanged;

  /// Only so a test can hand in a household. The running app leaves it null
  /// and the control fetches its own.
  final HouseholdRepository? household;

  const WhoseDayIsIt({super.key, required this.onChanged, this.household});

  @override
  State<WhoseDayIsIt> createState() => _WhoseDayIsItState();
}

class _WhoseDayIsItState extends State<WhoseDayIsIt> {
  HouseholdPerson? _other;

  /// Starts on "mine" every time. This is a correction, and the overwhelmingly
  /// common case is that no correction of this kind is being made — so the
  /// control must never arrive already proposing to move somebody's dinner.
  bool _theirs = false;

  @override
  void initState() {
    super.initState();
    _findTheOtherPerson();
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
      // Not being able to name the other person is not worth showing anybody.
      // The control does not appear and the dialog works as it always has.
    }
  }

  @override
  Widget build(BuildContext context) {
    final other = _other;
    if (other == null) return const SizedBox();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Semantics(
        label: _theirs
            ? "This moves to ${other.name}'s day and off yours"
            : 'This stays on your day',
        child: SegmentedButton<bool>(
          segments: [
            const ButtonSegment(
                value: false, label: Text(WhoseDayIsIt.mineLabel)),
            ButtonSegment(value: true, label: Text("${other.name}'s")),
          ],
          selected: {_theirs},
          showSelectedIcon: false,
          onSelectionChanged: (choice) {
            setState(() => _theirs = choice.first);
            widget.onChanged(_theirs ? other : null);
          },
        ),
      ),
    );
  }
}
