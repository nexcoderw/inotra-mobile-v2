import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

class ThemeService {
  static const _key = "appearance.theme"; // values: light | dark

  static Future<ThemeMode> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    switch (raw) {
      case "dark":
        return ThemeMode.dark;
      case "light":
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  static Future<void> save(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.dark ? "dark" : "light";
    await prefs.setString(_key, value);
  }
}
