import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_repository.dart';
import 'package:opennutritracker/features/household/domain/household_person.dart';

/// "Whose phone is this?" — asked once, on first run.
///
/// There are two people and no accounts, so this is the whole of setting the
/// phone up. The answer is sent to the Mac Mini *before* it is stored here: a
/// phone that thinks it belongs to Emily while the server still thinks Aidan is
/// the state that puts one person's dinner on the other's day, and it is easier
/// to refuse to start than to unpick afterwards.
///
/// Reached through [HouseholdGate], which shows this page exactly when nothing
/// has been stored yet — so a fresh install asks and a returning one does not.
class WhosePhonePage extends StatefulWidget {
  final HouseholdRepository repository;

  /// Called once an owner has been chosen and the server has accepted it.
  final VoidCallback? onChosen;

  const WhosePhonePage({
    super.key,
    required this.repository,
    this.onChosen,
  });

  @override
  State<WhosePhonePage> createState() => _WhosePhonePageState();
}

class _WhosePhonePageState extends State<WhosePhonePage> {
  List<HouseholdPerson>? _people;
  String? _problem;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _problem = null;
      _people = null;
    });
    try {
      final people = await widget.repository.people();
      if (!mounted) return;
      setState(() => _people = people);
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem =
          "Can't reach the kitchen computer, so I don't know who's in the "
          'house yet. (${e.message})');
    }
  }

  Future<void> _choose(HouseholdPerson person) async {
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      await widget.repository.setOwner(person.id);
      if (!mounted) return;
      widget.onChosen?.call();
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem =
          "Couldn't tell the kitchen computer, so nothing has been saved yet. "
          'Try again in a moment. (${e.message})');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Whose phone is this?',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Everything you log will count against this person. You can '
                'change it later.',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (_problem != null) ...[
                Text(_problem!,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _saving ? null : _load,
                  child: const Text('Try again'),
                ),
              ] else if (_people == null)
                const Center(child: CircularProgressIndicator())
              else
                for (final person in _people!) ...[
                  FilledButton(
                    onPressed: _saving ? null : () => _choose(person),
                    child: Text(person.name),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Stands in front of the app and asks who this phone belongs to when nobody
/// has said yet. Once there is an answer it gets out of the way for good.
class HouseholdGate extends StatefulWidget {
  final HouseholdRepository repository;
  final Widget child;

  /// Told once somebody has said whose phone this is, so the app above can pick
  /// up that person's own settings.
  final VoidCallback? onAnswered;

  const HouseholdGate({
    super.key,
    required this.repository,
    required this.child,
    this.onAnswered,
  });

  @override
  State<HouseholdGate> createState() => _HouseholdGateState();
}

class _HouseholdGateState extends State<HouseholdGate> {
  bool? _needsPrompt;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final needs = await widget.repository.needsOwnerPrompt();
    if (!mounted) return;
    setState(() => _needsPrompt = needs);
  }

  @override
  Widget build(BuildContext context) {
    if (_needsPrompt == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_needsPrompt!) {
      return WhosePhonePage(
        repository: widget.repository,
        onChosen: () {
          setState(() => _needsPrompt = false);
          widget.onAnswered?.call();
        },
      );
    }
    return widget.child;
  }
}
