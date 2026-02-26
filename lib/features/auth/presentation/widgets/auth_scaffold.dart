import "dart:async";
import "dart:ui";

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
    final logoAsset = isDark
        ? "assets/branding/logo_color.png"
        : "assets/branding/logo_black.png";
    final themeNotifier = context.read<ThemeNotifier?>();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 12),

                      // Logo centered below the top-right controls
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, anim) => FadeTransition(
                            opacity: anim,
                            child: ScaleTransition(scale: anim, child: child),
                          ),
                          child: Image.asset(
                            logoAsset,
                            key: ValueKey(logoAsset),
                            height: 90,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),
                      widget.child,
                    ],
                  ),
                ),
              ),
            ),

            // Top-right controls (theme + language) pinned
            Positioned(
              top: 10,
              right: 12,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _GlassIconButton(
                    tooltip:
                        isDark ? t(_lang, "theme.light") : t(_lang, "theme.dark"),
                    onPressed: () {
                      if (themeNotifier == null) return;
                      final next = isDark ? ThemeMode.light : ThemeMode.dark;
                      themeNotifier.setMode(next);
                    },
                    child: Icon(
                      isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      size: 18,
                      color: scheme.onSurface.withOpacity(0.82),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _LangSelector(
                    current: _lang,
                    onSelect: _onLangSelect,
                  ),
                ],
              ),
            ),
          ],
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

    // Refresh current page so text updates, keeping user on same auth screen.
    final currentRoute = ModalRoute.of(context)?.settings.name ?? AppRoutes.login;
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, currentRoute, (_) => false);
  }

  String _codeToBackendLabel(String code) => switch (code) {
        "rw" => "Kinyarwanda",
        "fr" => "French",
        "es" => "Spanish",
        "de" => "German",
        _ => "English",
      };
}

class _LangSelector extends StatefulWidget {
  final String current;
  final ValueChanged<String> onSelect;

  const _LangSelector({
    required this.current,
    required this.onSelect,
  });

  @override
  State<_LangSelector> createState() => _LangSelectorState();
}

class _LangSelectorState extends State<_LangSelector> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = _pressed || _hovered;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: PopupMenuButton<String>(
          onSelected: widget.onSelect,
          initialValue: widget.current,
          offset: const Offset(0, 44),
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
                      "assets/icons/language/$c.png",
                          width: 20,
                          height: 14,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.language,
                            size: 18,
                            color: scheme.onSurface,
                          ),
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
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: scheme.onSurface.withOpacity(0.10),
                width: 1,
              ),
              color: isActive
                  ? scheme.onSurface.withOpacity(0.08)
                  : scheme.onSurface.withOpacity(0.06),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                "assets/icons/language/${widget.current}.png",
                    width: 20,
                    height: 14,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.language,
                      size: 18,
                      color: scheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.current.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: scheme.onSurface.withOpacity(0.7),
                ),
              ],
            ),
          ),
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

class _GlassIconButton extends StatefulWidget {
  final Widget child;
  final String? tooltip;
  final VoidCallback onPressed;

  const _GlassIconButton({
    required this.child,
    required this.onPressed,
    this.tooltip,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = _pressed || _hovered;

    return Tooltip(
      message: widget.tooltip ?? "",
      child: MouseRegion(
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          onTapDown: (_) => _setPressed(true),
          onTapUp: (_) => _setPressed(false),
          onTapCancel: () => _setPressed(false),
          onTap: widget.onPressed,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            scale: _pressed ? 0.96 : 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: scheme.onSurface.withOpacity(0.10),
                      width: 1,
                    ),
                    color: isActive
                        ? scheme.onSurface.withOpacity(0.09)
                        : scheme.onSurface.withOpacity(0.06),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
