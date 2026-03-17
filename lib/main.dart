import "package:flutter/material.dart";

import "core/config/env.dart";
import "app.dart";
import "core/services/auth_session.dart";
import "core/services/device_info_service.dart";
import "core/services/session_heartbeat_service.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();

  // Resolve the device name once so every request can include X-Device-Name.
  await DeviceInfoService.instance.initialize();

  // Restore any persisted session from SharedPreferences.
  await AuthSession.instance.restore();

  // If a session was restored, resume the heartbeat immediately so the server
  // session stays active even after an app restart.
  if (AuthSession.instance.value.isAuthenticated) {
    SessionHeartbeatService.instance.start();
  }

  runApp(const App());
}
