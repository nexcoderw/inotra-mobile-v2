import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/auth_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../widgets/main_scaffold.dart";
import "../../widgets/page_header.dart";

class ProfileDangerZonePage extends StatefulWidget {
  const ProfileDangerZonePage({super.key});

  @override
  State<ProfileDangerZonePage> createState() => _ProfileDangerZonePageState();
}

class _ProfileDangerZonePageState extends State<ProfileDangerZonePage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "profile.danger_zone"),
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          PageHeader(
            title: t(lang, "profile.danger_zone"),
            onBack: () => Navigator.of(context).pop(),
            icon: HugeIcons.strokeRoundedArrowLeft01,
          ),
          const SizedBox(height: 10),

          // Premium warning header
          _GlassCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  height: 34,
                  width: 34,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: scheme.error.withOpacity(0.12),
                    border: Border.all(
                      color: scheme.error.withOpacity(0.22),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 14, // ✅ icon size 14
                      color: scheme.error,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    t(lang, "profile.danger_notice"),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: scheme.onSurface.withOpacity(0.68),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          _DangerGlassCard(
            color: scheme.error,
            title: t(lang, "profile.deactivate"),
            description: t(lang, "profile.deactivate_desc"),
            actionLabel: t(lang, "profile.deactivate_action"),
            busy: _busy,
            onConfirm: () => _confirmAction(
              context,
              title: t(lang, "profile.deactivate"),
              message: t(lang, "profile.deactivate_desc"),
              confirmLabel: t(lang, "profile.deactivate_action"),
              tone: scheme.error,
              onConfirm: () => _doAction(AuthEndpoints.meDeactivate),
            ),
          ),

          const SizedBox(height: 12),

          _DangerGlassCard(
            color: Colors.red.shade900,
            title: t(lang, "profile.delete_account"),
            description: t(lang, "profile.delete_desc"),
            actionLabel: t(lang, "profile.delete_action"),
            busy: _busy,
            onConfirm: () => _confirmAction(
              context,
              title: t(lang, "profile.delete_account"),
              message: t(lang, "profile.delete_desc"),
              confirmLabel: t(lang, "profile.delete_action"),
              tone: Colors.red.shade900,
              onConfirm: () => _doAction(AuthEndpoints.meDeleteRequest),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Color tone,
    required VoidCallback onConfirm,
  }) async {
    if (_busy) return;

    final scheme = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      barrierDismissible: !_busy,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: _GlassCard(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 46,
                width: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: tone.withOpacity(0.12),
                  border: Border.all(color: tone.withOpacity(0.22)),
                ),
                child: Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 14, // ✅ icon size 14
                    color: tone,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14, // ✅ title 14
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withOpacity(0.92),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, // ✅ subtitle 12
                  height: 1.25,
                  color: scheme.onSurface.withOpacity(0.68),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _GhostButton(
                      label: "Cancel",
                      onTap: _busy ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DangerButton(
                      label: confirmLabel,
                      tone: tone,
                      busy: _busy,
                      onTap: _busy
                          ? null
                          : () {
                              Navigator.of(context).pop();
                              onConfirm();
                            },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _doAction(String endpoint) async {
    setState(() => _busy = true);

    final session = AuthSession.instance.value;
    final token = session.accessToken ?? "";
    if (token.isEmpty) {
      await AuthSession.instance.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      }
      return;
    }

    try {
      final uri = Api.url(endpoint);
      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({}),
      );

      if (resp.statusCode == 401) {
        await AuthSession.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
        }
        return;
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await AuthSession.instance.signOut();
        if (!mounted) return;

        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text(t(currentLangSync(), "auth.update_success")),
          description: Text(t(currentLangSync(), "profile.danger_zone")),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );

        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
        return;
      }

      _showError(resp);
    } catch (e) {
      _showError(null, fallback: e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(http.Response? resp, {String? fallback}) {
    final detail = resp != null ? _extractError(resp) : (fallback ?? "Action failed");
    if (!mounted) return;

    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text(t(currentLangSync(), "auth.update_failed")),
      description: Text(detail),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  Map<String, dynamic>? _safeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(http.Response response) {
    final body = _safeJson(response.body);
    final detail = body?["detail"] ?? body?["message"] ?? body?["error"];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    return "Action failed (${response.statusCode})";
  }
}

class _DangerGlassCard extends StatelessWidget {
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onConfirm;
  final bool busy;

  const _DangerGlassCard({
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onConfirm,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.22)),
                ),
                child: Center(
                  child: Icon(
                    Icons.warning_amber_rounded,
                    size: 14, // ✅ icon size 14
                    color: color,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: color,
                    fontSize: 14, // ✅ title 14
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
              fontSize: 12, // ✅ subtitle 12
              height: 1.25,
              color: scheme.onSurface.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 12),
          _DangerButton(
            label: actionLabel,
            tone: color,
            busy: busy,
            onTap: busy ? null : onConfirm,
          ),
        ],
      ),
    );
  }
}

class _DangerButton extends StatefulWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;
  final Color tone;

  const _DangerButton({
    required this.label,
    required this.tone,
    required this.busy,
    required this.onTap,
  });

  @override
  State<_DangerButton> createState() => _DangerButtonState();
}

class _DangerButtonState extends State<_DangerButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    // keep using the provided "tone" but match the same style (pill, no shadows, same loader)
    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 0.992 : 1,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.tone,
                widget.tone.withOpacity(0.88),
              ],
            ),
            boxShadow: const [], // ✅ no shadow (hover/click)
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: widget.busy
                  ? const _PremiumDotsLoader(key: ValueKey("dots"))
                  : Text(
                      widget.label,
                      key: const ValueKey("label"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ Same premium dots loader (copy exactly)
class _PremiumDotsLoader extends StatefulWidget {
  const _PremiumDotsLoader({super.key});

  @override
  State<_PremiumDotsLoader> createState() => _PremiumDotsLoaderState();
}

class _PremiumDotsLoaderState extends State<_PremiumDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value; // 0..1

        double bump(double phase) {
          final x = (t - phase) * 2 * math.pi;
          return (0.5 + 0.5 * (-math.cos(x))).clamp(0.0, 1.0);
        }

        final b1 = bump(0.0);
        final b2 = bump(0.18);
        final b3 = bump(0.36);

        Widget dot(double b) => AnimatedContainer(
              duration: const Duration(milliseconds: 90),
              height: 6 + (b * 4),
              width: 6 + (b * 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.75 + b * 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            );

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dot(b1),
            const SizedBox(width: 7),
            dot(b2),
            const SizedBox(width: 7),
            dot(b3),
          ],
        );
      },
    );
  }
}

class _GhostButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;

  const _GhostButton({required this.label, required this.onTap});

  @override
  State<_GhostButton> createState() => _GhostButtonState();
}

class _GhostButtonState extends State<_GhostButton> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          scale: _pressed ? 0.99 : 1,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: scheme.onSurface.withOpacity(_hovered ? 0.06 : 0.04),
              border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
            ),
            child: Center(
              child: Text(
                widget.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withOpacity(0.80),
                ),
              ),
            ),
          ),
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
