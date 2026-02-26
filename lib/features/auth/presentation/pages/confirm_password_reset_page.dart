import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/reset_password_cache.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";
import "../widgets/info_pill.dart";

class ConfirmPasswordResetPage extends StatefulWidget {
  final String? email;
  const ConfirmPasswordResetPage({super.key, this.email});

  @override
  State<ConfirmPasswordResetPage> createState() =>
      _ConfirmPasswordResetPageState();
}

class _ConfirmPasswordResetPageState extends State<ConfirmPasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  late final String _email;
  late final String _otp;

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final cache = ResetPasswordCache.instance;
    _email = widget.email ?? cache.email ?? "";
    _otp = cache.otp ?? "";

    _newPassword.addListener(() {
      if (mounted) setState(() {});
    });
    _confirmPassword.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);

    try {
      final uri = Api.url(AuthEndpoints.passwordResetConfirm);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email,
          "otp": _otp,
          "new_password": _newPassword.text,
          "confirm_new_password": _confirmPassword.text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ResetPasswordCache.instance.clear();

        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text(tr("auth.password_updated")),
          description: Text(tr("auth.password_updated_desc")),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );

        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }

      final detail = _extractError(response);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.reset_failed")),
        description: Text(detail),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (_) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: Text(tr("auth.network_error")),
          description: Text(tr("auth.reset_retry")),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
    return tr("auth.reset_retry");
  }

  String _maskEmail(String email) {
    final e = email.trim();
    if (e.isEmpty || !e.contains("@")) return e.isEmpty ? "—" : e;
    final parts = e.split("@");
    final name = parts.first;
    final domain = parts.last;
    if (name.length <= 2) return "${name[0]}***@$domain";
    return "${name.substring(0, 2)}***@$domain";
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
    final scheme = Theme.of(context).colorScheme;

    final score = _passwordScore(_newPassword.text);
    final match = _confirmPassword.text.isNotEmpty &&
        _confirmPassword.text == _newPassword.text;

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: _GlassCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthUI.heading(tr("auth.set_new_password")),
              const SizedBox(height: 6),

              // ✅ subtitle visible in both themes
              Text(
                tr("auth.set_new_password_sub"),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: scheme.onSurface.withOpacity(0.92),
                ),
              ),

              const SizedBox(height: 14),

              InfoPill(
                icon: HugeIcons.strokeRoundedMail01,
                text: t(currentLangSync(), "auth.reset_for")
                    .replaceFirst("{email}", _maskEmail(_email)),
              ),

              const SizedBox(height: 14),

              _StrengthRow(
                score: score,
                label: _passwordLabel(score),
              ),

              const SizedBox(height: 14),

              AuthUI.label(tr("auth.new_password")),
              const SizedBox(height: 10),
              _GlassPasswordField(
                controller: _newPassword,
                hint: tr("auth.new_password_hint"),
                obscure: _obscure1,
                enabled: !_isBusy,
                onToggle: () => setState(() => _obscure1 = !_obscure1),
                validator: (v) =>
                    (v == null || v.isEmpty) ? tr("auth.password_required") : null,
              ),

              const SizedBox(height: 16),

              AuthUI.label(tr("auth.confirm_new_password")),
              const SizedBox(height: 10),
              _GlassPasswordField(
                controller: _confirmPassword,
                hint: tr("auth.confirm_new_password_hint"),
                obscure: _obscure2,
                enabled: !_isBusy,
                trailingBadge: _MatchBadge(
                  visible: _confirmPassword.text.isNotEmpty,
                  ok: match,
                ),
                onToggle: () => setState(() => _obscure2 = !_obscure2),
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return tr("auth.confirm_password_required");
                  }
                  if (v != _newPassword.text) return tr("auth.passwords_mismatch");
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // ✅ NOT const (important for hot reload scenarios)
              _PrimaryButton(
                label: tr("auth.save_changes"),
                busy: _isBusy,
                onTap: _isBusy ? null : _onSave,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StrengthRow extends StatelessWidget {
  final int score; // 0..4
  final String label;

  const _StrengthRow({
    required this.score,
    required this.label,
  });

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
                          color: scheme.primary.withOpacity(0.85),
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
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final VoidCallback onToggle;
  final bool enabled;
  final String? Function(String?) validator;
  final Widget? trailingBadge;

  const _GlassPasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.enabled,
    required this.validator,
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

    return Focus(
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
                      fontSize: 12,
                      color: scheme.onSurface.withOpacity(0.92),
                    ),
                    decoration: InputDecoration(
                      hintText: widget.hint,
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
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedLockPassword,
                            size: 14,
                            strokeWidth: 2,
                            color: scheme.primary.withOpacity(0.95),
                          ),
                        ),
                      ),
                    ),
                    validator: widget.validator,
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
                    size: 14,
                    strokeWidth: 2,
                    color: scheme.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
                        fontSize: 14,
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
            color: scheme.surface.withOpacity(0.55), // ✅ no border/gradient/shadow
          ),
          child: child,
        ),
      ),
    );
  }
}
