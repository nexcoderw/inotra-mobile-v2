import "package:flutter/material.dart";

import "theme_service.dart";

class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;
  bool _initialized = false;

  ThemeMode get mode => _mode;
  bool get initialized => _initialized;

  Future<void> load() async {
    _mode = await ThemeService.load();
    _initialized = true;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    await ThemeService.save(mode);
  }
}
