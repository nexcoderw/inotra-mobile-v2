import "package:flutter_dotenv/flutter_dotenv.dart";
import "package:flutter/foundation.dart";

final class Env {
  Env._();

  static const _baseUrlKey = "INOTRA_API_BASE_URL";
  static const _androidBaseUrlKey = "INOTRA_API_ANDROID_BASE_URL";
  static const _iosBaseUrlKey = "INOTRA_API_IOS_BASE_URL";
  static const _webBaseUrlKey = "INOTRA_API_WEB_BASE_URL";
  static const _googleClientIdKey = "GOOGLE_CLIENT_ID";
  static const _googleMapApiKeyKey = "GOOGLE_MAP_API_KEY";

  /// Call once before runApp()
  static Future<void> load() async {
    await dotenv.load(fileName: ".env");
  }

  /// Example: https://api.inotra.rw/
  ///
  /// Development note:
  /// - Android emulators cannot reach a host machine through 127.0.0.1.
  ///   When the shared base URL is localhost/127.0.0.1, this getter maps it
  ///   to 10.0.2.2 for Android emulator builds.
  /// - Physical devices still need a LAN or production URL in .env, because
  ///   neither 127.0.0.1 nor 10.0.2.2 points to the developer machine there.
  static String get baseUrl {
    final raw = _platformBaseUrlOverride ?? dotenv.env[_baseUrlKey];
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_baseUrlKey in .env");
    }
    return _ensureTrailingSlash(_resolveLocalhostBaseUrl(raw.trim()));
  }

  static String get googleClientId {
    final raw = dotenv.env[_googleClientIdKey];
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_googleClientIdKey in .env");
    }
    return raw.trim();
  }

  static String get googleMapApiKey {
    final raw = dotenv.env[_googleMapApiKeyKey];
    if (raw == null || raw.trim().isEmpty) {
      throw StateError("Missing $_googleMapApiKeyKey in .env");
    }
    return raw.trim();
  }

  static String? get _platformBaseUrlOverride {
    if (kIsWeb) return _nonEmptyEnv(_webBaseUrlKey);

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => _nonEmptyEnv(_androidBaseUrlKey),
      TargetPlatform.iOS => _nonEmptyEnv(_iosBaseUrlKey),
      _ => null,
    };
  }

  static String? _nonEmptyEnv(String key) {
    final raw = dotenv.env[key]?.trim();
    if (raw == null || raw.isEmpty) return null;
    return raw;
  }

  static String _resolveLocalhostBaseUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return value;
    if (!_isLocalhost(uri.host)) return value;
    if (kIsWeb) return value;

    return switch (defaultTargetPlatform) {
      TargetPlatform.android => uri.replace(host: "10.0.2.2").toString(),
      _ => value,
    };
  }

  static bool _isLocalhost(String host) {
    final normalized = host.toLowerCase();
    return normalized == "localhost" ||
        normalized == "127.0.0.1" ||
        normalized == "0.0.0.0" ||
        normalized == "::1";
  }

  static String _ensureTrailingSlash(String v) => v.endsWith("/") ? v : "$v/";
}
