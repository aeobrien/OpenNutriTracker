import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/presentation/figures.dart';
import 'package:opennutritracker/features/said/data/microphone.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';
import 'package:opennutritracker/features/today/data/day_repository.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

/// Saying what you ate, on the screen you are already looking at.
///
/// Two halves, and the second one is the reason the first is safe to use.
///
/// The top half is how you say it: hold the button and talk, or type it. Both
/// end up as one sentence going to the same place, so there is no second, worse
/// way of doing this for the times you cannot talk out loud.
///
/// The bottom half is everything that is still being worked out. A row appears
/// there the instant you let go — in your own words, with a rough figure — and
/// leaves it the moment the kitchen computer has understood it. While it is
/// there it can be said again, or taken off. Nothing is ever waiting somewhere
/// you cannot see it, which is the difference between a rough total you can
/// trust and one you cannot.
class SayWhatYouAteSection extends StatefulWidget {
  final DayRepository repository;
  final SaidRepository said;
  final Microphone microphone;

  /// Taking a row back off the day. Optional only so a test can mount this
  /// read-only; Home always passes it.
  final HouseholdLogger? logger;

  /// Called whenever the day changes underneath, so the screen around this
  /// redraws — speaking a dinner onto the day changes what is left of it.
  final VoidCallback? onChanged;

  /// The day, as 'YYYY-MM-DD'. Passed in rather than read from the clock so a
  /// test is not at the mercy of what time it runs.
  final String day;

  const SayWhatYouAteSection({
    super.key,
    required this.repository,
    required this.said,
    required this.microphone,
    required this.day,
    this.logger,
    this.onChanged,
  });

  static const holdToTalk = 'Hold to say what you ate';
  static const listening = 'Listening — let go when you have finished';
  static const noMicrophone =
      'This phone will not let the app listen. You can still type it.';
  static const typeItInstead = 'or type what you ate';
  static const workingOut = 'Still working this out';
  static const heading = 'Said, not settled yet';
  static const tryAgain = 'Say it again';
  static const takeItOff = 'Take it off';
  static const notHeardYet = 'Something you said';

  /// How long a row has been sitting unfinished, in the words a person would
  /// use. A row from four hours ago should not read the same as one from four
  /// seconds ago — one of them is waiting and the other is stuck.
  static String waitingFor(DateTime? since, {DateTime? now}) {
    if (since == null) return '';
    final gap = (now ?? DateTime.now()).difference(since);
    if (gap.inMinutes < 1) return 'just now';
    if (gap.inMinutes < 60) return '${gap.inMinutes} minutes ago';
    if (gap.inHours < 24) {
      return gap.inHours == 1 ? 'an hour ago' : '${gap.inHours} hours ago';
    }
    return gap.inDays == 1 ? 'yesterday' : '${gap.inDays} days ago';
  }

  @override
  State<SayWhatYouAteSection> createState() => SayWhatYouAteSectionState();
}

class SayWhatYouAteSectionState extends State<SayWhatYouAteSection> {
  List<LoggedItem> _rough = const [];
  bool _listening = false;
  bool _busy = false;
  String? _problem;
  String? _question;
  String? _questionAbout;
  final _typed = TextEditingController();
  final _answer = TextEditingController();
  final _log = Logger('SayWhatYouAte');

  @override
  void initState() {
    super.initState();
    reload();
  }

  @override
  void dispose() {
    _typed.dispose();
    _answer.dispose();
    super.dispose();
  }

  /// Read the day again, and try once more on anything still unfinished.
  ///
  /// The retry happens here, when the day is read, because that is the moment
  /// the phone is demonstrably talking to the kitchen computer anyway. Nothing
  /// runs on a timer: a row that stays unfinished is visible with both exits on
  /// it, so nobody is ever waiting on a retry they cannot see.
  Future<void> reload({bool catchUp = true}) async {
    try {
      final day = await widget.repository.today(widget.day);
      if (!mounted) return;
      setState(() {
        _rough = day.workingOut;
        _problem = null;
      });
      if (catchUp && _rough.isNotEmpty) {
        final settled = await widget.said.catchUp(_rough);
        if (settled > 0 && mounted) {
          await reload(catchUp: false);
          widget.onChanged?.call();
        }
      }
    } on StateError {
      // Nobody has said whose phone this is yet. The app asks before it opens.
      if (!mounted) return;
      setState(() => _rough = const []);
    } catch (e) {
      _log.info('[SAID] could not read the day: $e');
      if (!mounted) return;
      setState(() => _rough = const []);
    }
  }

  /// Getting the microphone going, while it is still going.
  ///
  /// Held onto because letting go can happen before it has finished. Asking the
  /// phone for permission and opening the microphone is real work, and a short
  /// sentence — "an apple" — is over before it lands. Without this, letting go
  /// arrives while the recorder is still coming up, finds nothing listening,
  /// and quietly does nothing: you say something, you watch the button, and
  /// nothing appears. The short sentences are exactly the ones this feature is
  /// for, so that is not an edge case, it is the main case.
  Future<void>? _starting;

  Future<void> _startListening() async {
    if (_busy || _listening) return;
    final coming = _reallyStart();
    _starting = coming;
    await coming;
  }

  Future<void> _reallyStart() async {
    if (!await widget.microphone.allowed()) {
      if (!mounted) return;
      setState(() => _problem = SayWhatYouAteSection.noMicrophone);
      return;
    }
    await widget.microphone.start();
    if (!mounted) return;
    setState(() {
      _listening = true;
      _problem = null;
    });
  }

  Future<void> _stopListening() async {
    await _starting;
    if (!_listening) return;
    setState(() => _listening = false);
    final clip = await widget.microphone.stop();
    if (clip == null) return;
    await _send(recording: clip);
  }

  /// They let go somewhere else. The sound is thrown away here and no row is
  /// ever made — changing your mind mid-sentence should cost nothing and reach
  /// nothing.
  Future<void> _abandon() async {
    await _starting;
    if (!_listening) return;
    setState(() => _listening = false);
    await widget.microphone.abandon();
  }

  Future<void> _sendTyped() async {
    final words = _typed.text.trim();
    if (words.isEmpty) return;
    _typed.clear();
    await _send(words: words);
  }

  /// The one order that matters: the row goes on the day, and only then does
  /// anything try to understand it.
  Future<void> _send({String? words, File? recording}) async {
    setState(() => _busy = true);
    try {
      final name = await widget.said.heard(
          day: widget.day, words: words, recording: recording);
      widget.onChanged?.call();
      await reload(catchUp: false);
      final answer =
          await widget.said.workOut(clientId: name, version: 0, words: words);
      if (!mounted) return;
      setState(() {
        _question = answer?.question;
        _questionAbout = answer?.question == null ? null : name;
      });
      await reload(catchUp: false);
      widget.onChanged?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Answering the one question. It goes back as another sentence through the
  /// same route, with the answer said alongside the original words — which is
  /// exactly what a person would do out loud, and means there is no second kind
  /// of message for the server to understand.
  Future<void> _answerQuestion() async {
    final about = _questionAbout;
    final reply = _answer.text.trim();
    if (about == null || reply.isEmpty) return;
    final row = _rough.where((r) => r.clientId == about).firstOrNull;
    _answer.clear();
    setState(() {
      _question = null;
      _questionAbout = null;
      _busy = true;
    });
    try {
      await widget.said.workOut(
          clientId: about,
          version: row?.version ?? 0,
          words: '${row?.said ?? ''} — $reply'.trim());
      await reload(catchUp: false);
      widget.onChanged?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sayAgain(LoggedItem row) async {
    final name = row.clientId;
    if (name == null) return;
    setState(() => _busy = true);
    try {
      await widget.said
          .workOut(clientId: name, version: row.version, words: row.said);
      await reload(catchUp: false);
      widget.onChanged?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _takeOff(LoggedItem row) async {
    final logger = widget.logger;
    final name = row.clientId;
    if (logger == null || name == null) return;
    setState(() => _rough = _rough.where((r) => r.clientId != name).toList());
    await logger.retireFood(name);
    widget.onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: GestureDetector(
            onLongPressStart: (_) => _startListening(),
            onLongPressEnd: (_) => _stopListening(),
            onLongPressCancel: _abandon,
            child: FilledButton.tonalIcon(
              // The button itself does nothing on a plain tap: this is a
              // hold-and-talk control, and a tap that started a recording
              // nobody meant to start is how a phone ends up listening in a
              // pocket.
              onPressed: () {},
              icon: Icon(_listening ? Icons.mic : Icons.mic_none),
              label: Text(_listening
                  ? SayWhatYouAteSection.listening
                  : SayWhatYouAteSection.holdToTalk),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _typed,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendTyped(),
            decoration: InputDecoration(
              isDense: true,
              hintText: SayWhatYouAteSection.typeItInstead,
              suffixIcon: IconButton(
                icon: const Icon(Icons.send),
                onPressed: _busy ? null : _sendTyped,
              ),
            ),
          ),
        ),
        if (_problem != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(_problem!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          ),
        if (_question != null) _questionPanel(theme),
        if (_rough.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(SayWhatYouAteSection.heading,
                style: theme.textTheme.titleSmall),
          ),
          for (final row in _rough) _roughRow(theme, row),
        ],
      ],
    );
  }

  Widget _questionPanel(ThemeData theme) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_question!, style: theme.textTheme.bodyMedium),
            TextField(
              controller: _answer,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _answerQuestion(),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Answer',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _busy ? null : _answerQuestion,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _roughRow(ThemeData theme, LoggedItem row) {
    final waiting = SayWhatYouAteSection.waitingFor(row.provisionalSince);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(row.said ?? row.label,
                    style: theme.textTheme.bodyLarge),
              ),
              // Marked as rough right next to the number rather than in a
              // caption somewhere else on the screen. A figure and the fact
              // that it is a guess have to be read in one glance or the guess
              // is not really being shown at all.
              Figures.kcalText(context, row.kcal,
                  prefix: 'about ',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.outline)),
            ],
          ),
          Text(
            waiting.isEmpty
                ? SayWhatYouAteSection.workingOut
                : '${SayWhatYouAteSection.workingOut} — $waiting',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.outline),
          ),
          if (row.assumed != null)
            Text(row.assumed!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.outline)),
          Row(
            children: [
              TextButton(
                onPressed: _busy ? null : () => _sayAgain(row),
                child: const Text(SayWhatYouAteSection.tryAgain),
              ),
              if (widget.logger != null)
                TextButton(
                  onPressed: () => _takeOff(row),
                  child: const Text(SayWhatYouAteSection.takeItOff),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
