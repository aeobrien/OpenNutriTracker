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

  bool _draining = false;

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

  Future<int> pendingCount() => _dao.count();

  Future<List<OutboxItem>> pending() => _dao.pending();

  /// Try to send everything waiting, oldest first.
  ///
  /// Stops at the first sign the Mini is unreachable — there is no point
  /// working through fifty items to collect fifty identical timeouts, and the
  /// order they were logged in is worth keeping.
  Future<OutboxDrainResult> drain() async {
    if (_draining) {
      return OutboxDrainResult(remaining: await _dao.count());
    }
    _draining = true;
    var sent = 0;
    var unreachable = false;
    try {
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
    } finally {
      _draining = false;
    }
    return OutboxDrainResult(
      sent: sent,
      remaining: await _dao.count(),
      unreachable: unreachable,
    );
  }
}
