import "package:shared_preferences/shared_preferences.dart";

class LanguageService {
  static const _key = "appearance.language"; // stores language code

  static Future<String?> load() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> save(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}
