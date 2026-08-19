import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/food_finder.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/label_scan/domain/food_draft.dart';
import 'package:opennutritracker/features/label_scan/presentation/confirm_food_screen.dart';

/// The last thing to try when neither food list has it.
///
/// It sits underneath the results rather than beside the search box, and it is
/// a button rather than something that runs on its own. Both of those are the
/// same decision: this is the least trustworthy of the three ways to find a
/// food, so it happens only when a person has looked at what the other two
/// offered and said no. A hunt that fired automatically would put a model's
/// reading of a stranger's page above a packet this house has already read.
///
/// Nothing here writes anything. Picking a result opens the same confirmation
/// screen a photographed label goes through, and that screen is the only place
/// a food gets saved.
class LookItUpWidget extends StatefulWidget {
  /// The words on the button. Named so a test asserts on what the screen says
  /// rather than on a copy of it.
  static const buttonLabel = 'Look it up online';

  /// What the shortlist is called, which is also the warning. The list has to
  /// say what it is at the moment somebody reads it, not two screens later.
  static const shortlistLabel = 'Found online — nobody here has checked these';

  /// What a hunt that found nothing says. Deliberately not an error: not
  /// finding something is an ordinary outcome, and the way out is the same one
  /// that was always there.
  static const nothingFound =
      "Couldn't find that online. You can photograph the packet or type the "
      'numbers in yourself.';

  final FoodFinder finder;
  final HouseholdLogger logger;

  /// What was typed in the search box. The hunt is only offered once there is
  /// something to hunt for.
  final String searchText;

  const LookItUpWidget({
    super.key,
    required this.finder,
    required this.logger,
    required this.searchText,
  });

  @override
  State<LookItUpWidget> createState() => _LookItUpWidgetState();
}

class _LookItUpWidgetState extends State<LookItUpWidget> {
  bool _hunting = false;
  List<FoodDraft>? _found;

  @override
  void didUpdateWidget(LookItUpWidget old) {
    super.didUpdateWidget(old);
    // A new search is a new question. Leaving the last hunt's results under a
    // different search would be showing somebody answers to something they are
    // no longer asking.
    if (old.searchText != widget.searchText && _found != null) {
      setState(() => _found = null);
    }
  }

  Future<void> _hunt() async {
    setState(() => _hunting = true);
    final found = await widget.finder.huntFor(widget.searchText);
    if (!mounted) return;
    setState(() {
      _hunting = false;
      _found = found;
    });
  }

  Future<void> _confirm(FoodDraft draft) async {
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (formContext) => Scaffold(
          appBar: AppBar(title: const Text('Check the numbers')),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: ConfirmFoodScreen(
                logger: widget.logger,
                draft: draft,
                onSaved: (clientId) => Navigator.of(formContext).pop(clientId),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// What a shortlist row says about itself, under its name: the shop, the pack
  /// size and the calories, in that order, and only the parts the page gave up.
  ///
  /// The calorie figure goes through [Figures] like every other one in the app,
  /// so this row disappears from the person who asked not to see calories
  /// rather than being the one place they come back.
  static String describe(BuildContext context, FoodDraft draft) {
    // Named for what it is rather than for its unit: the unit is Figures'
    // to say, and this row must not spell it out itself.
    final energy = Figures.kcal(context, draft.kcal100);
    final parts = <String>[
      if (draft.brand != null) draft.brand!,
      if (draft.packGrams != null) '${_tidy(draft.packGrams!)}g pack',
      if (energy != null) '$energy per 100g',
    ];
    return parts.isEmpty ? 'No details given' : parts.join(' · ');
  }

  static String _tidy(num value) =>
      value == value.roundToDouble() ? value.round().toString() : '$value';

  @override
  Widget build(BuildContext context) {
    if (widget.searchText.trim().isEmpty) return const SizedBox();
    final found = _found;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: OutlinedButton.icon(
            onPressed: _hunting ? null : _hunt,
            icon: _hunting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.travel_explore),
            label: const Text(LookItUpWidget.buttonLabel),
          ),
        ),
        if (found != null && found.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(LookItUpWidget.nothingFound),
          ),
        if (found != null && found.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(left: 8, top: 8, bottom: 4),
            child: Text(LookItUpWidget.shortlistLabel),
          ),
          for (final draft in found)
            ListTile(
              title: Text(draft.name),
              subtitle: Text(describe(context, draft)),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _confirm(draft),
            ),
        ],
      ],
    );
  }
}
