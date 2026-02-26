import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";
import "package:http/http.dart" as http;

import "../../widgets/main_scaffold.dart";
import "../../widgets/page_header.dart";
import "../../../../../core/config/api.dart";
import "../../../../../core/constants/api/auth_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../core/services/language_service.dart";
import "../../../../../i18n/translations.dart";

class SettingsLanguagePage extends StatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  State<SettingsLanguagePage> createState() => _SettingsLanguagePageState();
}

class _SettingsLanguagePageState extends State<SettingsLanguagePage> {
  late String _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final current =
        AuthSession.instance.value.user?["preferred_language"] as String?;
    _selected = current?.isNotEmpty == true ? _normalizeToCode(current!) : "en";
  }

  String _normalizeToCode(String v) {
    final lower = v.toLowerCase();
    if (lower.startsWith("en")) return "en";
    if (lower.startsWith("rw")) return "rw";
    if (lower.startsWith("fr")) return "fr";
    if (lower.startsWith("es")) return "es";
    if (lower.startsWith("de")) return "de";
    return "en";
  }

  String _codeToBackendLabel(String code) => switch (code) {
        "rw" => "Kinyarwanda",
        "fr" => "French",
        "es" => "Spanish",
        "de" => "German",
        _ => "English",
      };

  Future<void> _select(String code) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final tokens = AuthSession.instance.value.accessToken;
      if (tokens == null || tokens.isEmpty) {
        throw Exception("Missing access token");
      }

      final uri = Api.url(AuthEndpoints.meLanguage);
      final response = await http.patch(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $tokens",
        },
        body: jsonEncode({"preferred_language": _codeToBackendLabel(code)}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _selected = code;
        await LanguageService.save(code);

        final current = AuthSession.instance.value.user ?? {};
        final updatedUser = {
          ...current,
          "preferred_language": code,
          "preferred_languages": [code],
        };
        AuthSession.instance.signIn(
          user: updatedUser,
          accessToken: AuthSession.instance.value.accessToken ?? "",
          refreshToken: AuthSession.instance.value.refreshToken ?? "",
          theme: AuthSession.instance.value.theme,
        );

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: Text(t(_selected, "settings.language")),
            description: const Text("Language updated"),
            alignment: Alignment.topCenter,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      } else {
        throw Exception("Status ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text("Update failed"),
          description: Text(e.toString()),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: "Language",
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const PageHeader(title: "Language"),
          const SizedBox(height: 10),
          Text(
            "Choose your preferred language",
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: scheme.onSurface.withOpacity(0.68),
            ),
          ),
          const SizedBox(height: 14),

          // Glass list container
          _GlassCard(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
              children: _withDividers(
                context,
                supportedLanguages
                    .map(
                      (code) => _LanguageTile(
                        code: code,
                        selected: _selected == code,
                        isBusy: _busy,
                        onTap: () => _select(code),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _withDividers(BuildContext context, List<Widget> tiles) {
    final scheme = Theme.of(context).colorScheme;

    final out = <Widget>[];
    for (var i = 0; i < tiles.length; i++) {
      out.add(tiles[i]);
      if (i != tiles.length - 1) {
        out.add(
          Padding(
            padding: const EdgeInsets.only(left: 44, right: 6),
            child: Divider(
              height: 14,
              thickness: 1,
              color: scheme.onSurface.withOpacity(0.06),
            ),
          ),
        );
      }
    }
    return out;
  }
}

class _LanguageTile extends StatefulWidget {
  final String code;
  final bool selected;
  final bool isBusy;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.code,
    required this.selected,
    required this.isBusy,
    required this.onTap,
  });

  @override
  State<_LanguageTile> createState() => _LanguageTileState();
}

class _LanguageTileState extends State<_LanguageTile> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  String get _label => switch (widget.code) {
        "en" => "English",
        "rw" => "Kinyarwanda",
        "fr" => "French",
        "es" => "Spanish",
        "de" => "German",
        _ => widget.code,
      };

  String get _subtitle => switch (widget.code) {
        "en" => "Default experience",
        "rw" => "Ururimi rw’iwacu",
        "fr" => "Expérience en français",
        "es" => "Experiencia en español",
        "de" => "Erlebnis auf Deutsch",
        _ => "",
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final isActive = _pressed || _hovered;
    final disabled = widget.isBusy && !widget.selected;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: disabled ? null : (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: disabled ? null : widget.onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 140),
          opacity: disabled ? 0.55 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: isActive
                  ? scheme.onSurface.withOpacity(0.06)
                  : Colors.transparent,
            ),
            child: AnimatedScale(
              duration: const Duration(milliseconds: 140),
              curve: Curves.easeOut,
              scale: _pressed ? 0.985 : 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                child: Row(
                  children: [
                    _IconBadge(
                      icon: HugeIcons.strokeRoundedLanguageSkill,
                      selected: widget.selected,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _label,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14, // ✅ title 14
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle,
                            style: TextStyle(
                              fontSize: 12, // ✅ subtitle 12
                              height: 1.2,
                              color: scheme.onSurface.withOpacity(0.68),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: anim,
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: widget.isBusy && widget.selected
                          ? SizedBox(
                              key: const ValueKey("spinner"),
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation(scheme.primary),
                              ),
                            )
                          : Icon(
                              widget.selected
                                  ? Icons.check_circle_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              key: ValueKey(widget.selected ? "on" : "off"),
                              size: 18,
                              color: widget.selected
                                  ? scheme.primary
                                  : scheme.onSurface.withOpacity(0.4),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final dynamic icon;
  final bool selected;

  const _IconBadge({
    required this.icon,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: 30,
      width: 30,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary.withOpacity(selected ? 0.26 : 0.20),
            scheme.primary.withOpacity(selected ? 0.14 : 0.10),
          ],
        ),
        border: Border.all(
          color: scheme.onSurface.withOpacity(selected ? 0.14 : 0.10),
          width: 1,
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          color: scheme.primary.withOpacity(selected ? 1 : 0.95),
          size: 14, // ✅ all icons 14
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: scheme.surface.withOpacity(0.55),
            border: Border.all(
              color: scheme.onSurface.withOpacity(0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}