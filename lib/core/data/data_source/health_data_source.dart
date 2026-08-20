import 'package:health/health.dart';
import 'package:logging/logging.dart';

class HealthDataSource {
  final _log = Logger('HealthDataSource');
  final Health _health = Health();
  bool _configured = false;

  /// Energy and body weight are asked for together, because one permission
  /// dialog is kinder than two, but they are read apart on purpose: passing
  /// the combined list to the calorie read would fold every weigh-in into the
  /// day's active calories as if a kilogram were a kilocalorie. Keeping the
  /// two lists separate is what stops that, so they stay separate.
  static const List<HealthDataType> _energy = [
    HealthDataType.ACTIVE_ENERGY_BURNED,
  ];

  static const List<HealthDataType> _weight = [
    HealthDataType.WEIGHT,
  ];

  static const List<HealthDataType> _types = [..._energy, ..._weight];

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
        types: _energy,
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

  /// Every weigh-in Apple Health holds since [from], as one reading per day.
  ///
  /// A day with several weigh-ins on it — stepping on the scales twice, or a
  /// scale that reports as you shift your feet — comes back as the last one,
  /// because that is the reading a person would say was theirs for that day.
  /// Averaging them would invent a number nobody ever saw.
  ///
  /// Returns nothing rather than throwing when permission was never granted:
  /// there is no way on iOS to tell "you said no" from "there is nothing
  /// there", and treating the first as an error would put a warning in front
  /// of somebody who simply does not use a smart scale.
  Future<Map<DateTime, double>> weightsSince(DateTime from) async {
    try {
      await _ensureConfigured();
      final samples = await _health.getHealthDataFromTypes(
        types: _weight,
        startTime: from,
        endTime: DateTime.now(),
      );
      final byDay = <DateTime, double>{};
      final at = <DateTime, DateTime>{};
      for (final s in samples) {
        if (s.value is! NumericHealthValue) continue;
        final when = s.dateTo;
        final day = DateTime(when.year, when.month, when.day);
        if (at[day] != null && at[day]!.isAfter(when)) continue;
        at[day] = when;
        byDay[day] = (s.value as NumericHealthValue).numericValue.toDouble();
      }
      _log.fine('Weights since $from: ${byDay.length} day(s)');
      return byDay;
    } catch (e) {
      _log.warning('Error reading weights from HealthKit', e);
      return const {};
    }
  }
}
