import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:opennutritracker/features/household/data/exercise_sync.dart';

/// Typing in exercise the watch did not have.
///
/// A real route rather than a fallback that writes the same thing: a figure a
/// person typed and a figure a watch measured are different claims, and the day
/// has to be able to say which it was. What is saved here is marked as typed,
/// and it lands on the day of the person this phone belongs to.
class TypeExerciseScreen extends StatefulWidget {
  final ExerciseSync sync;

  /// The day it belongs to, as 'YYYY-MM-DD'.
  final String day;

  const TypeExerciseScreen({super.key, required this.sync, required this.day});

  @override
  State<TypeExerciseScreen> createState() => _TypeExerciseScreenState();
}

class _TypeExerciseScreenState extends State<TypeExerciseScreen> {
  final _kcal = TextEditingController();
  final _minutes = TextEditingController();
  final _note = TextEditingController();
  bool _saving = false;
  String? _problem;

  @override
  void dispose() {
    _kcal.dispose();
    _minutes.dispose();
    _note.dispose();
    super.dispose();
  }

  num? get _kcalValue => num.tryParse(_kcal.text.trim());

  Future<void> _save() async {
    final kcal = _kcalValue;
    if (kcal == null || kcal <= 0) {
      setState(() => _problem = 'How many calories? A number above zero.');
      return;
    }
    setState(() {
      _saving = true;
      _problem = null;
    });
    try {
      final id = await widget.sync.typeIn(
        day: widget.day,
        kcal: kcal,
        minutes: num.tryParse(_minutes.text.trim()),
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _problem = "That couldn't be saved: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add exercise')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('For when the watch did not catch it.'),
          const SizedBox(height: 16),
          TextField(
            controller: _kcal,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
                labelText: 'Calories burned', suffixText: 'kcal'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _minutes,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
                labelText: 'How long (optional)', suffixText: 'minutes'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration:
                const InputDecoration(labelText: 'What was it? (optional)'),
          ),
          const SizedBox(height: 20),
          if (_problem != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_problem!,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
