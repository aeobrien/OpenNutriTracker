/// Thrown when a label-scan extraction fails because the device appears to be
/// offline (no network reachable). Distinct from API/parse errors so the BLoC
/// can queue the photo for later processing rather than surfacing an error.
class LabelScanOfflineException implements Exception {
  final String message;
  const LabelScanOfflineException([this.message = 'No network connection']);

  @override
  String toString() => 'LabelScanOfflineException: $message';
}
