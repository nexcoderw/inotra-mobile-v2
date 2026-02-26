import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/reset_password_cache.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";
import "../widgets/info_pill.dart";

class ResetPasswordPage extends StatefulWidget {
  final String? email;
  const ResetPasswordPage({super.key, this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _email;
  final _otp = TextEditingController();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _email = TextEditingController(text: widget.email ?? "");
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  // ---------------------------
  // LOGIC (unchanged)
  // ---------------------------
  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _otp.text.trim();
    if (code.length != 6) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.invalid_code_short")),
        description: Text(tr("auth.invalid_code_email")),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isBusy = true);

    ResetPasswordCache.instance
      ..setEmail(_email.text.trim())
      ..setOtp(code);

    Navigator.pushNamed(
      context,
      AppRoutes.confirmPasswordReset,
      arguments: _email.text.trim().isEmpty ? null : _email.text.trim(),
    );

    if (mounted) setState(() => _isBusy = false);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: _GlassCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthUI.heading(tr("auth.reset_heading"), color: onSurface.withOpacity(0.96)),
              const SizedBox(height: 6),

              // subtitle visible in both themes (same vibe as title)
              Text(
                tr("auth.reset_sub"),
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
                hint: tr("auth.email_hint"),
                enabled: !_isBusy,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: HugeIcons.strokeRoundedMail01,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? tr("auth.email_required") : null,
              ),

              const SizedBox(height: 16),

              AuthUI.label(tr("auth.otp_code"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),

              _GlassField(
                controller: _otp,
                hint: tr("auth.otp_code"),
                enabled: !_isBusy,
                keyboardType: TextInputType.number,
                prefixIcon: HugeIcons.strokeRoundedKey01,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? tr("auth.otp_required") : null,
              ),

              const SizedBox(height: 18),

              _PrimaryPillButton(
                label: tr("auth.continue"),
                busy: _isBusy,
                onTap: _isBusy ? null : _onContinue,
              ),
            ],
          ),
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
            // button can keep gradient (premium), but no shadows
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                scheme.primary.withOpacity(0.88),
              ],
            ),
            boxShadow: const [],
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
