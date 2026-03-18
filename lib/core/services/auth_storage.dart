import "dart:convert";

import "package:shared_preferences/shared_preferences.dart";

class AuthStorage {
  static const _kTokens = "auth.tokens";
  static const _kUser = "auth.user";
  static const _kTheme = "auth.theme";

  const AuthStorage._();

  static Future<void> saveSession({
    required Map<String, dynamic> tokens,
    required Map<String, dynamic> user,
    String theme = "light",
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kTokens, jsonEncode(tokens));
    await prefs.setString(_kUser, jsonEncode(user));
    await prefs.setString(_kTheme, theme);
  }

  static Future<AuthStoredSession?> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final tokensRaw = prefs.getString(_kTokens);
    final userRaw = prefs.getString(_kUser);
    if (tokensRaw == null || userRaw == null) return null;

    Map<String, dynamic>? tokens;
    Map<String, dynamic>? user;
    try {
      tokens = jsonDecode(tokensRaw) as Map<String, dynamic>?;
      user = jsonDecode(userRaw) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
    if (tokens == null || user == null) return null;

    return AuthStoredSession(
      accessToken: tokens["access"] as String?,
      refreshToken: tokens["refresh"] as String?,
      user: user,
      theme: prefs.getString(_kTheme),
    );
  }

  /// Updates only the token fields inside the stored session.
  /// Used after a silent token refresh so the user stays signed in.
  static Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kTokens);
      if (raw == null) return;
      final tokens = jsonDecode(raw) as Map<String, dynamic>;
      tokens["access"] = accessToken;
      tokens["refresh"] = refreshToken;
      await prefs.setString(_kTokens, jsonEncode(tokens));
    } catch (_) {}
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kTokens);
    await prefs.remove(_kUser);
    await prefs.remove(_kTheme);
  }
}

class AuthStoredSession {
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;
  final String? theme;

  const AuthStoredSession({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.theme,
  });
}
