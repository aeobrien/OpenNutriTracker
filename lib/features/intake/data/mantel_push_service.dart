import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:opennutritracker/core/utils/notification_service.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/intake/data/data_source/mantel_data_source.dart';
import 'package:opennutritracker/features/intake/data/mantel_secure_storage.dart';
import 'package:opennutritracker/features/intake/data/mantel_sync_service.dart';

/// Wires Firebase Cloud Messaging to the Mantel meal sync (Phase B).
///
/// On start: ask notification permission, get the FCM token, register it with
/// Mantel so the server can push new intakes. When a push arrives, run the
/// Phase-A sync so the meal lands in the diary, and (foregrounded) surface a
/// banner. Push is the "usually instant" layer; the app-open/foreground sync
/// (Phase A) stays the reliable backstop, so every step here is best-effort and
/// degrades quietly if Mantel isn't configured or permission is denied.
class MantelPushService {
  final MantelSyncService _sync;
  final NotificationService _notifications;
  final SecureAppStorageProvider _storage;

  final _log = Logger('MantelPushService');
  bool _started = false;

  MantelPushService(this._sync, this._notifications, this._storage);

  Future<void> init() async {
    if (_started) return;
    _started = true;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      _log.info('[MANTEL-PUSH] notification permission: '
          '${settings.authorizationStatus}');
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        _log.info('Notifications denied — push off, Phase-A sync still works');
        return;
      }

      await _registerCurrentToken();
      messaging.onTokenRefresh.listen(_registerToken);

      // Foreground: iOS won't show the remote banner, so sync + show a local one.
      FirebaseMessaging.onMessage.listen((message) async {
        _log.fine('Push received (foreground)');
        final result = await _sync.syncPending();
        if (result.hasNewEntries) {
          final n = message.notification;
          await _notifications.showInstant(
            n?.title ?? 'Meal logged',
            n?.body ?? 'Synced from Mantel',
          );
        }
      });

      // Tapped a push that opened the app → just sync.
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _sync.syncPending());
    } catch (e) {
      _log.warning('Mantel push init failed (continuing without push): $e');
    }
  }

  Future<void> _registerCurrentToken() async {
    // On iOS the APNS token must exist before the FCM token resolves, and it's
    // commonly null for the first moment after permission is granted — so retry
    // briefly instead of silently giving up (which left device_tokens empty).
    String? apns;
    for (var i = 1; i <= 5; i++) {
      apns = await FirebaseMessaging.instance.getAPNSToken();
      if (apns != null) break;
      _log.info('[MANTEL-PUSH] APNS token not ready (attempt $i/5) — retrying');
      await Future.delayed(const Duration(seconds: 2));
    }
    if (apns == null) {
      _log.warning('[MANTEL-PUSH] no APNS token after retries — push cannot '
          'register. Check the Push Notifications capability + provisioning '
          'on this build.');
      return;
    }
    _log.info('[MANTEL-PUSH] APNS token acquired');
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null || token.isEmpty) {
      _log.warning('[MANTEL-PUSH] APNS ok but FCM getToken() returned null — '
          'Firebase project / APNs key mismatch?');
      return;
    }
    _log.info('[MANTEL-PUSH] FCM token acquired — registering with Mantel');
    await _registerToken(token);
  }

  Future<void> _registerToken(String? token) async {
    if (token == null || token.isEmpty) {
      _log.warning('[MANTEL-PUSH] no FCM token — cannot register for push');
      return;
    }
    if (!await _storage.hasMantelConfig()) {
      _log.info('[MANTEL-PUSH] Mantel not configured — skipping registration');
      return;
    }
    final url = (await _storage.getMantelBaseUrl())!;
    final actor = (await _storage.getMantelActor())!;
    final apiToken = await _storage.getMantelIntakeToken();
    final ok = await MantelDataSource(baseUrl: url, actor: actor, token: apiToken)
        .registerDevice(token);
    _log.info('[MANTEL-PUSH] registered device with Mantel (actor=$actor): $ok');
  }
}
