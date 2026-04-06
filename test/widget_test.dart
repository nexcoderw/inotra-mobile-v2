import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:inotra/core/services/theme_notifier.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("ThemeNotifier loads light mode by default", () async {
    SharedPreferences.setMockInitialValues(const {});
    final notifier = ThemeNotifier();

    await notifier.load();

    expect(notifier.initialized, isTrue);
    expect(notifier.mode, ThemeMode.light);
  });

  test("ThemeNotifier respects a persisted dark mode", () async {
    SharedPreferences.setMockInitialValues(const {"appearance.theme": "dark"});
    final notifier = ThemeNotifier();

    await notifier.load();

    expect(notifier.initialized, isTrue);
    expect(notifier.mode, ThemeMode.dark);
  });
}
