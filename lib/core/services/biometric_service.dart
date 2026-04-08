import "dart:convert";
import "dart:io" show Platform;

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:http/http.dart" as http;
import "package:local_auth/error_codes.dart" as auth_error;
import "package:local_auth/local_auth.dart";

import "../config/api.dart";
import "../constants/api/auth_endpoints.dart";
import "device_info_service.dart";

/// Manages biometric authentication and secure session storage.
///
/// Instead of storing a raw password, the app keeps a refreshable session
/// snapshot in secure storage. A successful biometric prompt unlocks that
/// snapshot and exchanges the refresh token for a fresh authenticated session.
class BiometricService {
  BiometricService._();

  static final instance = BiometricService._();

  static const _keySession = "bio.session";

  final _auth = LocalAuthentication();
  final ValueNotifier<int> _revision = ValueNotifier(0);

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  ValueListenable<int> get changes => _revision;

  // ---------------------------------------------------------------------------
  // Availability
  // ---------------------------------------------------------------------------

  Future<bool> isAvailable() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;
      final enrolled = await _auth.getAvailableBiometrics();
      return enrolled.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> isEnabled() async {
    final session = await getSession();
    return session != null;
  }

  Future<BiometricPresentationKind> getPresentationKind() async {
    try {
      final enrolled = await _auth.getAvailableBiometrics();
      if (enrolled.contains(BiometricType.face)) {
        return BiometricPresentationKind.faceId;
      }
      if (enrolled.contains(BiometricType.fingerprint)) {
        if (!kIsWeb && Platform.isIOS) {
          return BiometricPresentationKind.touchId;
        }
        return BiometricPresentationKind.fingerprint;
      }
      if (enrolled.isNotEmpty) {
        return BiometricPresentationKind.biometrics;
      }
    } catch (_) {}

    if (!kIsWeb && Platform.isIOS) {
      return BiometricPresentationKind.faceId;
    }
    return BiometricPresentationKind.biometrics;
  }

  Future<BiometricStatusSnapshot> getStatus() async {
    final available = await isAvailable();
    final enabled = available && await isEnabled();
    final presentation = await getPresentationKind();
    return BiometricStatusSnapshot(
      available: available,
      enabled: enabled,
      presentation: presentation,
    );
  }

  // ---------------------------------------------------------------------------
  // Secure biometric session
  // ---------------------------------------------------------------------------

  Future<void> saveSession({
    required String refreshToken,
    required Map<String, dynamic> user,
    String theme = "light",
  }) async {
    if (refreshToken.trim().isEmpty || user.isEmpty) {
      await clear();
      return;
    }

    final payload = jsonEncode({
      "refresh": refreshToken,
      "user": user,
      "theme": theme,
    });

    await _storage.write(key: _keySession, value: payload);
    _notifyChanged();
  }

  Future<BiometricStoredSession?> getSession() async {
    try {
      final raw = await _storage.read(key: _keySession);
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;

      final refresh = (decoded["refresh"] ?? "").toString().trim();
      final user = decoded["user"];
      if (refresh.isEmpty || user is! Map) return null;

      return BiometricStoredSession(
        refreshToken: refresh,
        user: Map<String, dynamic>.from(user),
        theme: (decoded["theme"] ?? "light").toString(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> updateSession({
    required String refreshToken,
    Map<String, dynamic>? user,
    String? theme,
  }) async {
    final existing = await getSession();
    if (existing == null) return;

    await saveSession(
      refreshToken: refreshToken,
      user: user ?? existing.user,
      theme: theme ?? existing.theme,
    );
  }

  Future<void> clear() async {
    await _storage.delete(key: _keySession);
    _notifyChanged();
  }

  Future<BiometricUnlockResult> unlockSession() async {
    final stored = await getSession();
    if (stored == null) {
      return const BiometricUnlockResult(
        status: BiometricUnlockStatus.notConfigured,
      );
    }

    try {
      final refreshResponse = await http
          .post(
            Api.url(AuthEndpoints.tokenRefresh),
            headers: {
              "Content-Type": "application/json",
              ...DeviceInfoService.instance.asHeader,
            },
            body: jsonEncode({"refresh": stored.refreshToken}),
          )
          .timeout(const Duration(seconds: 12));

      if (refreshResponse.statusCode == 401 ||
          refreshResponse.statusCode == 403 ||
          refreshResponse.statusCode == 400) {
        await clear();
        return const BiometricUnlockResult(
          status: BiometricUnlockStatus.sessionExpired,
        );
      }

      if (refreshResponse.statusCode < 200 ||
          refreshResponse.statusCode >= 300) {
        return const BiometricUnlockResult(
          status: BiometricUnlockStatus.networkError,
        );
      }

      final decoded = jsonDecode(refreshResponse.body);
      if (decoded is! Map<String, dynamic>) {
        await clear();
        return const BiometricUnlockResult(
          status: BiometricUnlockStatus.sessionExpired,
        );
      }

      final accessToken = (decoded["access"] ?? "").toString().trim();
      final refreshToken = (decoded["refresh"] ?? stored.refreshToken)
          .toString()
          .trim();

      if (accessToken.isEmpty || refreshToken.isEmpty) {
        await clear();
        return const BiometricUnlockResult(
          status: BiometricUnlockStatus.sessionExpired,
        );
      }

      final user = await _fetchCurrentUser(accessToken) ?? stored.user;
      await saveSession(
        refreshToken: refreshToken,
        user: user,
        theme: stored.theme,
      );

      return BiometricUnlockResult(
        status: BiometricUnlockStatus.success,
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
        theme: stored.theme,
      );
    } on PlatformException {
      return const BiometricUnlockResult(
        status: BiometricUnlockStatus.unknownError,
      );
    } catch (_) {
      return const BiometricUnlockResult(
        status: BiometricUnlockStatus.networkError,
      );
    }
  }

  void _notifyChanged() {
    _revision.value++;
  }

  Future<Map<String, dynamic>?> _fetchCurrentUser(String accessToken) async {
    try {
      final response = await http
          .get(
            Api.url(AuthEndpoints.me),
            headers: {
              "Authorization": "Bearer $accessToken",
              ...DeviceInfoService.instance.asHeader,
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) return null;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;

      final nestedUser = decoded["user"];
      if (nestedUser is Map) {
        return Map<String, dynamic>.from(nestedUser);
      }
      return decoded;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Authentication prompt
  // ---------------------------------------------------------------------------

  Future<bool> authenticate() async {
    final result = await authenticateWithResult();
    return result.isAuthenticated;
  }

  Future<BiometricAuthResult> authenticateWithResult() async {
    try {
      final authenticated = await _auth.authenticate(
        localizedReason: "Sign in to Inotra",
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
      return BiometricAuthResult(
        isAuthenticated: authenticated,
        message: authenticated ? null : "Biometric sign-in was cancelled.",
        shouldShowMessage: false,
      );
    } on PlatformException catch (error) {
      return _mapPlatformException(error);
    } catch (_) {
      return const BiometricAuthResult(
        isAuthenticated: false,
        message:
            "Biometric sign-in is currently unavailable. Please use your password and try again later.",
      );
    }
  }

  BiometricAuthResult _mapPlatformException(PlatformException error) {
    switch (error.code) {
      case auth_error.notAvailable:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message: "This device does not support biometric sign-in.",
        );
      case auth_error.notEnrolled:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message: "No biometric profile is enrolled on this device yet.",
        );
      case auth_error.passcodeNotSet:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message:
              "Set a device passcode first, then enable biometrics and try again.",
        );
      case auth_error.lockedOut:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message:
              "Biometric sign-in is temporarily locked. Unlock your device, then try again.",
        );
      case auth_error.permanentlyLockedOut:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message:
              "Biometric sign-in is locked. Unlock your device with your passcode, then try again.",
        );
      default:
        return BiometricAuthResult(
          isAuthenticated: false,
          message: error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : "Biometric sign-in is currently unavailable. Please use your password and try again.",
        );
    }
  }
}

class BiometricStoredSession {
  final String refreshToken;
  final Map<String, dynamic> user;
  final String theme;

  const BiometricStoredSession({
    required this.refreshToken,
    required this.user,
    required this.theme,
  });
}

class BiometricStatusSnapshot {
  final bool available;
  final bool enabled;
  final BiometricPresentationKind presentation;

  const BiometricStatusSnapshot({
    required this.available,
    required this.enabled,
    required this.presentation,
  });
}

enum BiometricPresentationKind { faceId, touchId, fingerprint, biometrics }

enum BiometricUnlockStatus {
  success,
  notConfigured,
  sessionExpired,
  networkError,
  unknownError,
}

class BiometricUnlockResult {
  final BiometricUnlockStatus status;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? theme;

  const BiometricUnlockResult({
    required this.status,
    this.accessToken,
    this.refreshToken,
    this.user,
    this.theme,
  });

  bool get isSuccess => status == BiometricUnlockStatus.success;
}

class BiometricAuthResult {
  final bool isAuthenticated;
  final String? message;
  final bool shouldShowMessage;

  const BiometricAuthResult({
    required this.isAuthenticated,
    this.message,
    this.shouldShowMessage = true,
  });
}
