import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/calendar_day_bloc.dart';
import 'package:opennutritracker/features/diary/presentation/bloc/diary_bloc.dart';
import 'package:opennutritracker/features/home/presentation/bloc/home_bloc.dart';
import 'package:opennutritracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:opennutritracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:opennutritracker/generated/l10n.dart';

class CalculationsDialog extends StatefulWidget {
  final SettingsBloc settingsBloc;
  final ProfileBloc profileBloc;
  final HomeBloc homeBloc;
  final DiaryBloc diaryBloc;
  final CalendarDayBloc calendarDayBloc;

  const CalculationsDialog({
    super.key,
    required this.settingsBloc,
    required this.profileBloc,
    required this.homeBloc,
    required this.diaryBloc,
    required this.calendarDayBloc,
  });

  @override
  State<CalculationsDialog> createState() => _CalculationsDialogState();
}

class _CalculationsDialogState extends State<CalculationsDialog> {
  static const double _maxKcalAdjustment = 1000;
  static const double _minKcalAdjustment = -1000;
  static const int _kcalDivisions = 200;
  double _kcalAdjustmentSelection = 0;

  static const double _defaultCarbsPctSelection = 0.6;
  static const double _defaultFatPctSelection = 0.25;
  static const double _defaultProteinPctSelection = 0.15;

  // Macros percentages
  double _carbsPctSelection = _defaultCarbsPctSelection * 100;
  double _proteinPctSelection = _defaultProteinPctSelection * 100;
  double _fatPctSelection = _defaultFatPctSelection * 100;

  // TDEE and goal for direct target
  double _tdee = 0;
  double _goalAdj = 0;

  // Macro mode
  bool _isGramsMode = false;
  final _proteinGramsController = TextEditingController();
  final _carbsGramsController = TextEditingController();
  final _fatGramsController = TextEditingController();

  // Direct target
  final _targetController = TextEditingController();
  bool _editingTarget = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeValues();
  }

  @override
  void dispose() {
    _proteinGramsController.dispose();
    _carbsGramsController.dispose();
    _fatGramsController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  void _initializeValues() async {
    final kcalAdjustment = await widget.settingsBloc.getKcalAdjustment() * 1.0;
    final userCarbsPct = await widget.settingsBloc.getUserCarbGoalPct();
    final userProteinPct = await widget.settingsBloc.getUserProteinGoalPct();
    final userFatPct = await widget.settingsBloc.getUserFatGoalPct();
    final tdee = await widget.settingsBloc.getTdee();
    final goalAdj = await widget.settingsBloc.getGoalAdjustment();
    final macroMode = await widget.settingsBloc.getMacroMode();
    final fixedProtein = await widget.settingsBloc.getFixedProteinGrams();
    final fixedCarbs = await widget.settingsBloc.getFixedCarbsGrams();
    final fixedFat = await widget.settingsBloc.getFixedFatGrams();

    setState(() {
      _kcalAdjustmentSelection = kcalAdjustment;
      _carbsPctSelection = (userCarbsPct ?? _defaultCarbsPctSelection) * 100;
      _proteinPctSelection =
          (userProteinPct ?? _defaultProteinPctSelection) * 100;
      _fatPctSelection = (userFatPct ?? _defaultFatPctSelection) * 100;
      _tdee = tdee;
      _goalAdj = goalAdj;
      _isGramsMode = macroMode == 'grams';
      _proteinGramsController.text =
          fixedProtein?.round().toString() ?? '';
      _carbsGramsController.text =
          fixedCarbs?.round().toString() ?? '';
      _fatGramsController.text =
          fixedFat?.round().toString() ?? '';
      _updateTargetField();
    });
  }

  double get _computedTarget => _tdee + _goalAdj + _kcalAdjustmentSelection;

  void _updateTargetField() {
    if (!_editingTarget) {
      _targetController.text = _computedTarget.round().toString();
    }
  }

  void _onTargetEdited(String value) {
    final entered = double.tryParse(value);
    if (entered == null) return;
    setState(() {
      _editingTarget = true;
      _kcalAdjustmentSelection =
          (entered - _tdee - _goalAdj).clamp(_minKcalAdjustment, _maxKcalAdjustment);
      _editingTarget = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              S.of(context).settingsCalculationsLabel,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            child: Text(S.of(context).buttonResetLabel),
            onPressed: () {
              setState(() {
                _kcalAdjustmentSelection = 0;
                _carbsPctSelection = _defaultCarbsPctSelection * 100;
                _proteinPctSelection = _defaultProteinPctSelection * 100;
                _fatPctSelection = _defaultFatPctSelection * 100;
                _isGramsMode = false;
                _proteinGramsController.clear();
                _carbsGramsController.clear();
                _fatGramsController.clear();
                _updateTargetField();
              });
            },
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField(
                isExpanded: true,
                decoration: InputDecoration(
                  enabled: false,
                  filled: false,
                  labelText: S.of(context).calculationsTDEELabel,
                ),
                items: [
                  DropdownMenuItem(
                      child: Text(
                    '${S.of(context).calculationsTDEEIOM2006Label} ${S.of(context).calculationsRecommendedLabel}',
                    overflow: TextOverflow.ellipsis,
                  )),
                ],
                onChanged: null),
            const SizedBox(height: 16),
            // Computed TDEE (read-only)
            Text(
              '${S.of(context).calculatedTdeeLabel}: ${Figures.kcal(context, _tdee) ?? ''}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            // Direct target field
            TextField(
              controller: _targetController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: S.of(context).dailyTargetLabel,
                suffixText: S.of(context).kcalLabel,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onTargetEdited,
            ),
            const SizedBox(height: 8),
            Container(
              alignment: Alignment.centerLeft,
              child: Text(
                '${S.of(context).dailyKcalAdjustmentLabel} ${Figures.bare(context, _kcalAdjustmentSelection, sign: true)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 280,
                child: Slider(
                  min: _minKcalAdjustment,
                  max: _maxKcalAdjustment,
                  divisions: _kcalDivisions,
                  value: _kcalAdjustmentSelection,
                  label:
                      Figures.kcal(context, _kcalAdjustmentSelection) ?? '',
                  onChanged: (value) {
                    setState(() {
                      _kcalAdjustmentSelection = value;
                      _updateTargetField();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Macro heading + mode toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  S.of(context).macroDistributionLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SegmentedButton<bool>(
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text(S.of(context).percentageModeLabel),
                ),
                ButtonSegment(
                  value: true,
                  label: Text(S.of(context).gramsModeLabel),
                ),
              ],
              selected: {_isGramsMode},
              onSelectionChanged: (selected) {
                setState(() => _isGramsMode = selected.first);
              },
            ),
            const SizedBox(height: 8),
            if (_isGramsMode) ..._buildGramsFields() else ..._buildPctSliders(),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(S.of(context).dialogCancelLabel)),
        TextButton(
            onPressed: () {
              _saveCalculationSettings();
            },
            child: Text(S.of(context).dialogOKLabel))
      ],
    );
  }

  List<Widget> _buildGramsFields() {
    return [
      _buildGramField(S.of(context).proteinLabel, _proteinGramsController),
      const SizedBox(height: 8),
      _buildGramField(S.of(context).carbsLabel, _carbsGramsController),
      const SizedBox(height: 8),
      _buildGramField(S.of(context).fatLabel, _fatGramsController),
    ];
  }

  Widget _buildGramField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        suffixText: 'g',
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  List<Widget> _buildPctSliders() {
    return [
      _buildMacroSlider(
        S.of(context).carbsLabel,
        _carbsPctSelection,
        Colors.orange,
        (value) {
          setState(() {
            double delta = value - _carbsPctSelection;
            _carbsPctSelection = value;

            double proteinRatio = _proteinPctSelection /
                (_proteinPctSelection + _fatPctSelection);
            double fatRatio = _fatPctSelection /
                (_proteinPctSelection + _fatPctSelection);

            _proteinPctSelection -= delta * proteinRatio;
            _fatPctSelection -= delta * fatRatio;

            if (_proteinPctSelection < 5) {
              double overflow = 5 - _proteinPctSelection;
              _proteinPctSelection = 5;
              _fatPctSelection -= overflow;
            }
            if (_fatPctSelection < 5) {
              double overflow = 5 - _fatPctSelection;
              _fatPctSelection = 5;
              _proteinPctSelection -= overflow;
            }
          });
        },
      ),
      _buildMacroSlider(
        S.of(context).proteinLabel,
        _proteinPctSelection,
        Colors.blue,
        (value) {
          setState(() {
            double delta = value - _proteinPctSelection;
            _proteinPctSelection = value;

            double carbsRatio = _carbsPctSelection /
                (_carbsPctSelection + _fatPctSelection);
            double fatRatio =
                _fatPctSelection / (_carbsPctSelection + _fatPctSelection);

            _carbsPctSelection -= delta * carbsRatio;
            _fatPctSelection -= delta * fatRatio;

            if (_carbsPctSelection < 5) {
              double overflow = 5 - _carbsPctSelection;
              _carbsPctSelection = 5;
              _fatPctSelection -= overflow;
            }
            if (_fatPctSelection < 5) {
              double overflow = 5 - _fatPctSelection;
              _fatPctSelection = 5;
              _carbsPctSelection -= overflow;
            }
          });
        },
      ),
      _buildMacroSlider(
        S.of(context).fatLabel,
        _fatPctSelection,
        Colors.green,
        (value) {
          setState(() {
            double delta = value - _fatPctSelection;
            _fatPctSelection = value;

            double carbsRatio = _carbsPctSelection /
                (_carbsPctSelection + _proteinPctSelection);
            double proteinRatio = _proteinPctSelection /
                (_carbsPctSelection + _proteinPctSelection);

            _carbsPctSelection -= delta * carbsRatio;
            _proteinPctSelection -= delta * proteinRatio;

            if (_carbsPctSelection < 5) {
              double overflow = 5 - _carbsPctSelection;
              _carbsPctSelection = 5;
              _proteinPctSelection -= overflow;
            }
            if (_proteinPctSelection < 5) {
              double overflow = 5 - _proteinPctSelection;
              _proteinPctSelection = 5;
              _carbsPctSelection -= overflow;
            }
          });
        },
      ),
    ];
  }

  Widget _buildMacroSlider(
    String label,
    double value,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${value.round()}%'),
          ],
        ),
        SizedBox(
          width: 280,
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              thumbColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              min: 5,
              max: 90,
              value: value,
              divisions: 85,
              onChanged: (value) {
                final newValue = value.round().toDouble();
                if (100 - newValue >= 10) {
                  onChanged(newValue);
                  _normalizeMacros();
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  void _normalizeMacros() {
    setState(() {
      _carbsPctSelection = _carbsPctSelection.roundToDouble();
      _proteinPctSelection = _proteinPctSelection.roundToDouble();
      _fatPctSelection = _fatPctSelection.roundToDouble();

      double total =
          _carbsPctSelection + _proteinPctSelection + _fatPctSelection;

      if (total != 100) {
        double factor = 100 / total;

        _carbsPctSelection = (_carbsPctSelection * factor).roundToDouble();
        _proteinPctSelection = (_proteinPctSelection * factor).roundToDouble();

        _fatPctSelection = 100 - _carbsPctSelection - _proteinPctSelection;

        if (_fatPctSelection < 5) {
          _fatPctSelection = 5;
          double remaining = 95;
          double ratio =
              _carbsPctSelection / (_carbsPctSelection + _proteinPctSelection);
          _carbsPctSelection = (remaining * ratio).roundToDouble();
          _proteinPctSelection = remaining - _carbsPctSelection;
        }
      }

      assert(
          _carbsPctSelection + _proteinPctSelection + _fatPctSelection == 100,
          'Macros must total 100%');
    });
  }

  void _saveCalculationSettings() {
    // Save the calorie offset
    widget.settingsBloc
        .setKcalAdjustment(_kcalAdjustmentSelection.toInt().toDouble());

    // Save macro mode
    widget.settingsBloc.setMacroMode(_isGramsMode ? 'grams' : 'percentage');

    if (_isGramsMode) {
      final protein =
          double.tryParse(_proteinGramsController.text) ?? 0;
      final carbs =
          double.tryParse(_carbsGramsController.text) ?? 0;
      final fat = double.tryParse(_fatGramsController.text) ?? 0;
      widget.settingsBloc.setFixedMacroGrams(protein, carbs, fat);
    } else {
      widget.settingsBloc.setMacroGoals(
          _carbsPctSelection, _proteinPctSelection, _fatPctSelection);
    }

    widget.settingsBloc.add(LoadSettingsEvent());
    widget.profileBloc.add(LoadProfileEvent());
    widget.homeBloc.add(LoadItemsEvent());

    widget.settingsBloc.updateTrackedDay(DateTime.now());
    widget.diaryBloc.add(LoadDiaryYearEvent());
    widget.calendarDayBloc.add(RefreshCalendarDayEvent());

    Navigator.of(context).pop();
  }
}
