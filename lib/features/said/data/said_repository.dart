import 'dart:io';

import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';
import 'package:opennutritracker/features/household/data/household_logger.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';
import 'package:opennutritracker/features/said/data/clip_store.dart';
import 'package:opennutritracker/features/said/domain/understood.dart';
import 'package:opennutritracker/features/today/domain/day_view.dart';

/// Saying what you ate.
///
/// The order of the two things this does is the whole design, so it is written
/// down rather than left to be inferred from the code below.
///
/// **The row is written before anything is understood.** Not after, and not
/// conditionally. You let go of the button and it is on your day — in your own
/// words, with a rough figure, marked as rough. Only then does anything try to
/// work out what you meant. The obvious other order — understand it, then write
/// it — reads better in code and is wrong in the one situation that matters: the
/// kitchen computer is asleep, or slow, or the train went into a tunnel, and
/// what you said is simply gone. A day that is roughly right and says so is
/// worth more than a day that is exactly right about the half of it that got
/// through.
///
/// **The queue is used for the row and not for the sentence.** The row goes
/// through the outbox like every other write on this phone, so it survives the
/// tunnel. The recording does not: it is kept beside the row under the same
/// name and offered again next time the day is read. That split exists because
/// the outbox carries JSON to a known route and a recording is neither of those
/// things, and because being unable to hear a sentence is recoverable — the row
/// is already on the day — whereas losing the row is not.
class SaidRepository {
  final HouseholdApi _api;
  final HouseholdLogger _logger;
  final Outbox _outbox;
  final ClipStore _clips;
  final _log = Logger('SaidRepository');

  SaidRepository(this._api, this._logger, this._outbox, this._clips);

  /// What a row says while nothing has heard it yet. It is replaced by the real
  /// sentence the moment the kitchen computer comes back with one.
  static const notHeardYet = 'Something you said';

  /// Put what somebody just said on their day, and then try to understand it.
  ///
  /// Returns the name the row now has, which is how anything asks about it
  /// afterwards. [words] is a typed sentence; [recording] is a spoken one. Both
  /// end up as the same string on the other side and are treated identically
  /// from that point — a sentence typed into a box and a sentence said out loud
  /// are the same claim about the same day.
  Future<String> heard({
    required String day,
    String? words,
    File? recording,
    DateTime? at,
  }) async {
    final typed = (words ?? '').trim();
    if (typed.isEmpty && recording == null) {
      throw ArgumentError('nothing was said');
    }
    final clientId = await _logger.logFood(
      day: day,
      // A recording nobody has listened to yet has no words to show, so the row
      // says what it honestly is. It is replaced by the real sentence the
      // moment anything hears it.
      label: typed.isEmpty ? notHeardYet : typed,
      state: 'provisional',
      said: typed.isEmpty ? null : typed,
      at: at,
    );
    if (recording != null) {
      await _clips.keep(clientId, recording);
    }
    _log.info('[SAID] $clientId is on the day, now working out what it was');
    return clientId;
  }

  /// Ask the kitchen computer what a row actually was.
  ///
  /// [version] is what the row is at right now, and it travels with the
  /// question so that a correction made while the answer is on the wire wins.
  /// Returns null when the Mini could not be reached — the row stays exactly as
  /// it is, still on the day, still in the person's own words.
  Future<Understood?> workOut({
    required String clientId,
    required int version,
    String? words,
  }) async {
    // The row has to be there before it can be asked about, and it went on the
    // queue rather than straight to the server. Draining first is not an
    // optimisation — a question about a row the Mini has never heard of is a
    // plain 404 and would look like a failure to understand.
    final drained = await _outbox.drain();
    if (drained.unreachable) {
      _log.info('[SAID] $clientId stays as it is — cannot reach the Mini');
      return null;
    }
    final clip = await _clips.forRow(clientId);
    try {
      final answer = Understood.fromJson(await _api.said(
        clientId: clientId,
        version: version,
        text: words,
        clip: clip,
      ));
      if (answer.applied || answer.why == 'it was changed by hand since') {
        // Heard, one way or the other. Either it settled, or the person got
        // there first and their answer stands — in both cases nothing is owed
        // and the recording has no reason to exist any more.
        await _clips.forget(clientId);
      }
      _log.info('[SAID] $clientId -> applied=${answer.applied} '
          'why=${answer.why} question=${answer.question}');
      return answer;
    } on HouseholdUnreachable catch (e) {
      _log.info('[SAID] $clientId stays as it is: ${e.message}');
      return null;
    }
  }

  /// Try again on everything still waiting to be understood.
  ///
  /// Called when the day is read, which is the moment the phone is demonstrably
  /// talking to the kitchen computer anyway. Nothing is retried on a timer:
  /// a row that stays unfinished is visible on the day with both exits on it,
  /// so the person is never waiting on a retry they cannot see.
  Future<int> catchUp(Iterable<LoggedItem> rows) async {
    var settled = 0;
    for (final row in rows.where((r) => r.stillBeingWorkedOut)) {
      final name = row.clientId;
      if (name == null) continue;
      final answer =
          await workOut(clientId: name, version: row.version, words: row.said);
      if (answer == null) break; // unreachable — no point trying the rest
      if (answer.applied) settled += 1;
    }
    return settled;
  }
}
