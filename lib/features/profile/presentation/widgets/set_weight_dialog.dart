import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horizontal_picker/horizontal_picker.dart';
import 'package:opennutritracker/generated/l10n.dart';

/// Setting your weight.
///
/// **You can type the number.** That sounds too small to write down and it is
/// the whole point of this file. Before 20 August 2026 this dialog was a
/// hundred-kilogram ruler and nothing else: to record 114.8 kg you had to drag
/// a scale spanning 65 to 165 kg onto one division in a thousand, with your
/// thumb over the number you were aiming at. Aidan set his weight to 114.8,
/// pressed OK, and the household recorded 115.0 — the ruler had never left the
/// centre. From where he stood the app had simply refused to save, and he was
/// right to call it that: a control that silently records something other than
/// what you told it is worse than one that refuses.
///
/// So the field is the primary way in and the ruler stays underneath for a
/// nudge. Whichever you touch last is the answer, and the field always shows
/// what will actually be saved — including after a drag — so there is never a
/// number on screen that is not the number being stored.
class SetWeightDialog extends StatefulWidget {
  static const weightRangeKg = 50.0;
  static const weightRangeLbs = 100.0;

  final double userWeight;
  final bool usesImperialUnits;

  const SetWeightDialog({
    super.key,
    required this.userWeight,
    required this.usesImperialUnits,
  });

  @override
  State<SetWeightDialog> createState() => _SetWeightDialogState();
}

class _SetWeightDialogState extends State<SetWeightDialog> {
  late final TextEditingController _typed;
  late double _selected;

  /// Set when what is in the box is not a number this dialog can save. OK is
  /// disabled while it is set rather than the dialog quietly saving the old
  /// value — which is the failure this whole file exists to stop.
  String? _problem;

  @override
  void initState() {
    super.initState();
    _selected = widget.userWeight;
    _typed = TextEditingController(text: _show(widget.userWeight));
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  /// One decimal, always. A weight is read off a scale to a tenth and a person
  /// who types 114.8 must see 114.8 back.
  static String _show(double kg) => kg.toStringAsFixed(1);

  String get _unit =>
      widget.usesImperialUnits ? S.of(context).lbsLabel : S.of(context).kgLabel;

  void _typedChanged(String text) {
    final value = double.tryParse(text.trim().replaceAll(',', '.'));
    setState(() {
      if (value == null || value <= 0) {
        _problem = text.trim().isEmpty
            ? 'Type your weight in $_unit.'
            : "That isn't a weight.";
      } else {
        _problem = null;
        _selected = value;
      }
    });
  }

  void _draggedTo(double value) {
    // Keep the box in step with the ruler, without fighting the person if they
    // are mid-type: the ruler only moves when they drag it.
    setState(() {
      _selected = value;
      _problem = null;
      _typed.value = TextEditingValue(text: _show(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(S.of(context).selectWeightDialogLabel),
      content: Wrap(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Named so a harness can type into it. The reason this dialog was
              // rewritten at all is that nothing had ever driven it: the ruler
              // could be dragged in a test only by pixel, which nobody wrote, so
              // "OK saves the number on screen" had never been checked by
              // anything but a person, once, on the day it went wrong.
              Semantics(
                identifier: 'weight-typed',
                child: TextField(
                  controller: _typed,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                  decoration: InputDecoration(
                    suffixText: _unit,
                    errorText: _problem,
                  ),
                  onChanged: _typedChanged,
                ),
              ),
              const SizedBox(height: 8),
              HorizontalPicker(
                height: 100,
                backgroundColor: Colors.transparent,
                minValue: widget.usesImperialUnits
                    ? widget.userWeight - SetWeightDialog.weightRangeLbs
                    : widget.userWeight - SetWeightDialog.weightRangeKg,
                maxValue: widget.usesImperialUnits
                    ? widget.userWeight + SetWeightDialog.weightRangeLbs
                    : widget.userWeight + SetWeightDialog.weightRangeKg,
                initialPosition: InitialPosition.center,
                divisions: 1000,
                suffix: _unit,
                onChanged: _draggedTo,
              ),
            ],
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(S.of(context).dialogCancelLabel),
        ),
        TextButton(
          onPressed: _problem != null
              ? null
              : () => Navigator.pop(context, _selected),
          child: Text(S.of(context).dialogOKLabel),
        ),
      ],
    );
  }
}
