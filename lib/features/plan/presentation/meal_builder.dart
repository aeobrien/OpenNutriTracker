/// Building a meal out of its parts.
///
/// Release 6, TM-0020 / BC-0021. This household cooks by assembling rather
/// than by following a recipe: something to cook, a way of cooking it, some
/// vegetables, something starchy. The kitchen panel has been able to record
/// that for months and has been learning the combinations as it went. A phone
/// could not, which is unfortunate, because the phone is what somebody has in
/// their hand when they decide what Tuesday is.
///
/// Four lists, each drawn from what this house has actually cooked. That is
/// the only thing that makes four choices faster than typing a name — the
/// lists are short. None of the shortening happens here: the Mac Mini reads
/// its own pairing graph and answers with the vegetables that have gone with
/// this thing cooked this way, first, and the ones that have gone with it
/// however it was cooked, after. A slot with nothing in it yet says so and
/// offers the box to type one, which is a different thing from an empty list.
///
/// **There is no calorie figure here, deliberately.** A meal named from its
/// parts is a meal nobody has yet said which of the house's foods stands for
/// "tenderstem broccoli" or how much of it goes in, and a figure worked out
/// from nothing is a zero somebody will believe. So building one lands on the
/// meal's own screen, where each part is named as missing, with the reason,
/// and can be filled in. The figure arrives when the parts do.
library;

import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/plan/data/plan_repository.dart';
import 'package:opennutritracker/features/plan/domain/meal_options.dart';
import 'package:opennutritracker/features/plan/domain/plan_week.dart';

class MealBuilder extends StatefulWidget {
  final PlanRepository repository;

  const MealBuilder({super.key, required this.repository});

  static const proteinHeading = 'What are you cooking?';
  static const prepHeading = 'How?';
  static const vegHeading = 'With what?';
  static const carbHeading = 'And?';
  static const nothingYet = 'Nothing here yet — type one.';
  static const typeOne = 'Something else';
  static const buildIt = 'Build it';
  static const skipIt = 'Not this time';
  static const twoIsTheLimit =
      'Two vegetables is what a meal here holds. Tap one to swap it out.';

  /// Open the builder. Comes back with the meal it built, or nothing at all if
  /// it was backed out of — an abandoned builder creates nothing.
  static Future<MealChoice?> show(
    BuildContext context, {
    required PlanRepository repository,
  }) =>
      showModalBottomSheet<MealChoice>(
        context: context,
        isScrollControlled: true,
        builder: (_) => MealBuilder(repository: repository),
      );

  @override
  State<MealBuilder> createState() => _MealBuilderState();
}

class _MealBuilderState extends State<MealBuilder> {
  MealOptions _options = const MealOptions();
  String? _protein;
  String? _prep;
  final _veg = <String>[];
  String? _carb;
  String? _problem;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  /// Re-ask what can be offered. Every choice of what is being cooked, or how,
  /// narrows the two lists below it, so the lists are re-read rather than
  /// filtered here — the house's habits are the Mini's to know.
  Future<void> _reload() async {
    try {
      final options =
          await widget.repository.partOptions(protein: _protein, prep: _prep);
      if (!mounted) return;
      setState(() {
        _options = options;
        _problem = null;
      });
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() => _problem = '${e.headline}, so there is nothing to choose '
          'from. You can still type each part.');
    }
  }

  void _chooseProtein(String one) {
    setState(() {
      // A different thing to cook makes the choices under it somebody else's
      // habits, so they go rather than sit there looking chosen.
      _protein = one;
      _prep = null;
      _veg.clear();
      _carb = null;
    });
    _reload();
  }

  void _choosePrep(String one) {
    setState(() => _prep = _prep == one ? null : one);
    _reload();
  }

  void _chooseVeg(String one) {
    setState(() {
      if (_veg.remove(one)) return;
      if (_veg.length >= 2) {
        _problem = MealBuilder.twoIsTheLimit;
        return;
      }
      _problem = null;
      _veg.add(one);
    });
  }

  Future<void> _build() async {
    final protein = _protein;
    if (protein == null || _busy) return;
    setState(() {
      _busy = true;
      _problem = null;
    });
    try {
      final meal = await widget.repository.buildMeal(
          protein: protein, prep: _prep, veg: _veg, carb: _carb);
      if (!mounted) return;
      Navigator.of(context).pop(meal);
    } on HouseholdUnreachable catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = '${e.headline}, so that meal was not made. Nothing was '
            'saved and nothing was lost — try again when it is back.';
      });
    } on HouseholdRefused catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _problem = 'The Mac Mini would not take that: ${e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_problem != null) ...[
              Text(_problem!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error)),
              const SizedBox(height: 8),
            ],
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _Slot(
                    heading: MealBuilder.proteinHeading,
                    options: _options.proteins,
                    chosen: _protein == null ? const [] : [_protein!],
                    onChosen: _chooseProtein,
                  ),
                  // Everything below the first choice only makes sense once
                  // there is something to cook: what goes with roast chicken
                  // is not a question until the chicken is chosen.
                  if (_protein != null) ...[
                    _Slot(
                      heading: MealBuilder.prepHeading,
                      options: _options.preps,
                      chosen: _prep == null ? const [] : [_prep!],
                      onChosen: _choosePrep,
                    ),
                    _Slot(
                      heading: MealBuilder.vegHeading,
                      options: _options.veg.inOrder,
                      chosen: _veg,
                      onChosen: _chooseVeg,
                    ),
                    _Slot(
                      heading: MealBuilder.carbHeading,
                      options: _options.carb.inOrder,
                      chosen: _carb == null ? const [] : [_carb!],
                      onChosen: (one) =>
                          setState(() => _carb = _carb == one ? null : one),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _busy ? null : () => Navigator.of(context).pop(),
                  child: const Text(MealBuilder.skipIt),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _protein == null || _busy ? null : _build,
                  child: const Text(MealBuilder.buildIt),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One of the four choices: a heading, what the house offers, and a box for
/// something it has never had before.
///
/// The typing box is not a fallback for when the list is short — it is how a
/// new thing gets into the house's habits at all. Every option in every list
/// here was typed into this box once.
class _Slot extends StatefulWidget {
  final String heading;
  final List<String> options;
  final List<String> chosen;
  final void Function(String) onChosen;

  const _Slot({
    required this.heading,
    required this.options,
    required this.chosen,
    required this.onChosen,
  });

  @override
  State<_Slot> createState() => _SlotState();
}

class _SlotState extends State<_Slot> {
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  void _take() {
    final one = _typed.text.trim();
    if (one.isEmpty) return;
    _typed.clear();
    widget.onChosen(one);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Something typed in is on the screen as a choice from then on, whether or
    // not the house has had it before — otherwise it would be chosen and
    // invisible at the same time.
    final offered = [
      ...widget.options,
      for (final one in widget.chosen)
        if (!widget.options.contains(one)) one,
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.heading, style: theme.textTheme.titleSmall),
          const SizedBox(height: 4),
          if (offered.isEmpty)
            Text(MealBuilder.nothingYet,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline))
          else
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final one in offered)
                  FilterChip(
                    label: Text(one),
                    selected: widget.chosen.contains(one),
                    onSelected: (_) => widget.onChosen(one),
                  ),
              ],
            ),
          const SizedBox(height: 4),
          TextField(
            controller: _typed,
            decoration: InputDecoration(
              labelText: MealBuilder.typeOne,
              isDense: true,
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                tooltip: MealBuilder.typeOne,
                onPressed: _take,
              ),
            ),
            onSubmitted: (_) => _take(),
          ),
        ],
      ),
    );
  }
}
