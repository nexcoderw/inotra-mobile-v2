import "../core/services/auth_session.dart";
import "../core/services/language_service.dart";
import "translations.dart";

/// Resolves the current language code based on user session or saved choice.
String currentLangSync() {
  final preferred = AuthSession.instance.value.user?["preferred_language"] as String?;
  if (preferred != null && preferred.isNotEmpty) {
    return _normalize(preferred);
  }
  return "en";
}

String _normalize(String v) {
  final lower = v.toLowerCase();
  if (lower.startsWith("rw")) return "rw";
  if (lower.startsWith("fr")) return "fr";
  if (lower.startsWith("es")) return "es";
  if (lower.startsWith("de")) return "de";
  return "en";
}

/// Translate a key using the current language.
String tr(String key) {
  final lang = currentLangSync();
  return t(lang, key);
}
