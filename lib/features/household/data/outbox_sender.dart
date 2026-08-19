import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/features/household/data/outbox.dart';

/// The thing that actually empties the queue.
///
/// [Outbox] knows *how* to send and never decides *when*. That separation is
/// deliberate — the queue has to be testable without a running app — but it
/// leaves a hole worth naming: a queue nobody empties is worse than no queue at
/// all, because work is written down safely and then never delivered, and from
/// the person's side that looks exactly like it worked.
///
/// This closes it. There are three moments worth trying, and no others:
///
///  1. **When the app opens.** Whatever was waiting from last time goes first.
///  2. **When the app comes back to the front.** The usual reason work is stuck
///     is that the phone was out of the house; coming back is when that changes.
///  3. **On a slow retry while anything is still waiting.** Not a poll — the
///     timer stops as soon as the queue is empty, and starts again only when
///     something new is held.
///
/// Nothing here decides what to send or in what order; that is the queue's job
/// and it is unchanged.
class OutboxSender with WidgetsBindingObserver {
  /// How long to wait before trying again while items are still held. Long
  /// enough not to matter to the battery, short enough that walking back
  /// through the front door is not a long wait.
  static const retryEvery = Duration(minutes: 2);

  final Outbox _outbox;
  final _log = Logger('OutboxSender');

  Timer? _retry;
  bool _started = false;

  OutboxSender(this._outbox);

  /// Begin watching. Sends once immediately for whatever last time left behind.
  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    unawaited(sendNow());
  }

  void stop() {
    if (!_started) return;
    _started = false;
    WidgetsBinding.instance.removeObserver(this);
    _retry?.cancel();
    _retry = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(sendNow());
  }

  /// Try now. Safe to call at any time — the queue itself refuses to run twice
  /// at once, so a resume landing on top of the retry timer costs nothing.
  Future<OutboxDrainResult> sendNow() async {
    final result = await _outbox.drain();
    if (result.sent > 0) {
      _log.info('[OUTBOX] delivered ${result.sent}, ${result.remaining} still held');
    }
    if (result.remaining > 0) {
      _scheduleRetry();
    } else {
      _retry?.cancel();
      _retry = null;
    }
    return result;
  }

  void _scheduleRetry() {
    if (_retry != null || !_started) return;
    _retry = Timer(retryEvery, () {
      _retry = null;
      unawaited(sendNow());
    });
  }
}
