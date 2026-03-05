import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/config/env.dart";
import "../../../../core/constants/app_colors.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/auth_storage.dart";
import "../../../../i18n/lang.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;
  bool _isBusy = false;
  String? _error;
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      clientId: Env.googleClientId,
      serverClientId: Env.googleClientId,
      scopes: const ["email", "profile", "openid"],
    );
  }

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final uri = Api.url(AuthEndpoints.login);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": _identifier.text.trim(),
          "password": _password.text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _safeJson(response.body);
        final tokens = body?["tokens"] as Map<String, dynamic>? ?? {};
        final user = body?["user"] as Map<String, dynamic>? ?? {};

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
          title: Text(tr("auth.signed_in")),
          description: Text(tr("auth.welcome_back")),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );

        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return;
      }

      final detail = _extractError(response);
      _error = detail;

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.login_failed")),
        description: Text(detail),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (_) {
      final message = tr("auth.network_retry");
      _error = message;

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: Text(tr("auth.network_error")),
          description: Text(message),
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
    return tr("auth.incorrect_credentials");
  }

  Future<void> _onGoogleLogin() async {
    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        if (mounted) setState(() => _isBusy = false);
        return;
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) throw Exception("Missing Google ID token");

      final uri = Api.url(AuthEndpoints.googleLogin);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"token": idToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _safeJson(response.body);
        final tokens = body?["tokens"] as Map<String, dynamic>? ?? {};
        final user = body?["user"] as Map<String, dynamic>? ?? {};

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
          title: Text(tr("auth.google_success")),
          description: Text(tr("auth.welcome")),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return;
      }

      final detail = _extractError(response);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.google_error")),
        description: Text(detail),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.google_error")),
        description: Text(e.toString()),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
              // Title
              AuthUI.heading(
                tr("auth.sign_in"),
                color: onSurface.withValues(alpha: 0.96),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                tr("auth.sign_in_title"),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withValues(alpha: 0.88),
                ),
              ),

              const SizedBox(height: 18),

              // Error chip
              if (_error != null && _error!.trim().isNotEmpty) ...[
                _ErrorPill(text: _error!),
                const SizedBox(height: 14),
              ],

              // Identifier
              AuthUI.label(tr("auth.identifier"), color: onSurface.withValues(alpha: 0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _identifier,
                hint: tr("auth.identifier"),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isBusy,
                prefixIcon: HugeIcons.strokeRoundedUser,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? tr("auth.identifier_required")
                    : null,
              ),

              const SizedBox(height: 14),

              // Password
              AuthUI.label(tr("auth.password"), color: onSurface.withValues(alpha: 0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _password,
                hint: tr("auth.password"),
                obscure: _obscure,
                enabled: !_isBusy,
                prefixIcon: HugeIcons.strokeRoundedLockPassword,
                suffix: IconButton(
                  onPressed: _isBusy ? null : () => setState(() => _obscure = !_obscure),
                  icon: HugeIcon(
                    icon: _obscure
                        ? HugeIcons.strokeRoundedViewOff
                        : HugeIcons.strokeRoundedView,
                    size: 14,
                    strokeWidth: 2,
                    color: onSurface.withValues(alpha: 0.65),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? tr("auth.password_required")
                    : null,
              ),

              const SizedBox(height: 12),

              // Remember + forgot
              Row(
                children: [
                  _RememberMe(
                    value: _rememberMe,
                    enabled: !_isBusy,
                    onChanged: (v) => setState(() => _rememberMe = v),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _isBusy
                        ? null
                        : () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                    child: Text(
                      tr("auth.forgot_password"),
                      style: TextStyle(
                        color: onSurface.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Actions row
              Row(
                children: [
                  Expanded(
                    child: _PrimaryPillButton(
                      label: tr("auth.sign_in"),
                      busy: _isBusy,
                      onTap: _isBusy ? null : _onLogin,
                    ),
                  ),
                  const SizedBox(width: 12),
                  _IconCircleButton(
                    icon: HugeIcons.strokeRoundedFaceId,
                    busy: _isBusy,
                    onTap: _isBusy
                        ? null
                        : () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tr("auth.biometric_soon")),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                  ),
                ],
              ),

              const SizedBox(height: 18),

              AuthUI.orDivider(),

              const SizedBox(height: 14),

              // Google
              _GoogleButton(
                busy: _isBusy,
                onTap: _isBusy ? null : _onGoogleLogin,
                label: tr("auth.sign_in_google"),
              ),

              const SizedBox(height: 16),

              // Sign up
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${tr("auth.no_account")} ",
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.60),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  InkWell(
                    onTap: _isBusy ? null : () => Navigator.pushNamed(context, AppRoutes.register),
                    child: Text(
                      tr("auth.sign_up"),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.primary,
                      ),
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
}

// ---------------------------
// Premium widgets (glass + micro-interactions)
// ---------------------------

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
            color: scheme.surface.withValues(alpha: 0.55),
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
  final bool obscure;
  final dynamic prefixIcon;
  final Widget? suffix;
  final String? Function(String?) validator;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.obscure = false,
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
        ? scheme.primary.withValues(alpha: 0.32)
        : scheme.onSurface.withValues(alpha: 0.10);

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
              color: scheme.surface.withValues(alpha: 0.55),
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
                color: scheme.onSurface.withValues(alpha: 0.92),
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.45),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: InputBorder.none,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Center(
                    widthFactor: 1,
                    child: HugeIcon(
                      icon: widget.prefixIcon,
                      size: 14,
                      strokeWidth: 2,
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                ),
                suffixIcon: widget.suffix,
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ),
    );
  }
}

class _RememberMe extends StatelessWidget {
  final bool value;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _RememberMe({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = scheme.onSurface;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: enabled ? () => onChanged(!value) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: onSurface.withValues(alpha: 0.28),
                  width: 1.4,
                ),
                color: value ? scheme.primary : Colors.transparent,
              ),
              child: value
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            Text(
              tr("auth.remember_me"),
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.76),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
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
                scheme.primary.withValues(alpha: 0.88),
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

class _IconCircleButton extends StatelessWidget {
  final dynamic icon;
  final bool busy;
  final VoidCallback? onTap;

  const _IconCircleButton({
    required this.icon,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: onTap,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.55),
                border: Border.all(color: scheme.onSurface.withValues(alpha: 0.10)),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: HugeIcon(
                  icon: icon,
                  size: 22,
                  strokeWidth: 2.2,
                  color: scheme.primary,
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
  final String label;

  const _GoogleButton({
    required this.busy,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 56,
      child: OutlinedButton(
        onPressed: busy ? null : onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: scheme.surface.withValues(alpha: 0.45),
          side: BorderSide(color: scheme.onSurface.withValues(alpha: 0.10)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: busy
              ? SizedBox(
                  key: const ValueKey("spinner"),
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onSurface.withValues(alpha: 0.55),
                  ),
                )
              : Row(
                  key: const ValueKey("label"),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleMark(),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: TextStyle(
                        color: scheme.onSurface.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ErrorPill extends StatelessWidget {
  final String text;
  const _ErrorPill({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.error.withValues(alpha: 0.10),
            border: Border.all(color: scheme.error.withValues(alpha: 0.25)),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(Icons.error_rounded, size: 16, color: scheme.error),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.90),
                  ),
                ),
              ),
            ],
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
                color: Colors.white.withValues(alpha: 0.75 + b * 0.25),
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

/* -------------------------------- Google Brand Mark -------------------------------- */

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _GoogleGPainter()),
    );
  }
}

class _GoogleGPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  const _GoogleGPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Clip everything to the outer circle so bar edges are clean
    canvas.save();
    canvas.clipPath(Path()..addOval(rect));

    void arc(Color color, double startAngle, double sweepAngle) {
      final path = Path()
        ..moveTo(c.dx, c.dy)
        ..arcTo(rect, startAngle, sweepAngle, false)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }

    // Four color segments (0 rad = 3 o'clock, clockwise positive)
    // Blue:   -30° → 90°   (120° sweep) — top-right
    // Red:     90° → 210°  (120° sweep) — left
    // Yellow: 210° → 270°  ( 60° sweep) — bottom-left
    // Green:  270° → 330°  ( 60° sweep) — bottom-right
    arc(_blue,   -math.pi / 6,       2 * math.pi / 3);
    arc(_red,     math.pi / 2,       2 * math.pi / 3);
    arc(_yellow,  7 * math.pi / 6,   math.pi / 3);
    arc(_green,   3 * math.pi / 2,   math.pi / 3);

    // Blue horizontal bar — the crossbar of the G (from center rightward)
    final barHalf = r * 0.28;
    canvas.drawRect(
      Rect.fromLTRB(c.dx, c.dy - barHalf, r * 2, c.dy + barHalf),
      Paint()..color = _blue,
    );

    // Inner donut hole (white)
    canvas.drawCircle(c, r * 0.58, Paint()..color = Colors.white);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
