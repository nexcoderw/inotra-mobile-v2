import "package:firebase_core/firebase_core.dart";
import "package:flutter/material.dart";

import "app.dart";
import "core/config/env.dart";
import "core/services/auth_session.dart";
import "core/services/device_info_service.dart";
import "core/services/fcm_service.dart";
import "core/services/notification_service.dart";
import "core/services/session_heartbeat_service.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  // Firebase must be initialised before any Firebase service is used.
  await Firebase.initializeApp();

  // Resolve the device name once so every request can include X-Device-Name.
  await DeviceInfoService.instance.initialize();

  // Restore any persisted session from SharedPreferences.
  await AuthSession.instance.restore();

  if (AuthSession.instance.value.isAuthenticated) {
    // Resume the heartbeat so the server session stays active after a restart.
    SessionHeartbeatService.instance.start();

    // Initialise FCM (requests permission, registers token, hooks up listeners).
    // Wrapped in try-catch — FCM failure must never prevent the app from launching.
    try {
      await FCMService.instance.initialize();
    } catch (_) {}

    // Pre-fetch notifications so the badge is ready on first render.
    NotificationService.instance.fetch();
  }

  // Listen for future sign-in to activate FCM + fetch notifications.
  AuthSession.instance.addListener(_onAuthChange);

  runApp(const App());
}

void _onAuthChange() {
  if (AuthSession.instance.value.isAuthenticated) {
    FCMService.instance.initialize().catchError((_) {});
    NotificationService.instance.fetch();
  } else {
    FCMService.instance.deregisterToken();
    NotificationService.instance.clear();
  }
}
