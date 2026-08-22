/// The shopping list.
///
/// Release 6, TM-0022 / BC-0023. One line per thing, at the total the week
/// needs, with the meals that put it there underneath. Ticked lines stay on
/// the screen with a line through them rather than vanishing, because a list
/// that empties as you shop gives you nothing to check at the till.
///
/// This screen is built for a shop. Reading and ticking work with no signal at
/// all; the only thing that needs the house is making the list in the first
/// place, and the button that does it says so rather than pretending.
library;

import 'package:flutter/material.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/shopping/data/shopping_repository.dart';
import 'package:opennutritracker/features/shopping/domain/shopping_line.dart';

class ShoppingScreen extends StatefulWidget {
  final ShoppingRepository repository;

  const ShoppingScreen({super.key, required this.repository});

  static const heading = 'Shopping list';
  static const nothingOnIt = 'Nothing on the list.';
  static const makeIt = 'Make the shopping list';
  static const madeNothing = "Nothing on the plan needs buying.";
  static const cannotMakeIt =
      "Making the list reads the whole plan, so it needs the Mac Mini. The "
      "list below is the one this phone last saw, and you can still tick it.";
  static const whyThis = 'Why this?';

  /// What compiling did, in words. Plurals handled here rather than at three
  /// call sites.
  static String madeLine(ListMade made) {
    if (made.meals == 0) return madeNothing;
    final meals = made.meals == 1 ? '1 meal' : '${made.meals} meals';
    final lines = made.added == 1 ? '1 thing' : '${made.added} things';
    return 'Made from $meals — $lines to buy.';
  }

  /// The meals behind one line, as one sentence.
  static String whoWantsIt(ShoppingLine line) {
    if (!line.isFromThePlan) return '';
    final names = <String>[];
    for (final one in line.putItThere) {
      if (!names.contains(one.title)) names.add(one.title);
    }
    final times = line.putItThere.length;
    final said = names.length == 1
        ? names.single
        : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
    // Two helpings of the same dinner is why the number is what it is, so the
    // count is said even when there is only one name.
    return times > names.length ? '$said, $times times' : said;
  }

  static Future<void> show(BuildContext context,
          {required ShoppingRepository repository}) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => ShoppingScreen(repository: repository),
      ));

  @override
  State<ShoppingScreen> createState() => _ShoppingScreenState();
}

class _ShoppingScreenState extends State<ShoppingScreen> {
  List<ShoppingLine>? _lines;
  String? _problem;
  String? _said;
  bool _busy = false;
  final _open = <int>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final lines = await widget.repository.list();
    if (!mounted) return;
    setState(() => _lines = lines);
  }

  Future<void> _tick(ShoppingLine line, bool done) async {
    final now = await widget.repository.tick(line.id, done);
    if (!mounted) return;
    setState(() => _lines = now);
  }

  Future<void> _remove(ShoppingLine line) async {
    final now = await widget.repository.remove(line.id);
    if (!mounted) return;
    setState(() => _lines = now);
  }

  Future<void> _make() async {
    setState(() {
      _busy = true;
      _problem = null;
      _said = null;
    });
    try {
      final made = await widget.repository.make();
      if (!mounted) return;
      setState(() {
        _lines = made.list;
        _said = ShoppingScreen.madeLine(made);
      });
    } on HouseholdUnreachable {
      if (!mounted) return;
      setState(() => _problem = ShoppingScreen.cannotMakeIt);
    } on HouseholdRefused catch (e) {
      if (!mounted) return;
      setState(() => _problem = 'The Mac Mini would not take that: '
          '${e.message}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = _lines;
    return Scaffold(
      appBar: AppBar(title: const Text(ShoppingScreen.heading)),
      body: ListView(
        children: [
          if (_problem != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(_problem!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error)),
            ),
          if (_said != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(_said!, style: theme.textTheme.bodySmall),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.tonal(
                onPressed: _busy ? null : _make,
                child: const Text(ShoppingScreen.makeIt),
              ),
            ),
          ),
          if (lines != null && lines.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(ShoppingScreen.nothingOnIt,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ),
          for (final line in lines ?? const <ShoppingLine>[])
            _Line(
              line: line,
              open: _open.contains(line.id),
              onTicked: (done) => _tick(line, done),
              onRemoved: () => _remove(line),
              onWhy: !line.isFromThePlan
                  ? null
                  : () => setState(() => _open.contains(line.id)
                      ? _open.remove(line.id)
                      : _open.add(line.id)),
            ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final ShoppingLine line;
  final bool open;
  final void Function(bool) onTicked;
  final VoidCallback onRemoved;
  final VoidCallback? onWhy;

  const _Line({
    required this.line,
    required this.open,
    required this.onTicked,
    required this.onRemoved,
    this.onWhy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          value: line.done,
          onChanged: (now) => onTicked(now ?? false),
          controlAffinity: ListTileControlAffinity.leading,
          title: Text(
            line.text,
            // Ticked stays on the screen, struck through. A list that empties
            // as you shop leaves nothing to check at the till.
            style: !line.done
                ? null
                : theme.textTheme.bodyLarge?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.outline),
          ),
          secondary: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onWhy != null)
                IconButton(
                  icon: const Icon(Icons.help_outline),
                  tooltip: ShoppingScreen.whyThis,
                  onPressed: onWhy,
                ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Take it off',
                onPressed: onRemoved,
              ),
            ],
          ),
        ),
        if (open)
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
            child: Text(ShoppingScreen.whoWantsIt(line),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
      ],
    );
  }
}
