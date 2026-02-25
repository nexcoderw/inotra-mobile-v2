import "package:flutter/material.dart";

import "core/config/env.dart";
import "app.dart";
import "core/services/auth_session.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  await AuthSession.instance.restore();
  runApp(const App());
}
