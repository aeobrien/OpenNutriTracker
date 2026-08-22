import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/drift/app_database.dart';
import 'package:opennutritracker/core/data/drift/daos/outbox_dao.dart';
import 'package:opennutritracker/core/data/drift/daos/own_row_dao.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/features/household/data/household_api.dart';

/// What happened on one attempt to empty the queue.
class OutboxDrainResult {
  /// Items the server confirmed and that have left the queue for good.
  final int sent;

  /// Items still waiting — either the server could not be reached, or it
  /// refused them and they are being kept rather than thrown away.
  final int remaining;

  /// True when the Mac Mini could not be reached at all. This is what the app
  /// says out loud; a refusal is a different thing and is not "offline".
  final bool unreachable;

  const OutboxDrainResult({
    this.sent = 0,
    this.remaining = 0,
    this.unreachable = false,
  });
}

/// The one queue of work waiting to reach the Mac Mini.
///
/// There is exactly one. Everything the phone writes to the household server —
/// a meal, some exercise, a weight, a new food — is enqueued here and sent from
/// here, whether or not the network happens to be up at the time. The app never
/// posts to the household server anywhere else, so "have we sent that yet?" has
/// a single answer.
///
/// Three rules, in the order they matter:
///
///  1. **Nothing is lost.** An item is only removed once the server has
///     confirmed it. A crash, a kill, a flat battery: the queue is on disk, so
///     it is all still there next time the app opens.
///  2. **Nothing is sent twice.** Each item carries an id minted on the phone
///     when the person tapped. The server remembers ids, so a resend after a
///     reply we never saw returns the original row instead of making a second.
///  3. **Who it belongs to was decided when it was logged.** Owner, author and
///     time are frozen at enqueue. Handing the phone to the other person does
///     not reach back and change what is already waiting.
class Outbox {
  static const _maxAttempts = 8;

  final OutboxDao _dao;

  /// What this phone has done, written down as it does it. The queue is the
  /// only place every write passes through, so it is the only place that can
  /// keep that record completely. See [OwnRowDao].
  final OwnRowDao? _own;
  final HouseholdApi _api;
  final _log = Logger('Outbox');

  /// The drain currently running, if one is. Held so a second caller can wait
  /// for it instead of being handed a result about a queue nobody looked at.
  Future<OutboxDrainResult>? _inFlight;

  /// Told the moment something joins the queue, so it can be sent straight
  /// away rather than waiting for the app to be opened again.
  ///
  /// This exists because it did not. Sending was tried on start, on coming
  /// back to the front, and on a two-minute timer that was only ever set when
  /// a previous attempt had left something behind — so a queue that was empty
  /// when the app opened had nothing scheduled at all, and the first thing
  /// added after that sat there. On 20 August a weight typed into Profile
  /// showed on the phone at once and did not reach the Mac Mini until
  /// the app was backgrounded and brought back. The phone and the panel
  /// disagreed for as long as somebody kept looking at the phone.
  void Function()? onQueued;

  Outbox(this._dao, this._api, {OwnRowDao? own}) : _own = own;

  factory Outbox.of(AppDatabase db, HouseholdApi api) =>
      Outbox(OutboxDao(db), api, own: OwnRowDao(db));

  /// Put work on the queue. Returns the client id, which is how this piece of
  /// work is known from here on — to the queue, to the server, and to any
  /// retry.
  Future<String> enqueue({
    required String path,
    required Map<String, dynamic> body,
    required int ownerId,
    required int authorId,
    DateTime? loggedAt,
    String? clientId,
  }) async {
    final id = clientId ?? IdGenerator.getUniqueID();
    final at = loggedAt ?? DateTime.now();
    final seconds = at.millisecondsSinceEpoch ~/ 1000;
    await _dao.add(OutboxItemsCompanion(
      clientId: Value(id),
      path: Value(path),
      body: Value(jsonEncode(body)),
      ownerId: Value(ownerId),
      authorId: Value(authorId),
      loggedAt: Value(seconds),
      queuedAt: Value(DateTime.now().millisecondsSinceEpoch),
    ));
    // Written down before anything is sent, because the record is of what this
    // phone *did*, not of what got through. A row that reaches the house on a
    // retry tomorrow is still this phone's action today.
    // Stamped now rather than with the row's own time: this is a record of
    // when the phone acted, and a backdated entry is still today's action.
    await _own?.remember(id);
    _log.info('[OUTBOX] queued $path as $id for person $ownerId');
    onQueued?.call();
    return id;
  }

  /// Take a queued *create* back off the queue, if it is still there.
  ///
  /// Answers whether it was. True means nothing about that row ever left this
  /// phone, so there is nothing to unsay: BC-0025's "deleting an entry that is
  /// still queued removes it from the queue as well, so nothing is sent
  /// afterwards for something already deleted".
  ///
  /// Two things it deliberately will not do.
  ///
  /// **It will not touch anything while a drain is running.** The drain posts
  /// an item and then removes it; taking the row out from under that would let
  /// the house receive the create while this phone has thrown away the only
  /// thing that could have retired it — a row standing on somebody's day that
  /// nothing on either machine says is wrong. So a delete during a drain
  /// queues its retire like any other, which costs one round trip and cannot
  /// leave that behind.
  ///
  /// **It will only cancel a create.** A correction or a removal for the same
  /// row carries its own id and is not what "still queued" means here. The path
  /// is checked as well as the id so that stays true even if an id is ever
  /// reused.
  Future<bool> cancelQueuedEntry(String clientId) async {
    if (_inFlight != null) {
      _log.info('[OUTBOX] not cancelling $clientId — a drain is running');
      return false;
    }
    final queued = await _dao.byClientId(clientId);
    if (queued == null || queued.path != _entryPath) return false;
    _takenBack[clientId] = queued;
    await _dao.remove(clientId);
    _log.info('[OUTBOX] cancelled $clientId — it never left the phone');
    return true;
  }

  /// Put back on the queue a create that [cancelQueuedEntry] took off it.
  ///
  /// Answers whether there was one. This is what makes Undo honest after a
  /// delete that never left the phone: without it, undoing would ask the house
  /// to put back a row it has never heard of, and the house would rightly
  /// refuse — eight times, over the following hour, while the phone showed the
  /// row perfectly happily.
  ///
  /// Held in memory rather than on disk, deliberately. The offer to undo lives
  /// about five seconds; a cancelled create that outlives the app was not
  /// undone and should stay cancelled.
  Future<bool> putBackQueuedEntry(String clientId) async {
    final held = _takenBack.remove(clientId);
    if (held == null) {
      // Nothing was taken back — but if the creation is sitting on the queue
      // anyway, this row has still never left the phone and there is nothing
      // for the house to put back. Answering false here would queue an undo
      // for a row the house has never heard of, which is what a second press
      // of Undo used to do: correct on the phone, refused eight times over the
      // following hour on the other side of the wire.
      final queued = await _dao.byClientId(clientId);
      return queued != null && queued.path == _entryPath;
    }
    await _dao.add(OutboxItemsCompanion(
      clientId: Value(held.clientId),
      path: Value(held.path),
      body: Value(held.body),
      ownerId: Value(held.ownerId),
      authorId: Value(held.authorId),
      // Both the moment it happened and the moment it joined the queue are the
      // originals. This is the same piece of work coming back, not a new one:
      // a fresh queuedAt would send it after things that were logged later.
      loggedAt: Value(held.loggedAt),
      queuedAt: Value(held.queuedAt),
      attempts: Value(held.attempts),
      lastError: Value(held.lastError),
    ));
    _log.info('[OUTBOX] $clientId is back on the queue');
    onQueued?.call();
    return true;
  }

  /// Creates taken off the queue by a delete, kept only until the offer to undo
  /// that delete has gone. See [putBackQueuedEntry].
  final Map<String, OutboxItem> _takenBack = {};

  /// Where a newly logged row is sent. Named here because [cancelQueuedEntry]
  /// has to recognise one.
  static const _entryPath = '/household/entry';

  Future<int> pendingCount() => _dao.count();

  Future<List<OutboxItem>> pending() => _dao.pending();

  /// Try to send everything waiting, oldest first.
  ///
  /// Stops at the first sign the Mini is unreachable — there is no point
  /// working through fifty items to collect fifty identical timeouts, and the
  /// order they were logged in is worth keeping.
  Future<OutboxDrainResult> drain() {
    // A second caller waits for the drain already running rather than being
    // told everything is fine.
    //
    // It used to return straight away with a result that said nothing was
    // unreachable and nothing had been sent — which is indistinguishable, to
    // the caller, from a queue that emptied successfully. Saying what you ate
    // asks for a drain and then asks the Mini about the row, and its whole
    // reason for draining first is that a question about a row the Mini has
    // never heard of comes back as a plain 404. On 21 August 2026 that is
    // exactly what happened: the drain was already running, the all-clear was
    // untrue, and the question went out about a row still sitting in the queue.
    final running = _inFlight;
    if (running != null) return running;
    final started = _drainOnce();
    _inFlight = started;
    return started.whenComplete(() => _inFlight = null);
  }

  Future<OutboxDrainResult> _drainOnce() async {
    var sent = 0;
    var unreachable = false;
    for (final item in await _dao.pending()) {
      if (item.attempts >= _maxAttempts) continue;
      final body = jsonDecode(item.body) as Map<String, dynamic>;
      body['client_id'] = item.clientId;
      body['owner_id'] = item.ownerId;
      body['author_id'] = item.authorId;
      body['logged_at'] = item.loggedAt;
      try {
        await _api.post(item.path, body);
        await _dao.remove(item.clientId);
        sent += 1;
      } on HouseholdUnreachable catch (e) {
        _log.info('[OUTBOX] holding ${item.clientId}: ${e.message}');
        unreachable = true;
        break;
      } on HouseholdRefused catch (e) {
        // Kept, not dropped. A refusal usually means something we can fix and
        // resend; throwing the person's dinner away because the server
        // disagreed with the request is not an option.
        _log.warning('[OUTBOX] ${item.clientId} refused: ${e.message}');
        await _dao.recordFailure(item.clientId, e.message);
      }
    }
    return OutboxDrainResult(
      sent: sent,
      remaining: await _dao.count(),
      unreachable: unreachable,
    );
  }
}
