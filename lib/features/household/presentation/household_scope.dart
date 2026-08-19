import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/household/presentation/whose_phone_page.dart';

/// The household, wrapped around the whole app.
///
/// Two things live here because they have to sit above everything else:
///
///  * **Whose phone this is.** Until somebody has said, the app does not open —
///    every entry has to belong to one of the two people, and there is no
///    sensible default. [HouseholdGate] asks once and then gets out of the way.
///  * **Whether this person sees calorie figures.** [FiguresScope] has to be
///    above every screen that could show one, or a screen further down would
///    quietly keep its numbers after the switch was thrown.
///
/// It reads the settings from the person's own record, so handing the phone to
/// the other person changes both at once — call [refreshed] after a change and
/// the app redraws as the new person's.
class HouseholdScope extends StatefulWidget {
  final HouseholdRepository repository;
  final Widget child;

  const HouseholdScope({
    super.key,
    required this.repository,
    required this.child,
  });

  /// Reload the household settings — after the phone changes hands, or after
  /// the figures switch is thrown. Safe to call when there is no scope above.
  static void refreshed(BuildContext context) {
    context.findAncestorStateOfType<_HouseholdScopeState>()?._load();
  }

  @override
  State<HouseholdScope> createState() => _HouseholdScopeState();
}

class _HouseholdScopeState extends State<HouseholdScope> {
  bool _figuresOff = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final owner = await widget.repository.storedOwner();
    if (owner == null) return;
    // The cached copy first, so the app is not held up by the network, then
    // whatever the server says.
    final cached = await widget.repository.cachedSettings(owner);
    if (!mounted) return;
    setState(() => _figuresOff = cached.figuresOff);
    try {
      final fresh = await widget.repository.settings(owner);
      if (!mounted) return;
      setState(() => _figuresOff = fresh.figuresOff);
    } on HouseholdUnreachable {
      // The cached answer stands. Somebody who asked not to see figures must
      // not start seeing them because the Mini is off.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FiguresScope(
      figuresOff: _figuresOff,
      child: HouseholdGate(
        repository: widget.repository,
        onAnswered: _load,
        child: widget.child,
      ),
    );
  }
}
