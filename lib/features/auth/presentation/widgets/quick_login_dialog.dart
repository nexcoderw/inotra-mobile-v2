import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/auth_storage.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../../../../core/config/app_routes.dart";

class QuickLoginDialog extends StatefulWidget {
  const QuickLoginDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (_) => const QuickLoginDialog(),
    );
  }

  @override
  State<QuickLoginDialog> createState() => _QuickLoginDialogState();
}

class _QuickLoginDialogState extends State<QuickLoginDialog> {
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  final _formKey = GlobalKey<FormState>();
  bool _showPassword = false;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final lang = currentLangSync();

    setState(() => _busy = true);
    try {
      final uri = Api.url(AuthEndpoints.login);
      final resp = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": _identifier.text.trim(),
          "password": _password.text,
        }),
      );

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = jsonDecode(resp.body) as Map<String, dynamic>;
        final tokens = body["tokens"] as Map<String, dynamic>? ?? {};
        final user = body["user"] as Map<String, dynamic>? ?? {};

        await AuthStorage.saveSession(tokens: tokens, user: user, theme: "light");
        AuthSession.instance.signIn(
          user: user,
          accessToken: tokens["access"] as String? ?? "",
          refreshToken: tokens["refresh"] as String? ?? "",
          theme: "light",
        );

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        title: Text(t(lang, "auth.signed_in")),
        description: Text(t(lang, "auth.welcome_back")),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );

      Navigator.of(context).pop(); // close dialog, stay on same page
      // Refresh current route so authenticated header/state shows immediately.
      if (mounted) {
        // ignore: use_build_context_synchronously
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(pageBuilder: (_, __, ___) => Navigator.of(context).widget),
        );
      }
      return;
      }

      final detail = _extractError(resp.body);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(t(lang, "auth.login_failed")),
        description: Text(detail),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (_) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(t(lang, "auth.network_error")),
        description: Text(t(lang, "auth.network_retry")),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _extractError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded["detail"] != null) {
        return decoded["detail"].toString();
      }
    } catch (_) {}
    return "Unable to login";
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.95),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        t(lang, "auth.sign_in"),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      )
                    ],
                  ),
                  const SizedBox(height: 12),

                  _GlassField(
                    controller: _identifier,
                    hint: t(lang, "auth.identifier"),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_busy,
                    prefixIcon: HugeIcons.strokeRoundedMail02,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? t(lang, "auth.required_field") : null,
                  ),
                  const SizedBox(height: 10),
                  _GlassField(
                    controller: _password,
                    hint: t(lang, "auth.password"),
                    keyboardType: TextInputType.visiblePassword,
                    enabled: !_busy,
                    obscure: !_showPassword,
                    prefixIcon: HugeIcons.strokeRoundedLockPassword,
                    onToggleObscure: () => setState(() => _showPassword = !_showPassword),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? t(lang, "auth.required_field") : null,
                  ),

                  const SizedBox(height: 14),

                  _PrimaryPillButton(
                    label: t(lang, "auth.sign_in"),
                    busy: _busy,
                    onTap: _busy ? null : _login,
                  ),

                  const SizedBox(height: 12),
                  _GoogleButton(
                    busy: _busy,
                    onTap: _busy
                        ? null
                        : () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                  ),

                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t(lang, "auth.no_account"),
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      TextButton(
                        onPressed: _busy
                            ? null
                            : () {
                                Navigator.of(context).pop();
                                Navigator.pushNamed(context, AppRoutes.register);
                              },
                        child: Text(
                          t(lang, "auth.sign_up"),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/* --------------------------- Reused UI pieces (trimmed) --------------------------- */

class _GlassField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool enabled;
  final bool obscure;
  final dynamic prefixIcon;
  final VoidCallback? onToggleObscure;
  final String? Function(String?) validator;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.obscure = false,
    required this.prefixIcon,
    this.onToggleObscure,
  });

  @override
  State<_GlassField> createState() => _GlassFieldState();
}

class _GlassFieldState extends State<_GlassField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final borderColor = _focused
        ? scheme.primary.withOpacity(0.32)
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
            child: TextFormField(
              controller: widget.controller,
              enabled: widget.enabled,
              obscureText: widget.obscure,
              keyboardType: widget.keyboardType,
              cursorColor: scheme.primary,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.92),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withOpacity(0.5),
                ),
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 10),
                  child: HugeIcon(
                    icon: widget.prefixIcon,
                    size: 18,
                    strokeWidth: 2,
                    color: scheme.onSurface.withOpacity(0.75),
                  ),
                ),
                suffixIcon: widget.onToggleObscure == null
                    ? null
                    : IconButton(
                        icon: Icon(
                          widget.obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 18,
                          color: scheme.onSurface.withOpacity(0.65),
                        ),
                        onPressed: widget.onToggleObscure,
                      ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryPillButton extends StatefulWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _PrimaryPillButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  State<_PrimaryPillButton> createState() => _PrimaryPillButtonState();
}

class _PrimaryPillButtonState extends State<_PrimaryPillButton> {
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
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: widget.busy
                  ? const _DotsLoader(key: ValueKey("dots"))
                  : Text(
                      widget.label,
                      key: const ValueKey("label"),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
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

class _GoogleButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onTap;

  const _GoogleButton({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 46,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: scheme.onSurface.withOpacity(0.16)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        onPressed: busy ? null : onTap,
        icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
        label: Text(
          t(currentLangSync(), "auth.sign_in_google"),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _DotsLoader extends StatefulWidget {
  const _DotsLoader({super.key});

  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = _ctrl.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = i * 0.18;
            final v = (t - phase);
            final pulse = (0.5 + 0.5 * (1 - math.cos(v * 2 * math.pi))).clamp(0.0, 1.0);
            final size = 6 + 4 * pulse;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: scheme.onPrimary,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
