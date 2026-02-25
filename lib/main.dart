import "package:flutter/material.dart";

import "core/config/env.dart";
import "app.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Env.load();
  runApp(const App());
}