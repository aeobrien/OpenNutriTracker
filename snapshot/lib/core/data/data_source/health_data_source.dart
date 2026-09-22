import 'package:health/health.dart';
import 'package:logging/logging.dart';

class HealthDataSource {
  final _log = Logger('HealthDataSource');
  final Health _health = Health();
  bool _configured = false;

  static const List<HealthDataType> _types = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  Future<void> _ensureConfigured() async {
    if (!_configured) {
      await _health.configure();
      _configured = true;
    }
  }

  Future<bool> requestPermission() async {
    try {
      await _ensureConfigured();
      final result = await _health.requestAuthorization(
        _types,
        permissions: [HealthDataAccess.READ],
      );
      _log.fine('HealthKit permission request result: $result');
      // On iOS, result=true just means the dialog was shown without error.
      // We can't know if the user actually granted READ permission.
      // So we store that we asked, and later just try to read data.
      return result;
    } catch (e) {
      _log.warning('Error requesting HealthKit permission', e);
      return false;
    }
  }

  /// On iOS, hasPermissions for READ always returns null (privacy restriction).
  /// We return true if we successfully requested before, and rely on
  /// getActiveCaloriesToday returning 0 if denied.
  Future<bool> hasPermission() async {
    try {
      await _ensureConfigured();
      final result = await _health.hasPermissions(
        _types,
        permissions: [HealthDataAccess.READ],
      );
      // null means undetermined on iOS for READ — treat as true if we asked
      return result ?? true;
    } catch (e) {
      _log.warning('Error checking HealthKit permission', e);
      return false;
    }
  }

  Future<double> getActiveCaloriesToday() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);
      // getHealthDataFromTypes already calls removeDuplicates internally
      final dataPoints = await _health.getHealthDataFromTypes(
        types: _types,
        startTime: midnight,
        endTime: now,
      );
      double total = 0.0;
      for (final dp in dataPoints) {
        if (dp.value is NumericHealthValue) {
          total += (dp.value as NumericHealthValue).numericValue.toDouble();
        }
      }
      _log.fine('Active calories today: $total (${dataPoints.length} samples)');
      return total;
    } catch (e) {
      _log.warning('Error reading active calories from HealthKit', e);
      return 0.0;
    }
  }
}
