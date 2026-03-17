import "dart:io" show Platform;

import "package:device_info_plus/device_info_plus.dart";
import "package:flutter/foundation.dart" show kIsWeb;

/// Resolves and caches the physical device name so that API requests can
/// include it via the ``X-Device-Name`` header.
///
/// Examples of resolved names:
/// - iOS:     "John's iPhone"  (the user-set device name)
/// - Android: "Samsung Galaxy S24 Ultra"
/// - macOS:   "MacBook Pro"
/// - Windows: "DESKTOP-ABC123"
/// - Web:     "chrome"
///
/// Call [initialize] once at app startup before any authenticated requests
/// are made.  All subsequent reads via [deviceName] are synchronous.
class DeviceInfoService {
  DeviceInfoService._();

  static final DeviceInfoService instance = DeviceInfoService._();

  String? _deviceName;

  /// Initialise the service.  Safe to call multiple times; subsequent calls
  /// are no-ops once a name has been resolved.
  Future<void> initialize() async {
    if (_deviceName != null) return;

    try {
      final plugin = DeviceInfoPlugin();

      if (kIsWeb) {
        final info = await plugin.webBrowserInfo;
        _deviceName = info.browserName.name;
      } else if (Platform.isIOS) {
        final info = await plugin.iosInfo;
        // name = user-set device name, e.g. "John's iPhone"
        _deviceName = info.name.isNotEmpty ? info.name : info.model;
      } else if (Platform.isAndroid) {
        final info  = await plugin.androidInfo;
        final brand = info.brand.trim();
        final model = info.model.trim();
        // Avoid showing raw identifiers like "SAMSUNG SM-G998B"; prefer
        // the user-facing model string which Android exposes.
        final name  = [brand, model].where((s) => s.isNotEmpty).join(" ");
        _deviceName = name.isNotEmpty ? name : "Android Device";
      } else if (Platform.isMacOS) {
        final info  = await plugin.macOsInfo;
        _deviceName = info.computerName.isNotEmpty
            ? info.computerName
            : info.model.isNotEmpty
                ? info.model
                : "Mac";
      } else if (Platform.isWindows) {
        final info  = await plugin.windowsInfo;
        _deviceName = info.computerName.isNotEmpty
            ? info.computerName
            : "Windows PC";
      } else if (Platform.isLinux) {
        final info  = await plugin.linuxInfo;
        _deviceName = info.prettyName.isNotEmpty ? info.prettyName : "Linux PC";
      }
    } catch (_) {
      // Silently ignore — device name is best-effort and never required.
      _deviceName = null;
    }
  }

  /// Human-readable device name, or an empty string if not resolved.
  String get deviceName => _deviceName ?? "";

  /// Whether a device name has been resolved.
  bool get hasDeviceName => _deviceName != null && _deviceName!.isNotEmpty;

  /// Returns the X-Device-Name header map if a name is available, otherwise
  /// an empty map.  Merge this into your request headers:
  ///
  /// ```dart
  /// headers: {
  ///   "Content-Type": "application/json",
  ///   ...DeviceInfoService.instance.asHeader,
  /// }
  /// ```
  Map<String, String> get asHeader =>
      hasDeviceName ? {"X-Device-Name": deviceName} : const {};
}
