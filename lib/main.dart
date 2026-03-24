import "package:firebase_core/firebase_core.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

import "app.dart";
import "core/config/env.dart";
import "core/services/auth_session.dart";
import "core/services/device_info_service.dart";
import "core/services/local_notification_service.dart";
import "core/services/notification_service.dart";
import "core/services/session_heartbeat_service.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  // Firebase is only used for analytics. Do not block app startup on web
  // while Firebase web options are still not provisioned for this project.
  await _initializeFirebase();

  // Resolve the device name once so every request can include X-Device-Name.
  await DeviceInfoService.instance.initialize();

  // Initialise local notification plugin (creates Android channel, requests
  // permission on Android 13+ and iOS).
  await LocalNotificationService.instance.initialize();

  // Restore any persisted session from SharedPreferences.
  await AuthSession.instance.restore();

  if (AuthSession.instance.value.isAuthenticated) {
    // Resume the heartbeat so the server session stays active after a restart.
    SessionHeartbeatService.instance.start();

    // Load cached notifications immediately so the badge is visible before
    // the API fetch completes.
    await NotificationService.instance.load();

    // Sync from the server — shows banners for any new notifications found.
    // Also starts the 30-second poll + app-resume listener.
    NotificationService.instance.fetch();
    NotificationService.instance.startPolling();
  }

  // Listen for future sign-in / sign-out to activate or clear notifications.
  AuthSession.instance.addListener(_onAuthChange);

  runApp(const App());
}

Future<void> _initializeFirebase() async {
  try {
    if (kIsWeb) {
      debugPrint(
        "Skipping Firebase initialization on web because FirebaseOptions are not configured yet.",
      );
      return;
    }

    await Firebase.initializeApp();
  } catch (error, stackTrace) {
    debugPrint("Firebase initialization skipped: $error");
    debugPrintStack(stackTrace: stackTrace);
  }
}

void _onAuthChange() {
  if (AuthSession.instance.value.isAuthenticated) {
    NotificationService.instance.load().then((_) {
      NotificationService.instance.fetch();
      NotificationService.instance.startPolling();
    });
  } else {
    NotificationService.instance.clear();
  }
}
