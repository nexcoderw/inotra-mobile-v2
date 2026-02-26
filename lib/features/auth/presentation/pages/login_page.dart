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
import "../../../../i18n/translations.dart";
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
      serverClientId: Env.googleClientId, // request ID token usable by backend
      scopes: ["email", "profile", "openid"],
    );

    // Design-only: let fields react to typing (optional polish, no logic change)
    _identifier.addListener(() {
      if (mounted) setState(() {});
    });
    _password.addListener(() {
      if (mounted) setState(() {});
    });
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
    } catch (e) {
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
      if (idToken == null) {
        throw Exception("Missing Google ID token");
      }

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

        if (mounted) {
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
        }
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
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: Text(tr("auth.google_error")),
          description: Text(e.toString()),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: _GlassCard(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthUI.heading(tr("auth.sign_in")),
              const SizedBox(height: 6),

              // keep text as-is, just styled like confirm page
              Text(
                tr("auth.sign_in_title"),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: scheme.onSurface.withOpacity(0.92),
                ),
              ),

              const SizedBox(height: 18),

              AuthUI.label(tr("auth.identifier")),
              const SizedBox(height: 10),

              _GlassTextField(
                controller: _identifier,
                hint: tr("auth.identifier"),
                enabled: !_isBusy,
                keyboardType: TextInputType.emailAddress,
                prefixIcon: HugeIcons.strokeRoundedUser,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? tr("auth.identifier_required")
                    : null,
              ),

              const SizedBox(height: 16),

              AuthUI.label(tr("auth.password")),
              const SizedBox(height: 10),

              _GlassPasswordField(
                controller: _password,
                hint: tr("auth.password"),
                obscure: _obscure,
                enabled: !_isBusy,
                onToggle: () => setState(() => _obscure = !_obscure),
                validator: (v) => (v == null || v.isEmpty)
                    ? tr("auth.password_required")
                    : null,
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(999),
                    onTap: () => setState(() => _rememberMe = !_rememberMe),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  scheme.onSurface.withOpacity(0.35),
                              width: 1.4,
                            ),
                            color: _rememberMe
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: _rememberMe
                              ? const Icon(Icons.check,
                                  size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          tr("auth.remember_me"),
                          style: TextStyle(
                            color: scheme.onSurface.withOpacity(0.70),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(
                      context,
                      AppRoutes.forgotPassword,
                    ),
                    child: Text(
                      tr("auth.forgot_password"),
                      style: TextStyle(
                        color: scheme.onSurface.withOpacity(0.70),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor:
                            scheme.onSurface.withOpacity(0.70),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // same premium primary button + loader dots look
              _PrimaryButton(
                label: _isBusy ? tr("auth.wait") : tr("auth.sign_in"),
                busy: _isBusy,
                onTap: _isBusy ? null : _onLogin,
              ),

              const SizedBox(height: 14),

              // biometric button: keep same behavior, just re-styled
              Center(
                child: _CircleGlassButton(
                  enabled: !_isBusy,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(tr("auth.biometric_soon")),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedFaceId,
                    size: 30,
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              AuthUI.orDivider(),

              const SizedBox(height: 16),

              _GoogleGlassButton(
                enabled: !_isBusy,
                onTap: _isBusy ? null : _onGoogleLogin,
                label: tr("auth.sign_in_google"),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${tr("auth.no_account")} ",
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pushNamed(
                      context,
                      AppRoutes.register,
                    ),
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

class _GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final dynamic prefixIcon;
  final String? Function(String?) validator;

  const _GlassTextField({
    required this.controller,
    required this.hint,
    required this.enabled,
    required this.validator,
    required this.prefixIcon,
    this.keyboardType,
  });

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
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
            child: TextFormField(
              controller: widget.controller,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              cursorColor: scheme.primary,
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
                      icon: widget.prefixIcon,
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

  const _GlassPasswordField({
    required this.controller,
    required this.hint,
    required this.obscure,
    required this.onToggle,
    required this.enabled,
    required this.validator,
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
                    cursorColor: scheme.primary,
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

class _CircleGlassButton extends StatefulWidget {
  final bool enabled;
  final VoidCallback onTap;
  final Widget child;

  const _CircleGlassButton({
    required this.enabled,
    required this.onTap,
    required this.child,
  });

  @override
  State<_CircleGlassButton> createState() => _CircleGlassButtonState();
}

class _CircleGlassButtonState extends State<_CircleGlassButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.enabled ? widget.onTap : null,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
        scale: _pressed ? 0.985 : 1,
        child: ClipOval(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: scheme.primary.withOpacity(0.90),
                border: Border.all(
                  color: Colors.white.withOpacity(0.14),
                ),
              ),
              alignment: Alignment.center,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}

class _GoogleGlassButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback? onTap;
  final String label;

  const _GoogleGlassButton({
    required this.enabled,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.55),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const _GoogleMark(),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.80),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: const Center(
        child: Text(
          "G",
          style: TextStyle(fontWeight: FontWeight.w900),
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
          ),
          child: child,
        ),
      ),
    );
  }
}
