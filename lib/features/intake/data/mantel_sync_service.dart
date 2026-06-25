import 'package:logging/logging.dart';
import 'package:opennutritracker/core/data/repository/intake_repository.dart';
import 'package:opennutritracker/core/utils/id_generator.dart';
import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';
import 'package:opennutritracker/features/intake/data/data_source/mantel_data_source.dart';
import 'package:opennutritracker/features/intake/data/mantel_secure_storage.dart';

/// Result of one Mantel -> FoodTracker meal-sync pass.
class MantelSyncResult {
  /// New intakes inserted into the local diary this run.
  final int synced;

  /// Items already present locally (skipped, then acked so Mantel stops
  /// returning them) — the idempotency path.
  final int skipped;

  /// Items that errored on insert (not acked; a later run retries them).
  final int failed;

  /// False when Mantel isn't configured yet (no base URL / actor).
  final bool configured;

  const MantelSyncResult({
    this.synced = 0,
    this.skipped = 0,
    this.failed = 0,
    this.configured = true,
  });

  const MantelSyncResult.notConfigured() : this(configured: false);

  /// Whether this run actually added anything new (drives diary refresh).
  bool get hasNewEntries => synced > 0;

  @override
  String toString() =>
      'MantelSyncResult(synced: $synced, skipped: $skipped, failed: $failed, configured: $configured)';
}

/// Pulls an actor's resolved meals from Mantel and mirrors them into the local
/// food diary as quick-add intakes, then acks them so Mantel marks them
/// consumed. Mantel is the source of truth; this is a one-way, at-least-once,
/// idempotent pull.
///
/// Idempotency: each Mantel intake carries a UUID, stored locally as the log
/// entry's `externalId` (UNIQUE index). A re-pull of an already-synced intake is
/// skipped (and re-acked). We only ack AFTER a successful local insert, so a
/// dropped ack just re-pulls next time and dedups — never double-logs.
///
/// Concurrency: a single in-flight guard collapses overlapping triggers
/// (foreground resume + manual button can fire together) onto one run.
///
/// Phase A only — open-app + manual sync. Push (Phase B) is layered on later.
class MantelSyncService {
  final IntakeRepository _intakeRepository;
  final SecureAppStorageProvider _storage;

  /// Test seam: when set, used instead of building one from secure storage.
  final MantelDataSource? _injectedDataSource;

  final _log = Logger('MantelSyncService');
  static const _pageSize = 50;

  Future<MantelSyncResult>? _inFlight;

  MantelSyncService(
    this._intakeRepository,
    this._storage, {
    MantelDataSource? dataSource,
  }) : _injectedDataSource = dataSource;

  /// Syncs pending intakes. Overlapping calls share the one in-flight run.
  Future<MantelSyncResult> syncPending() {
    return _inFlight ??= _run().whenComplete(() => _inFlight = null);
  }

  Future<MantelDataSource?> _buildDataSource() async {
    if (_injectedDataSource != null) return _injectedDataSource;
    if (!await _storage.hasMantelConfig()) return null;
    final url = (await _storage.getMantelBaseUrl())!;
    final actor = (await _storage.getMantelActor())!;
    final token = await _storage.getMantelIntakeToken();
    return MantelDataSource(baseUrl: url, actor: actor, token: token);
  }

  Future<MantelSyncResult> _run() async {
    final ds = await _buildDataSource();
    if (ds == null) {
      _log.fine('Mantel sync skipped — not configured');
      return const MantelSyncResult.notConfigured();
    }

    var synced = 0;
    var skipped = 0;
    var failed = 0;
    String? afterId;

    while (true) {
      final page = await ds.getPending(limit: _pageSize, afterId: afterId);
      if (page.isEmpty) break;

      final ackable = <String>[];
      for (final dto in page) {
        try {
          if (await _intakeRepository.hasExternalIntake(dto.id)) {
            skipped++;
            ackable.add(dto.id); // already local → ack so it stops returning
            continue;
          }
          await _intakeRepository.addQuickAddIntake(
            id: IdGenerator.getUniqueID(),
            externalId: dto.id,
            kcal: dto.kcal,
            protein: dto.protein,
            carbs: dto.carbs,
            fat: dto.fat,
            label: dto.label,
            mealSlot: dto.foodTrackerMealSlot,
            dateTime: dto.eatenAtLocal,
          );
          synced++;
          ackable.add(dto.id);
        } catch (e) {
          // The UNIQUE index is the backstop: if a concurrent insert already
          // landed this externalId, re-check and treat as a skip+ack rather
          // than a failure. Anything else is a real failure — don't ack it.
          if (await _intakeRepository.hasExternalIntake(dto.id)) {
            skipped++;
            ackable.add(dto.id);
          } else {
            _log.warning('Failed to log Mantel intake "${dto.label}": $e');
            failed++;
          }
        }
      }

      if (ackable.isNotEmpty) {
        try {
          await ds.ack(ackable);
        } catch (e) {
          // A dropped ack is safe — the next pull re-pulls these and the
          // externalId dedup skips+re-acks them. Just log and continue.
          _log.warning('Mantel ack failed for ${ackable.length} ids: $e');
        }
      }

      afterId = page.last.id;
      if (page.length < _pageSize) break;
    }

    final result =
        MantelSyncResult(synced: synced, skipped: skipped, failed: failed);
    _log.info('Mantel sync complete: $result');
    return result;
  }
}
