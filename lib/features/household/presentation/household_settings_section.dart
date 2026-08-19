import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';

/// The household part of Settings: whose phone this is, this person's own
/// calorie target, and the two switches that change what they see.
///
/// Everything here is keyed on the person who holds the phone. There is no
/// setting on this screen that belongs to the household rather than to one of
/// its two people — which is what stops one person's change moving the other's.
class HouseholdSettingsSection extends StatefulWidget {
  final HouseholdRepository repository;

  /// Told when the owner or the settings change, so the app above can rebuild
  /// with the new person's figures.
  final VoidCallback? onChanged;

  const HouseholdSettingsSection({
    super.key,
    required this.repository,
    this.onChanged,
  });

  @override
  State<HouseholdSettingsSection> createState() =>
      _HouseholdSettingsSectionState();
}

class _HouseholdSettingsSectionState extends State<HouseholdSettingsSection> {
  List<HouseholdPerson> _people = const [];
  int? _ownerId;
  PersonSettings? _settings;
  String? _problem;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final owner = await widget.repository.storedOwner();
    if (!mounted) return;
    setState(() => _ownerId = owner);
    try {
      final people = await widget.repository.people();
      if (!mounted) return;
      setState(() => _people = people);
    } on HouseholdUnreachable {
      // The names are a nicety; the settings below still work from the cache.
    }
    if (owner != null) {
      final settings = await widget.repository.settings(owner);
      if (!mounted) return;
      setState(() => _settings = settings);
    }
  }

  String _nameOf(int? personId) {
    if (personId == null) return 'nobody yet';
    for (final person in _people) {
      if (person.id == personId) return person.name;
    }
    return 'person $personId';
  }

  Future<void> _changeOwner(HouseholdPerson person) async {
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      await widget.repository.setOwner(person.id);
      final settings = await widget.repository.settings(person.id);
      if (!mounted) return;
      setState(() {
        _ownerId = person.id;
        _settings = settings;
      });
      widget.onChanged?.call();
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem = '${e.headline}, so this phone still belongs '
          'to ${_nameOf(_ownerId)}. (${e.message})');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _update({
    int? dailyTargetKcal,
    bool? weightTrackingOn,
    bool? figuresOff,
  }) async {
    final owner = _ownerId;
    if (owner == null) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final updated = await widget.repository.updateSettings(
        owner,
        dailyTargetKcal: dailyTargetKcal,
        weightTrackingOn: weightTrackingOn,
        figuresOff: figuresOff,
      );
      if (!mounted) return;
      setState(() => _settings = updated);
      widget.onChanged?.call();
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem =
          "${e.headline}, so that hasn't been saved. "
          '(${e.message})');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _askForOwner() async {
    final chosen = await showDialog<HouseholdPerson>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Whose phone is this?'),
        children: [
          for (final person in _people)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(person),
              child: Text(person.name),
            ),
        ],
      ),
    );
    if (chosen != null) await _changeOwner(chosen);
  }

  Future<void> _askForTarget() async {
    final controller = TextEditingController(
        text: _settings?.dailyTargetKcal?.toString() ?? '');
    final entered = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Daily calorie target for ${_nameOf(_ownerId)}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'kcal'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (entered != null) await _update(dailyTargetKcal: entered);
  }

  @override
  Widget build(BuildContext context) {
    final settings = _settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          title: const Text('This phone belongs to'),
          subtitle: Text(_nameOf(_ownerId)),
          trailing: const Icon(Icons.chevron_right),
          onTap: _busy || _people.isEmpty ? null : _askForOwner,
        ),
        // Hidden while figures are off — a target is a calorie figure like any
        // other. It is not forgotten: the value stays on the server and comes
        // back with the row when figures are switched on again.
        if (!Figures.off(context))
          ListTile(
            title: const Text('Daily calorie target'),
            subtitle: Text(settings?.dailyTargetKcal == null
                ? 'Not set'
                : Figures.kcal(context, settings!.dailyTargetKcal) ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: _busy || _ownerId == null ? null : _askForTarget,
          ),
        SwitchListTile(
          title: const Text('Track weight'),
          subtitle: const Text(
              'Turning this off hides the weight tab. Nothing already recorded '
              'is deleted.'),
          value: settings?.weightTrackingOn ?? false,
          onChanged: _busy || settings == null
              ? null
              : (on) => _update(weightTrackingOn: on),
        ),
        SwitchListTile(
          title: const Text('Show calorie figures'),
          subtitle: const Text(
              'Turn this off to use the plan and one-tap logging without any '
              'numbers. Your day is still counted underneath.'),
          value: !(settings?.figuresOff ?? false),
          onChanged: _busy || settings == null
              ? null
              : (shown) => _update(figuresOff: !shown),
        ),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(_problem!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
      ],
    );
  }
}
