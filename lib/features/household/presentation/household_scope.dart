import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/data/outbox_sender.dart';
import 'package:opennutritracker/features/household/data/profile_handover.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/household/presentation/whose_phone_page.dart';

/// The household, wrapped around the whole app.
///
/// Two things live here because they have to sit above everything else:
///
///  * **Whose phone this is.** Until somebody has said, the app does not open —
///    every entry has to belong to one of the two people, and there is no
///    sensible default. [HouseholdGate] asks once and then gets out of the way.
///  * **Whether this person sees calorie figures, and whether they are keeping
///    track of their weight.** [FiguresScope] and [WeightTrackingScope] have to
///    be above every screen that could show one, or a screen further down would
///    quietly keep its numbers after the switch was thrown.
///  * **Emptying the queue.** [OutboxSender] is started here rather than from a
///    screen because work held while the Mini was unreachable has to be sent
///    whatever the person happens to be looking at — including nothing, on an
///    app they have just brought back to the front.
///
/// It reads the settings from the person's own record, so handing the phone to
/// the other person changes both at once — call [refreshed] after a change and
/// the app redraws as the new person's.
class HouseholdScope extends StatefulWidget {
  final HouseholdRepository repository;

  /// Empties the household queue. Optional only so a test can mount the scope
  /// without one; the running app always passes it.
  final OutboxSender? sender;

  final Widget child;

  /// Passed down to the "whose phone is this" question, which is the one moment
  /// the household can be asked whether it already knows this person.
  final ProfileHandover? handover;

  const HouseholdScope({
    super.key,
    required this.repository,
    required this.child,
    this.sender,
    this.handover,
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
  bool _weightTrackingOn = true;

  @override
  void initState() {
    super.initState();
    _load();
    widget.sender?.start();
  }

  @override
  void dispose() {
    widget.sender?.stop();
    super.dispose();
  }

  Future<void> _load() async {
    final owner = await widget.repository.storedOwner();
    if (owner == null) return;
    // The cached copy first, so the app is not held up by the network, then
    // whatever the server says.
    final cached = await widget.repository.cachedSettings(owner);
    if (!mounted) return;
    setState(() {
      _figuresOff = cached.figuresOff;
      _weightTrackingOn = cached.weightTrackingOn;
    });
    try {
      final fresh = await widget.repository.settings(owner);
      if (!mounted) return;
      setState(() {
        _figuresOff = fresh.figuresOff;
        _weightTrackingOn = fresh.weightTrackingOn;
      });
    } on HouseholdUnreachable {
      // The cached answer stands. Somebody who asked not to see figures must
      // not start seeing them because the Mini is off.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FiguresScope(
      figuresOff: _figuresOff,
      child: WeightTrackingScope(
        trackingOn: _weightTrackingOn,
        child: HouseholdGate(
          repository: widget.repository,
          handover: widget.handover,
          onAnswered: _load,
          child: widget.child,
        ),
      ),
    );
  }
}
