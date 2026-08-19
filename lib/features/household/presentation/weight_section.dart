import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/weight_record.dart';

/// The weight tab, for the person this phone belongs to.
///
/// Shown only when that person has weight tracking switched on. Switching it
/// off makes this disappear and nothing else: the history stays on the server,
/// this widget simply stops asking for it, so switching back on shows exactly
/// what was there before.
class WeightSection extends StatefulWidget {
  final HouseholdRepository repository;
  final int personId;

  const WeightSection({
    super.key,
    required this.repository,
    required this.personId,
  });

  @override
  State<WeightSection> createState() => _WeightSectionState();
}

class _WeightSectionState extends State<WeightSection> {
  bool? _on;
  List<WeightRecord> _weights = const [];
  String? _problem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant WeightSection old) {
    super.didUpdateWidget(old);
    if (old.personId != widget.personId) _load();
  }

  Future<void> _load() async {
    try {
      final settings = await widget.repository.settings(widget.personId);
      if (!mounted) return;
      setState(() {
        _on = settings.weightTrackingOn;
        _problem = null;
      });
      if (!settings.weightTrackingOn) {
        // Nothing is fetched and nothing is cleared server-side; the list here
        // is only what this screen is currently showing.
        setState(() => _weights = const []);
        return;
      }
      final rows = await widget.repository.weights(widget.personId);
      if (!mounted) return;
      setState(() => _weights = rows);
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem =
          "Can't reach the kitchen computer, so your weights aren't showing "
          'right now. (${e.message})');
    }
  }

  /// Called by the screen above when the switch has just been changed, so the
  /// tab appears or disappears without waiting for a fresh visit.
  Future<void> refresh() => _load();

  @override
  Widget build(BuildContext context) {
    if (_problem != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(_problem!,
            style: TextStyle(color: Theme.of(context).colorScheme.error)),
      );
    }
    if (_on != true) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('Weight'),
        ),
        if (_weights.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Nothing recorded yet.'),
          ),
        for (final w in _weights)
          ListTile(
            title: Text('${w.kg} kg'),
            subtitle: Text(w.day),
          ),
      ],
    );
  }
}
