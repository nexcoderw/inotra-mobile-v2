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
import "../../../../core/services/registration_cache.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";
import "../widgets/info_pill.dart";

class ConfirmRegistrationOtpPage extends StatefulWidget {
  const ConfirmRegistrationOtpPage({super.key});

  @override
  State<ConfirmRegistrationOtpPage> createState() =>
      _ConfirmRegistrationOtpPageState();
}

class _ConfirmRegistrationOtpPageState extends State<ConfirmRegistrationOtpPage> {
  final _email = TextEditingController();

  final List<TextEditingController> _c = [];
  final List<FocusNode> _f = [];

  bool _isBusy = false;
  String? _initialEmail;

  void _ensureOtpFields() {
    while (_c.length < 6) {
      _c.add(TextEditingController());
    }
    while (_f.length < 6) {
      _f.add(FocusNode());
    }
  }

  @override
  void dispose() {
    _email.dispose();
    for (final c in _c) {
      c.dispose();
    }
    for (final f in _f) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _c.map((e) => e.text).join();

  // ---------------------------
  // LOGIC (unchanged)
  // ---------------------------
  Future<void> _verify() async {
    if (_otp.trim().length != 6) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.invalid_code")),
        description: Text(tr("auth.invalid_code_desc")),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final uri = Api.url(AuthEndpoints.registerVerify);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text.trim(),
          "otp": _otp.trim(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text(tr("auth.account_verified")),
          description: Text(tr("auth.account_verified_desc")),
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
        title: Text(tr("auth.verification_failed")),
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
          description: Text(tr("auth.verify_retry")),
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
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(http.Response response) {
    final body = _safeJson(response.body);
    final detail = body?["detail"] ?? body?["message"] ?? body?["error"];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    return tr("auth.invalid_code_desc");
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

  void _handleOtpChange(int i, String v) {
    // keep your behavior, just adds paste + smarter focus handling
    final raw = v;

    // paste support: user pasted "123456" into one box
    if (raw.length > 1) {
      final digits = raw.replaceAll(RegExp(r"\D"), "");
      if (digits.isEmpty) return;

      for (var k = 0; k < 6; k++) {
        _c[k].text = k < digits.length ? digits[k] : "";
      }

      final next = digits.length.clamp(1, 6) - 1;
      _f[next].requestFocus();
      setState(() {});
      return;
    }

    if (raw.isNotEmpty && i < 5) {
      _f[i + 1].requestFocus();
    }
    if (raw.isEmpty && i > 0) {
      _f[i - 1].requestFocus();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _ensureOtpFields();

    // pick up email from navigation args once
    _initialEmail ??=
        ModalRoute.of(context)?.settings.arguments as String? ??
            RegistrationCache.instance.email;
    if ((_initialEmail ?? "").isNotEmpty && _email.text.isEmpty) {
      _email.text = _initialEmail!;
    }

    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return AuthScaffold(
      child: _GlassCard(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUI.heading(
              tr("auth.verify_heading"),
              color: onSurface.withOpacity(0.96),
            ),
            const SizedBox(height: 6),

            // subtitle visible in both themes
            Text(
              tr("auth.verify_desc"),
              style: TextStyle(
                fontSize: 12,
                height: 1.25,
                fontWeight: FontWeight.w600,
                color: onSurface.withOpacity(0.88),
              ),
            ),

            const SizedBox(height: 16),

            InfoPill(
              icon: HugeIcons.strokeRoundedMail01,
              text: t(currentLangSync(), "auth.reset_for")
                  .replaceFirst("{email}", _maskEmail(_email.text)),
            ),

            const SizedBox(height: 16),

            AuthUI.label(tr("auth.email_label"), color: onSurface.withOpacity(0.92)),
            const SizedBox(height: 10),

            _GlassField(
              controller: _email,
              hint: "",
              enabled: false,
              readOnly: true,
              keyboardType: TextInputType.emailAddress,
              prefixIcon: HugeIcons.strokeRoundedMail01,
              validator: (_) => null,
            ),

            const SizedBox(height: 16),

            AuthUI.label(tr("auth.otp_code"), color: onSurface.withOpacity(0.92)),
            const SizedBox(height: 12),

            _OtpRow(
              controllers: _c,
              focusNodes: _f,
              enabled: !_isBusy,
              onChanged: _handleOtpChange,
            ),

            const SizedBox(height: 18),

            _PrimaryPillButton(
              label: tr("auth.verify_heading"),
              busy: _isBusy,
              onTap: _isBusy ? null : _verify,
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${tr("auth.have_account")} ",
                  style: TextStyle(
                    color: onSurface.withOpacity(0.45),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                InkWell(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: Text(
                    tr("auth.sign_in"),
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w900,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------
// Premium building blocks (UI-only)
// ---------------------------

InputDecoration _glassInputDecoration(
  BuildContext context, {
  required String hint,
  dynamic prefixIcon,
  Widget? suffix,
}) {
  final scheme = Theme.of(context).colorScheme;

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface.withOpacity(0.45),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: InputBorder.none,
    prefixIcon: prefixIcon == null
        ? null
        : Padding(
            padding: const EdgeInsets.only(left: 12, right: 8),
            child: Center(
              widthFactor: 1,
              child: HugeIcon(
                icon: prefixIcon,
                size: 14,
                strokeWidth: 2,
                color: scheme.onSurface.withOpacity(0.65),
              ),
            ),
          ),
    suffixIcon: suffix,
  );
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    required this.padding,
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
            // main container: no border, no shadow, no gradient
            color: scheme.surface.withOpacity(0.55),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final dynamic prefixIcon;
  final Widget? suffix;
  final String? Function(String?) validator;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    required this.prefixIcon,
    this.suffix,
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
              readOnly: widget.readOnly,
              onTap: widget.onTap,
              keyboardType: widget.keyboardType,
              cursorColor: scheme.primary,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withOpacity(0.92),
              ),
              decoration: _glassInputDecoration(
                context,
                hint: widget.hint,
                prefixIcon: widget.prefixIcon,
                suffix: widget.suffix,
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool enabled;
  final void Function(int i, String v) onChanged;

  const _OtpRow({
    required this.controllers,
    required this.focusNodes,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        final node = focusNodes[i];

        return SizedBox(
          width: 48,
          height: 54,
          child: Focus(
            onFocusChange: (_) {},
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
                    border: Border.all(
                      color: node.hasFocus
                          ? scheme.primary.withOpacity(0.32)
                          : scheme.onSurface.withOpacity(0.10),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: controllers[i],
                    focusNode: node,
                    enabled: enabled,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface.withOpacity(0.92),
                    ),
                    decoration: const InputDecoration(
                      counterText: "",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) => onChanged(i, v),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
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
            boxShadow: const [], // no shadows
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
        final t = _c.value;

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