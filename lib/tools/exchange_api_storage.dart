import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists Qutrade exchange API credentials for private endpoints.
///
/// The API key / secret pair enables authenticated requests (order
/// placement, balance checks) for future Buy/Swap features. Keys live in
/// secure storage and are never logged. Only a masked hint is ever shown
/// in the UI.
class ExchangeApiStorage {
  static const _secure = FlutterSecureStorage();
  static const _apiKeyKey = 'qutrade_api_key';
  static const _secretKeyKey = 'qutrade_api_secret';

  static Future<bool> hasKeys() async {
    final key = await _secure.read(key: _apiKeyKey);
    return key != null && key.isNotEmpty;
  }

  /// Returns the API key and a masked hint (last 4 chars), never the secret.
  static Future<({String apiKey, String hint})?> readKeyHint() async {
    final key = await _secure.read(key: _apiKeyKey);
    if (key == null || key.isEmpty) return null;
    final hint = key.length > 4 ? '••••${key.substring(key.length - 4)}' : '••••';
    return (apiKey: key, hint: hint);
  }

  static Future<String?> readSecret() async {
    return _secure.read(key: _secretKeyKey);
  }

  static Future<void> saveKeys(String apiKey, String secret) async {
    await _secure.write(key: _apiKeyKey, value: apiKey.trim());
    await _secure.write(key: _secretKeyKey, value: secret.trim());
  }

  static Future<void> clearKeys() async {
    await _secure.delete(key: _apiKeyKey);
    await _secure.delete(key: _secretKeyKey);
  }
}
