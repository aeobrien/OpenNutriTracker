import 'package:opennutritracker/core/utils/secure_app_storage_provider.dart';

/// Secure storage for the Mealie server connection details, sitting beside the
/// existing Claude/OpenAI key storage. Kept as an extension so the integration
/// is fully additive — it reuses the already-configured [FlutterSecureStorage]
/// via the public `SecureAppStorageProvider.secureAppStorage` instance and does
/// not modify the provider class.
extension MealieSecureStorage on SecureAppStorageProvider {
  static const _baseUrlTag = 'MealieBaseUrl';
  static const _tokenTag = 'MealieToken';

  Future<String?> getMealieBaseUrl() async {
    return SecureAppStorageProvider.secureAppStorage.read(key: _baseUrlTag);
  }

  Future<void> setMealieBaseUrl(String value) async {
    await SecureAppStorageProvider.secureAppStorage
        .write(key: _baseUrlTag, value: value);
  }

  Future<String?> getMealieToken() async {
    return SecureAppStorageProvider.secureAppStorage.read(key: _tokenTag);
  }

  Future<void> setMealieToken(String value) async {
    await SecureAppStorageProvider.secureAppStorage
        .write(key: _tokenTag, value: value);
  }

  Future<bool> hasMealieConfig() async {
    final url = await getMealieBaseUrl();
    final token = await getMealieToken();
    return (url?.isNotEmpty ?? false) && (token?.isNotEmpty ?? false);
  }

  Future<void> deleteMealieConfig() async {
    await SecureAppStorageProvider.secureAppStorage.delete(key: _baseUrlTag);
    await SecureAppStorageProvider.secureAppStorage.delete(key: _tokenTag);
  }
}
