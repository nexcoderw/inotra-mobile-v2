import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "package:inotra/core/config/api.dart";
import "package:inotra/core/config/app_routes.dart";
import "package:inotra/core/constants/api/auth_endpoints.dart";
import "package:inotra/core/services/auth_session.dart";
import "package:inotra/features/main/presentation/widgets/main_scaffold.dart";
import "package:inotra/features/main/presentation/widgets/page_header.dart";
import "package:inotra/i18n/lang.dart";
import "package:inotra/i18n/translations.dart";

class ProfileChangePasswordPage extends StatefulWidget {
  const ProfileChangePasswordPage({super.key});

  @override
  State<ProfileChangePasswordPage> createState() =>
      _ProfileChangePasswordPageState();
}

class _ProfileChangePasswordPageState extends State<ProfileChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();

  bool _ob0 = true;
  bool _ob1 = true;
  bool _ob2 = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _new.addListener(() {
      if (mounted) setState(() {});
    });
    _confirm.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  int _passwordScore(String v) {
    final s = v.trim();
    if (s.isEmpty) return 0;
    var score = 0;
    if (s.length >= 8) score++;
    if (RegExp(r"[A-Z]").hasMatch(s)) score++;
    if (RegExp(r"[0-9]").hasMatch(s)) score++;
    if (RegExp(r"[^A-Za-z0-9]").hasMatch(s)) score++;
    return score; // 0..4
  }

  String _passwordLabel(int score) => switch (score) {
        0 => "Too weak",
        1 => "Weak",
        2 => "Okay",
        3 => "Strong",
        _ => "Very strong",
      };

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    final score = _passwordScore(_new.text);
    final match = _confirm.text.isNotEmpty && _confirm.text == _new.text;

    return MainScaffold(
      title: t(lang, "profile.change_password"),
      showAppBar: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            PageHeader(
              title: t(lang, "profile.change_password"),
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),

            // ✅ Premium glass container
            _GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Update your password",
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: scheme.onSurface.withOpacity(0.68),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),

                  _GlassPasswordField(
                    label: t(lang, "profile.current_password"),
                    controller: _current,
                    obscure: _ob0,
                    enabled: !_busy,
                    requiredMessage: t(lang, "auth.required_field"),
                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                    onToggle: () => setState(() => _ob0 = !_ob0),
                  ),

                  const SizedBox(height: 14),

                  // Strength row (for new password)
                  _StrengthRow(score: score, label: _passwordLabel(score)),
                  const SizedBox(height: 10),

                  _GlassPasswordField(
                    label: t(lang, "profile.new_password"),
                    controller: _new,
                    obscure: _ob1,
                    enabled: !_busy,
                    requiredMessage: t(lang, "auth.required_field"),
                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                    onToggle: () => setState(() => _ob1 = !_ob1),
                  ),

                  const SizedBox(height: 14),

                  _GlassPasswordField(
                    label: t(lang, "profile.confirm_password"),
                    controller: _confirm,
                    obscure: _ob2,
                    enabled: !_busy,
                    requiredMessage: t(lang, "auth.required_field"),
                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                    onToggle: () => setState(() => _ob2 = !_ob2),
                    trailingBadge: _MatchBadge(
                      visible: _confirm.text.isNotEmpty,
                      ok: match,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return t(lang, "auth.required_field");
                      }
                      if (v != _new.text) return t(lang, "auth.passwords_mismatch");
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _PrimaryButton(
              label: t(lang, "auth.save_changes"),
              busy: _busy,
              onTap: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
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
      final uri = Api.url(AuthEndpoints.mePasswordChange);
      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "current_password": _current.text,
          "new_password": _new.text,
          "confirm_new_password": _confirm.text,
        }),
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
          title: Text(t(currentLangSync(), "auth.password_updated")),
          description: Text(t(currentLangSync(), "auth.password_updated_desc")),
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
    final detail = resp != null ? _extractError(resp) : (fallback ?? "Update failed");
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
    return "Update failed (${response.statusCode})";
  }
}

class _StrengthRow extends StatelessWidget {
  final int score; // 0..4
  final String label;

  const _StrengthRow({required this.score, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final pct = (score / 4).clamp(0.0, 1.0);
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        width: c.maxWidth * pct,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withOpacity(0.70),
          ),
        ),
      ],
    );
  }
}

class _MatchBadge extends StatelessWidget {
  final bool visible;
  final bool ok;

  const _MatchBadge({required this.visible, required this.ok});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 160),
      child: AnimatedScale(
        scale: visible ? 1 : 0.95,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: (ok ? scheme.primary : scheme.error).withOpacity(0.12),
            border: Border.all(
              color: (ok ? scheme.primary : scheme.error).withOpacity(0.25),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                ok ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 14,
                color: ok ? scheme.primary : scheme.error,
              ),
              const SizedBox(width: 6),
              Text(
                ok ? "Match" : "No match",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: ok ? scheme.primary : scheme.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassPasswordField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  final String requiredMessage;
  final bool enabled;
  final dynamic prefixIcon;
  final String? Function(String?)? validator;
  final Widget? trailingBadge;

  const _GlassPasswordField({
    required this.label,
    required this.controller,
    required this.obscure,
    required this.onToggle,
    required this.requiredMessage,
    required this.enabled,
    required this.prefixIcon,
    this.validator,
    this.trailingBadge,
  });

  @override
  State<_GlassPasswordField> createState() => _GlassPasswordFieldState();
}

class _GlassPasswordFieldState extends State<_GlassPasswordField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final borderColor = _focused
        ? scheme.primary.withOpacity(0.35)
        : scheme.onSurface.withOpacity(0.10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 14, // ✅ title 14
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withOpacity(0.92),
          ),
        ),
        const SizedBox(height: 8),
        Focus(
          onFocusChange: (v) => setState(() => _focused = v),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: widget.controller,
                        obscureText: widget.obscure,
                        enabled: widget.enabled,
                        style: TextStyle(
                          fontSize: 12, // ✅ field text 12
                          color: scheme.onSurface.withOpacity(0.92),
                        ),
                        decoration: InputDecoration(
                          hintText: widget.label,
                          hintStyle: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.45),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          border: InputBorder.none,
                          prefixIcon: Padding(
                            padding: const EdgeInsets.only(left: 12, right: 8),
                            child: Center(
                              widthFactor: 1,
                              child: widget.prefixIcon is IconData
                                  ? Icon(
                                      widget.prefixIcon as IconData,
                                      size: 14, // ✅ icon size 14
                                      color: scheme.primary.withOpacity(0.95),
                                    )
                                  : HugeIcon(
                                      icon: widget.prefixIcon,
                                      size: 14, // ✅ icon size 14
                                      strokeWidth: 2,
                                      color: scheme.primary.withOpacity(0.95),
                                    ),
                            ),
                          ),
                        ),
                        validator: widget.validator ??
                            (v) => (v == null || v.trim().isEmpty)
                                ? widget.requiredMessage
                                : null,
                      ),
                    ),
                    if (widget.trailingBadge != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: widget.trailingBadge!,
                      ),
                    IconButton(
                      onPressed: widget.enabled ? widget.onToggle : null,
                      icon: HugeIcon(
                        icon: widget.obscure
                            ? HugeIcons.strokeRoundedViewOff
                            : HugeIcons.strokeRoundedView,
                        size: 14, // ✅ icon size 14
                        strokeWidth: 2,
                        color: scheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

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
                scheme.primary,
                scheme.primary.withOpacity(0.88),
              ],
            ),
            boxShadow: const [], // ✅ no shadow on hover/click
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

// ✅ Premium loading: animated 3 dots (same as before)
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
