import "dart:async";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/language_service.dart";
import "../../../../core/services/theme_notifier.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class AuthScaffold extends StatefulWidget {
  final Widget child;

  const AuthScaffold({super.key, required this.child});

  @override
  State<AuthScaffold> createState() => _AuthScaffoldState();
}

class _AuthScaffoldState extends State<AuthScaffold> {
  late String _lang;

  @override
  void initState() {
    super.initState();
    _lang = currentLangSync();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = isDark ? "assets/branding/logo_color.png" : "assets/branding/logo_black.png";
    final themeNotifier = context.read<ThemeNotifier?>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: isDark ? t(_lang, "theme.light") : t(_lang, "theme.dark"),
                        onPressed: () {
                          if (themeNotifier == null) return;
                          final next = isDark ? ThemeMode.light : ThemeMode.dark;
                          themeNotifier.setMode(next);
                        },
                        icon: Icon(
                          isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                          color: scheme.onSurface.withOpacity(0.80),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _LangSelector(
                        current: _lang,
                        onSelect: _onLangSelect,
                      ),
                      const Spacer(),
                      Image.asset(
                        logoAsset,
                        height: 82,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  widget.child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onLangSelect(String code) async {
    setState(() => _lang = code);
    await LanguageService.save(code);

    final session = AuthSession.instance.value;
    AuthSession.instance.signIn(
      user: {
        ...?session.user,
        "preferred_language": code,
        "preferred_languages": [code],
      },
      accessToken: session.accessToken ?? "",
      refreshToken: session.refreshToken ?? "",
      theme: session.theme,
    );

    // Persist to backend if authenticated; silent background request.
    if (session.isAuthenticated && (session.accessToken ?? "").isNotEmpty) {
      final uri = Api.url(AuthEndpoints.meLanguage);
      unawaited(http.patch(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer ${session.accessToken}",
        },
        body: '{"preferred_language": "${_codeToBackendLabel(code)}"}',
      ));
    }
  }

  String _codeToBackendLabel(String code) => switch (code) {
        "rw" => "Kinyarwanda",
        "fr" => "French",
        "es" => "Spanish",
        "de" => "German",
        _ => "English",
      };
}

class _LangSelector extends StatelessWidget {
  final String current;
  final ValueChanged<String> onSelect;

  const _LangSelector({
    required this.current,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      onSelected: onSelect,
      initialValue: current,
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      itemBuilder: (context) => supportedLanguages
          .map(
            (c) => PopupMenuItem(
              value: c,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      "icons/language/$c.png",
                      width: 20,
                      height: 14,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Icon(Icons.language, size: 18, color: scheme.onSurface),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _label(c),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: scheme.onSurface.withOpacity(0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                "icons/language/$current.png",
                width: 20,
                height: 14,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Icon(Icons.language, size: 18, color: scheme.onSurface),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              current.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 18, color: scheme.onSurface.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }

  String _label(String c) => switch (c) {
        "rw" => "Kinyarwanda",
        "fr" => "French",
        "es" => "Spanish",
        "de" => "German",
        _ => "English",
      };
}
