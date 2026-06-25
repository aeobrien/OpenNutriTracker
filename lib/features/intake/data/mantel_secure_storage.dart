import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';

/// Secure storage for the Mantel meal-sync connection details, sitting beside
/// the existing Mealie/Claude/OpenAI storage. Kept as an extension so the
/// integration is fully additive — it reuses the already-configured
/// [FlutterSecureStorage] via [SecureAppStorageProvider.secureAppStorage] and
/// does not modify the provider class.
///
/// Three values: the Mantel base URL (the Tailscale host, same one Mealie uses
/// but on Mantel's port), the `actor` whose meals to pull, and an optional
/// per-actor `X-Intake-Token` (only needed if Mantel has a token set for that
/// actor; on the tailnet it can be blank).
extension MantelSecureStorage on SecureAppStorageProvider {
  static const _baseUrlTag = 'MantelBaseUrl';
  static const _actorTag = 'MantelActor';
  static const _tokenTag = 'MantelIntakeToken';

  Future<String?> getMantelBaseUrl() async {
    return SecureAppStorageProvider.secureAppStorage.read(key: _baseUrlTag);
  }

  Future<void> setMantelBaseUrl(String value) async {
    await SecureAppStorageProvider.secureAppStorage
        .write(key: _baseUrlTag, value: value);
  }

  Future<String?> getMantelActor() async {
    return SecureAppStorageProvider.secureAppStorage.read(key: _actorTag);
  }

  Future<void> setMantelActor(String value) async {
    await SecureAppStorageProvider.secureAppStorage
        .write(key: _actorTag, value: value);
  }

  Future<String?> getMantelIntakeToken() async {
    return SecureAppStorageProvider.secureAppStorage.read(key: _tokenTag);
  }

  Future<void> setMantelIntakeToken(String value) async {
    await SecureAppStorageProvider.secureAppStorage
        .write(key: _tokenTag, value: value);
  }

  /// A base URL + actor are the minimum to sync. The token is optional.
  Future<bool> hasMantelConfig() async {
    final url = await getMantelBaseUrl();
    final actor = await getMantelActor();
    return (url?.isNotEmpty ?? false) && (actor?.isNotEmpty ?? false);
  }

  Future<void> deleteMantelConfig() async {
    await SecureAppStorageProvider.secureAppStorage.delete(key: _baseUrlTag);
    await SecureAppStorageProvider.secureAppStorage.delete(key: _actorTag);
    await SecureAppStorageProvider.secureAppStorage.delete(key: _tokenTag);
  }
}
