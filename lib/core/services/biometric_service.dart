import "package:flutter_secure_storage/flutter_secure_storage.dart";
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
    try {
      return await _auth.authenticate(
        localizedReason: "Sign in to Inotra",
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
