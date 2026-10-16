import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Default testnet base URL from the LNbits integration guide.
/// Plain HTTP and not hardened yet — always keep this configurable so a
/// hardened (HTTPS) URL can be adopted without an app update.
const String defaultLnbitsBaseUrl = 'http://163.245.193.102:5000';

/// Persists the LNbits wallet credentials and server configuration.
///
/// The inkey/adminkey pair IS the wallet identity: it lives in secure
/// storage and is never logged or hardcoded. Wallet creation itself is an
/// admin operation and is intentionally not exposed here.
class LnbitsStorage {
  static const _secure = FlutterSecureStorage();
  static const _inkeyKey = 'lnbits_inkey';
  static const _adminkeyKey = 'lnbits_adminkey';
  static const _baseUrlKey = 'lnbits_base_url';

  static Future<bool> hasKeys() async {
    final inkey = await _secure.read(key: _inkeyKey);
    return inkey != null && inkey.isNotEmpty;
  }

  static Future<({String inkey, String adminkey})?> readKeys() async {
    final inkey = await _secure.read(key: _inkeyKey);
    if (inkey == null || inkey.isEmpty) return null;
    final adminkey = await _secure.read(key: _adminkeyKey) ?? '';
    return (inkey: inkey, adminkey: adminkey);
  }

  static Future<void> saveKeys(String inkey, String adminkey) async {
    await _secure.write(key: _inkeyKey, value: inkey.trim());
    await _secure.write(key: _adminkeyKey, value: adminkey.trim());
  }

  static Future<void> clearKeys() async {
    await _secure.delete(key: _inkeyKey);
    await _secure.delete(key: _adminkeyKey);
  }

  /// Returns the configured base URL, normalized with a scheme.
  /// A saved URL without a scheme fails silently against the API, so one is
  /// always ensured here.
  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    var url = (prefs.getString(_baseUrlKey) ?? defaultLnbitsBaseUrl).trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    return url;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, url.trim());
  }
}
