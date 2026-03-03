import "package:flutter_dotenv/flutter_dotenv.dart";

final class Env {
  Env._();

  static const _baseUrlKey = "INOTRA_API_BASE_URL";

  // Old (keep for backward compatibility)
  static const _googleClientIdKey = "GOOGLE_CLIENT_ID";

  // New (recommended)
  static const _googleWebClientIdKey = "GOOGLE_WEB_CLIENT_ID";
  static const _googleServerClientIdKey = "GOOGLE_SERVER_CLIENT_ID";

  static const _googleMapKey = "GOOGLE_MAP_API_KEY";

  /// Call once before runApp()
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  /// Example: https://api.inotra.rw/
  static String get baseUrl {
    final raw = dotenv.env[_baseUrlKey];
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_baseUrlKey in .env");
    }
    return _ensureTrailingSlash(raw.trim());
  }

  /// ✅ Web OAuth client id (Type: Web application)
  /// Falls back to GOOGLE_CLIENT_ID if you didn't add GOOGLE_WEB_CLIENT_ID yet.
  static String get googleWebClientId {
    final raw = (dotenv.env[_googleWebClientIdKey] ?? dotenv.env[_googleClientIdKey]);
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_googleWebClientIdKey (or $_googleClientIdKey) in .env");
    }
    return raw.trim();
  }

  /// ✅ Used on Android/iOS to obtain idToken for backend
  /// Usually same as googleWebClientId.
  static String get googleServerClientId {
    final raw = (dotenv.env[_googleServerClientIdKey] ?? dotenv.env[_googleClientIdKey]);
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_googleServerClientIdKey (or $_googleClientIdKey) in .env");
    }
    return raw.trim();
  }

  /// Old getter (kept so your current code doesn't break)
  static String get googleClientId {
    final raw = dotenv.env[_googleClientIdKey];
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_googleClientIdKey in .env");
    }
    return raw.trim();
  }

  static String get googleMapApiKey {
    final raw = dotenv.env[_googleMapKey];
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_googleMapKey in .env");
    }
    return raw.trim();
  }

  static String _ensureTrailingSlash(String v) => v.endsWith("/") ? v : "$v/";
}