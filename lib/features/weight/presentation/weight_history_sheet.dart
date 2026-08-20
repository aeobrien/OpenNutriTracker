import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/domain/weight_record.dart';
import 'package:opennutritracker/features/weight/data/weight_repository.dart';
import 'package:opennutritracker/features/weight/domain/weight_history.dart';

/// Everything somebody has weighed in at, opened from the weight row on
/// Profile.
///
/// A sheet rather than a screen, and no new tab: the weight already lives on
/// Profile and this is the same fact in more detail. Aidan stopped an earlier
/// build because a second Today tab sat beside the Home tab doing the same job
/// — a weight tab beside the weight row would be that mistake again.
///
/// Each day says where its number came from when it did not come from the
/// scales, so a reading that looks wrong can be traced without asking anybody.
class WeightHistorySheet extends StatefulWidget {
  final WeightRepository repository;

  const WeightHistorySheet({super.key, required this.repository});

  static const heading = 'Weight';

  /// What the control that opens this sheet says on the profile page.
  ///
  /// It used to be a bare chart icon whose only explanation was a tooltip, and
  /// a tooltip is a thing you get by hovering a mouse — there is no mouse. On
  /// 20 August 2026 Aidan was asked to bring his weights in from Apple Health,
  /// which lives in here, and reported: "No idea where this is." He had been
  /// tapping the row, which opens the weight dialog. An unlabelled icon on a
  /// row that already has a purpose is not a way in.
  static const openLabel = 'Past weights';
  static const nothingYet = 'No weights yet.';
  static const bringIn = 'Bring in from Apple Health';
  static const bringingIn = 'Bringing them in…';
  static const foundNothing = 'Nothing new in Apple Health.';
  static const fromHealth = 'from Apple Health';
  static const unreachable =
      "Can't reach the kitchen computer, so this may not be the whole story.";
  static const cannotBringIn =
      "Can't reach the kitchen computer, so there's no telling which of these "
      'it already has. Try again when it\'s back.';

  /// 'Brought in 12 readings.' — plural handled, because '1 readings' is the
  /// sort of thing that makes a person distrust the rest of the screen.
  static String broughtIn(int n) =>
      n == 1 ? 'Brought in 1 reading.' : 'Brought in $n readings.';

  /// How a day is written in the list — '18 Aug'.
  static String when(String day) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final date = DateTime.parse(day);
    return '${date.day} ${months[date.month - 1]}';
  }

  static Future<void> show(BuildContext context,
      {required WeightRepository repository}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => WeightHistorySheet(repository: repository),
    );
  }

  @override
  State<WeightHistorySheet> createState() => WeightHistorySheetState();
}

class WeightHistorySheetState extends State<WeightHistorySheet> {
  WeightHistory? _history;
  String? _problem;
  String? _said;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final history = await widget.repository.history();
      if (!mounted) return;
      setState(() {
        _history = history;
        _problem = null;
      });
    } on HouseholdUnreachable catch (_) {
      if (!mounted) return;
      setState(() => _problem = WeightHistorySheet.unreachable);
    }
  }

  Future<void> bringIn() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _said = null;
    });
    try {
      final n = await widget.repository.bringInFromAppleHealth();
      if (!mounted) return;
      setState(() => _said =
          n == 0 ? WeightHistorySheet.foundNothing : WeightHistorySheet.broughtIn(n));
      await _load();
    } on HouseholdUnreachable catch (_) {
      // Without the history there is no way to know which days are already
      // here, and importing a year of readings blind is worse than waiting.
      if (!mounted) return;
      setState(() => _said = WeightHistorySheet.cannotBringIn);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final history = _history;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(WeightHistorySheet.heading,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            if (_problem != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(WeightHistorySheet.unreachable,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            if (history == null && _problem == null)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (history != null && history.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(WeightHistorySheet.nothingYet),
              ),
            if (history != null && !history.isEmpty)
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: history.readings.reversed
                      .map((r) => _row(context, r))
                      .toList(),
                ),
              ),
            if (_said != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_said!,
                    style: Theme.of(context).textTheme.bodySmall),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: _busy ? null : bringIn,
                child: Text(_busy
                    ? WeightHistorySheet.bringingIn
                    : WeightHistorySheet.bringIn),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, WeightRecord r) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text('${r.kg} kg'),
      subtitle: r.typed ? null : const Text(WeightHistorySheet.fromHealth),
      trailing: Text(WeightHistorySheet.when(r.day),
          style: Theme.of(context).textTheme.bodySmall),
    );
  }
}
