import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter/services.dart";
import "package:local_auth/error_codes.dart" as auth_error;
import "package:local_auth/local_auth.dart";

/// Manages biometric authentication and secure credential storage.
///
/// Credentials are stored in encrypted storage (Android Keystore /
/// iOS Secure Enclave) and only retrieved after a successful biometric
/// or device-credential challenge.
class BiometricService {
  BiometricService._();

  static final instance = BiometricService._();

  static const _keyIdentifier = "bio_identifier";
  static const _keyPassword = "bio_password";

  final _auth = LocalAuthentication();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // ---------------------------------------------------------------------------
  // Availability
  // ---------------------------------------------------------------------------

  /// Returns true when the device hardware supports biometrics (or PIN/pattern
  /// as fallback) and at least one biometric is enrolled.
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

  /// Returns true when valid credentials have previously been saved, meaning
  /// the user has completed at least one successful normal login.
  Future<bool> isEnabled() async {
    try {
      final id = await _storage.read(key: _keyIdentifier);
      final pw = await _storage.read(key: _keyPassword);
      return id != null && id.isNotEmpty && pw != null && pw.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Credentials
  // ---------------------------------------------------------------------------

  /// Persists [identifier] and [password] to encrypted storage.
  /// Call this only after a confirmed successful login response (2xx).
  Future<void> saveCredentials({
    required String identifier,
    required String password,
  }) async {
    await _storage.write(key: _keyIdentifier, value: identifier);
    await _storage.write(key: _keyPassword, value: password);
  }

  /// Returns the stored credentials, or null if none have been saved yet.
  Future<({String identifier, String password})?> getCredentials() async {
    try {
      final id = await _storage.read(key: _keyIdentifier);
      final pw = await _storage.read(key: _keyPassword);
      if (id == null || id.isEmpty || pw == null || pw.isEmpty) return null;
      return (identifier: id, password: pw);
    } catch (_) {
      return null;
    }
  }

  /// Deletes all saved credentials from encrypted storage.
  Future<void> clear() async {
    await _storage.delete(key: _keyIdentifier);
    await _storage.delete(key: _keyPassword);
  }

  // ---------------------------------------------------------------------------
  // Authentication
  // ---------------------------------------------------------------------------

  /// Presents the native biometric / device-credential prompt.
  ///
  /// * [stickyAuth] keeps the prompt alive when the app loses focus (e.g.
  ///   when Face ID shows its system overlay).
  /// * [biometricOnly] = false allows PIN/pattern fallback so the user is
  ///   never locked out on devices where face data isn't enrolled.
  ///
  /// Returns true if the user was successfully authenticated.
  Future<bool> authenticate() async {
    final result = await authenticateWithResult();
    return result.isAuthenticated;
  }

  /// Returns the biometric prompt outcome together with a user-facing message
  /// when the failure was actionable.
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
            "Face ID is currently unavailable. Please use your password and try again later.",
      );
    }
  }

  BiometricAuthResult _mapPlatformException(PlatformException error) {
    switch (error.code) {
      case auth_error.notAvailable:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message: "This device does not support Face ID or biometric sign-in.",
        );
      case auth_error.notEnrolled:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message:
              "No Face ID or biometric profile is enrolled on this device yet.",
        );
      case auth_error.passcodeNotSet:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message:
              "Set a device passcode first, then enable Face ID and try again.",
        );
      case auth_error.lockedOut:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message:
              "Face ID is temporarily locked. Unlock your device, then try again.",
        );
      case auth_error.permanentlyLockedOut:
        return const BiometricAuthResult(
          isAuthenticated: false,
          message:
              "Face ID is locked. Unlock your device with your passcode, then try again.",
        );
      default:
        return BiometricAuthResult(
          isAuthenticated: false,
          message: error.message?.trim().isNotEmpty == true
              ? error.message!.trim()
              : "Face ID is currently unavailable. Please use your password and try again.",
        );
    }
  }
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
