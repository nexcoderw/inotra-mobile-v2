import "package:flutter_dotenv/flutter_dotenv.dart";

final class Env {
  Env._();

  static const _baseUrlKey = "INOTRA_API_BASE_URL";
  static const _googleClientIdKey = "GOOGLE_CLIENT_ID";

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

  static String get googleClientId {
    final raw = dotenv.env[_googleClientIdKey];
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_googleClientIdKey in .env");
    }
    return raw.trim();
  }

  static String _ensureTrailingSlash(String v) => v.endsWith("/") ? v : "$v/";
}
