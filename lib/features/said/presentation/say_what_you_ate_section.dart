import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/said/data/microphone.dart';
import 'package:opennutritracker/features/said/data/said_repository.dart';

/// Saying what you ate, on the screen you are already looking at.
///
/// Hold the button and talk, or type it. Both become one sentence going to the
/// same place, so there is no second, worse way of doing this for the times you
/// cannot speak out loud. At most one question comes back, and answering it is
/// just another sentence through the same route.
///
/// **What this does not have is a list of its own, and that is the point.**
/// Until 20 August 2026 it did: a spoken meal appeared here, in its own
/// section, while the app's four meal slots sat empty a scroll further down and
/// the ring at the top counted only those. Aidan looked at that and said:
///
///     "It's not clear to me why I ALSO have a days of the week section which
///     is where foods added using the 'hold to say what you ate' function
///     appear, or why this section seems to be completely separate to the
///     existing food tracking system - it seems like despite the issues we had
///     yesterday you are still building a separate system inside the existing
///     system."
///
/// Spoken food now lands in the diary this app already had, through the mirror
/// this app already had — a page of settled meals pulled from the household and
/// written in as ordinary entries. So a spoken breakfast and a scanned one end
/// up in the same place, count the same, and are edited and deleted the same
/// way. This widget's whole job is the sentence; what becomes of it belongs to
/// the diary.
///
/// The one thing kept from the old shape is the honesty about waiting. While a
/// sentence is being worked out this says so, because several seconds of a
/// button that has visibly done nothing is how somebody says it twice — which
/// is exactly what he did.
class SayWhatYouAteSection extends StatefulWidget {
  final SaidRepository said;
  final Microphone microphone;

  /// Called once a sentence has been understood, so the screen around this can
  /// fetch what it became and redraw.
  final VoidCallback? onChanged;

  /// The day, as 'YYYY-MM-DD'. Passed in rather than read from the clock so a
  /// test is not at the mercy of what time it runs.
  final String day;

  const SayWhatYouAteSection({
    super.key,
    required this.said,
    required this.microphone,
    required this.day,
    this.onChanged,
  });

  static const holdToTalk = 'Hold to say what you ate';
  static const listening = 'Listening — let go when you have finished';
  static const noMicrophone =
      'This phone will not let the app listen. You can still type it.';
  static const typeItInstead = 'or type what you ate';
  static const workingOut = 'Working out what that was…';
  static const notUnderstood =
      "That did not come back as anything. It is on the kitchen computer as you "
      'said it — say it again, or add it below.';
  static const couldNotReach =
      "The kitchen computer did not answer, so that is not counted yet. It will "
      'go over next time the app can reach it.';

  static String dayKey(DateTime now) => '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}';

  @override
  State<SayWhatYouAteSection> createState() => SayWhatYouAteSectionState();
}

class SayWhatYouAteSectionState extends State<SayWhatYouAteSection> {
  bool _listening = false;
  bool _busy = false;
  String? _problem;
  String? _question;
  String? _questionAbout;
  String? _questionWords;
  final _typed = TextEditingController();
  final _answer = TextEditingController();
  final _log = Logger('SayWhatYouAte');

  @override
  void dispose() {
    _typed.dispose();
    _answer.dispose();
    super.dispose();
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
    if (words.isEmpty || _busy) return;
    _typed.clear();
    await _send(words: words);
  }

  /// One sentence, all the way through: onto the household's ledger, understood
  /// there, and then into this phone's diary.
  ///
  /// The button is locked for the whole of it. Before 20 August 2026 it was not,
  /// and the wait had nothing to show, so Aidan said his breakfast, saw nothing
  /// move, said it again, and got two of everything. A control that is working
  /// has to look like one.
  Future<void> _send({String? words, File? recording}) async {
    setState(() {
      _busy = true;
      _problem = null;
      _question = null;
      _questionAbout = null;
    });
    try {
      final name = await widget.said.heard(
          day: widget.day, words: words, recording: recording);
      final answer =
          await widget.said.workOut(clientId: name, version: 0, words: words);
      if (!mounted) return;
      setState(() {
        _question = answer?.question;
        _questionAbout = answer?.question == null ? null : name;
        _questionWords = answer?.said ?? words;
        _problem = _whatWentWrong(answer);
      });
      widget.onChanged?.call();
    } catch (e) {
      _log.info('[SAID] that sentence did not get through: $e');
      if (!mounted) return;
      setState(() => _problem = SayWhatYouAteSection.couldNotReach);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// What to say when a sentence did not become anything, or null when it did.
  ///
  /// "Their hand won" is not a problem and is deliberately silent: it means the
  /// person corrected the row themselves while this was in flight, which is the
  /// system working.
  String? _whatWentWrong(dynamic answer) {
    if (answer == null) return SayWhatYouAteSection.couldNotReach;
    if (answer.applied as bool) return null;
    final why = answer.why as String?;
    if (why == 'it was changed by hand since') return null;
    return SayWhatYouAteSection.notUnderstood;
  }

  /// Answering the one question. It goes back as another sentence through the
  /// same route, with the answer said alongside the original words — which is
  /// exactly what a person would do out loud, and means there is no second kind
  /// of message for the server to understand.
  Future<void> _answerQuestion() async {
    final about = _questionAbout;
    final reply = _answer.text.trim();
    if (about == null || reply.isEmpty || _busy) return;
    final original = _questionWords ?? '';
    _answer.clear();
    setState(() {
      _question = null;
      _questionAbout = null;
      _busy = true;
    });
    try {
      await widget.said.workOut(
          clientId: about, version: 0, words: '$original — $reply'.trim());
      widget.onChanged?.call();
    } catch (e) {
      _log.info('[SAID] the answer did not get through: $e');
      if (!mounted) return;
      setState(() => _problem = SayWhatYouAteSection.couldNotReach);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
              icon: _busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_listening ? Icons.mic : Icons.mic_none),
              label: Text(_busy
                  ? SayWhatYouAteSection.workingOut
                  : _listening
                      ? SayWhatYouAteSection.listening
                      : SayWhatYouAteSection.holdToTalk),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          // Named so the harness can type a sentence here. The microphone
          // cannot be driven on a simulator, so this box is the only way a
          // machine can walk the path Aidan actually complained about — a
          // sentence going in and food coming out the other end in the diary.
          child: Semantics(
            identifier: 'say-typed',
            child: TextField(
              controller: _typed,
              enabled: !_busy,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTyped(),
              decoration: InputDecoration(
                isDense: true,
                hintText: SayWhatYouAteSection.typeItInstead,
                suffixIcon: Semantics(
                  identifier: 'say-send',
                  child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _busy ? null : _sendTyped,
                  ),
                ),
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
              enabled: !_busy,
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
}
