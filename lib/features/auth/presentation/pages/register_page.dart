import "dart:convert";
import "dart:io" show Platform;
import "dart:math" as math;
import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart" show kIsWeb;
import "package:google_sign_in/google_sign_in.dart";
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";
import "package:http/http.dart" as http;
import "package:world_countries/world_countries.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/config/env.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/registration_cache.dart";
import "../../../../core/services/auth_storage.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nationality = TextEditingController();

  String _preferredLanguage = "English";

  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isBusy = false;
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    final iosClient = (!kIsWeb && Platform.isIOS)
        ? "859455003917-g57ugmgdbdbch1kur95ssq3ma0i9dvgo.apps.googleusercontent.com"
        : null;
    _googleSignIn = GoogleSignIn(
      clientId: iosClient,
      serverClientId: Env.googleClientId,
      scopes: const ["email", "profile", "openid"],
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _nationality.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  // ---------------------------
  // LOGIC (unchanged)
  // ---------------------------

  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);

    try {
      final uri = Api.url(AuthEndpoints.register);
      final response = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": _name.text.trim(),
              "email": _email.text.trim(),
              "phone_number": _normalizedPhone(_phone.text.trim()),
              "nationality": _nationality.text.trim(),
              "preferred_languages": [_preferredLanguage],
              "password": _password.text,
              "confirm_password": _confirmPassword.text,
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text(tr("auth.account_created")),
          description: Text(tr("auth.check_email_code")),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );

        RegistrationCache.instance.setEmail(_email.text.trim());

        Navigator.pushNamed(
          context,
          AppRoutes.verifyRegistrationOtp,
          arguments: _email.text.trim().isEmpty ? null : _email.text.trim(),
        );
        return;
      }

      final detail = _extractError(response);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.signup_failed")),
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
        title: Text(tr("auth.network_error")),
        description: Text(e.toString()),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 6),
      );
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
    return tr("auth.signup_retry");
  }

  String _normalizedPhone(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return value;
    if (value.startsWith("00")) return "+${value.substring(2)}";
    if (value.startsWith("+")) return value;
    final digits = value.replaceAll(RegExp(r"[^0-9]"), "");
    return "+$digits";
  }

  Future<void> _onGoogleSignUp() async {
    setState(() => _isBusy = true);
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
        body: jsonEncode({"IdToken": idToken}),
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

  Future<void> _chooseCountry() async {
    final chosen = await showModalBottomSheet<WorldCountry?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.72,
                  decoration: BoxDecoration(
                    color: scheme.surface.withOpacity(0.70),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
                  ),
                  child: CountryPicker(
                    onSelect: (country) => Navigator.pop(context, country),
                    showSearchBar: true,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (chosen != null) {
      setState(() => _nationality.text = chosen.name.common);
    }
  }

  // ---------------------------
  // UI (premium)
  // ---------------------------

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
              AuthUI.heading(tr("auth.sign_up"), color: onSurface.withOpacity(0.96)),
              const SizedBox(height: 6),
              Text(
                tr("auth.sign_up_title"),
                style: TextStyle(
                  fontSize: 12,
                  height: 1.25,
                  fontWeight: FontWeight.w600,
                  color: onSurface.withOpacity(0.88),
                ),
              ),
              const SizedBox(height: 18),

              // Name
              AuthUI.label(tr("auth.name"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _name,
                hint: tr("auth.name_hint"),
                enabled: !_isBusy,
                prefixIcon: HugeIcons.strokeRoundedUser,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? tr("auth.name_required") : null,
              ),

              const SizedBox(height: 14),

              // Email
              AuthUI.label(tr("auth.email"), color: onSurface.withOpacity(0.92)),
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

              const SizedBox(height: 14),

              // Phone (simple input; ask for country code in placeholder)
              AuthUI.label(tr("auth.phone"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassWrap(
                child: TextFormField(
                  controller: _phone,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withOpacity(0.92),
                  ),
                  keyboardType: TextInputType.phone,
                  decoration: _glassInputDecoration(
                    context,
                    hint: "${tr("auth.phone_hint")} (+ country code)",
                  ).copyWith(
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, maxWidth: 120),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? tr("auth.phone_required") : null,
                ),
              ),

              const SizedBox(height: 14),

              // Nationality (picker unchanged)
              AuthUI.label(tr("auth.nationality"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _nationality,
                hint: tr("auth.nationality_hint"),
                enabled: !_isBusy,
                readOnly: true,
                onTap: _chooseCountry,
                prefixIcon: HugeIcons.strokeRoundedGlobe,
                suffix: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: onSurface.withOpacity(0.55),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? tr("auth.nationality_required")
                    : null,
              ),

              const SizedBox(height: 14),

              // Preferred language (same logic)
              AuthUI.label(tr("auth.preferred_language"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassWrap(
                child: DropdownButtonFormField<String>(
                  initialValue: _preferredLanguage,
                  icon: const SizedBox.shrink(),
                  dropdownColor: scheme.surface,
                  decoration: _glassInputDecoration(
                    context,
                    hint: tr("auth.preferred_language_hint"),
                    prefixIcon: HugeIcons.strokeRoundedMic01,
                    suffix: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: onSurface.withOpacity(0.60),
                    ),
                  ).copyWith(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withOpacity(0.92),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Kinyarwanda", child: Text("Kinyarwanda")),
                    DropdownMenuItem(value: "English", child: Text("English")),
                    DropdownMenuItem(value: "French", child: Text("French")),
                    DropdownMenuItem(value: "German", child: Text("German")),
                    DropdownMenuItem(value: "Spanish", child: Text("Spanish")),
                  ],
                  onChanged: (v) => setState(() => _preferredLanguage = v ?? "English"),
                ),
              ),

              const SizedBox(height: 14),

              // Password
              AuthUI.label(tr("auth.password"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _password,
                hint: tr("auth.password_hint"),
                enabled: !_isBusy,
                obscure: _obscure1,
                prefixIcon: HugeIcons.strokeRoundedLockPassword,
                suffix: IconButton(
                  onPressed: _isBusy ? null : () => setState(() => _obscure1 = !_obscure1),
                  icon: HugeIcon(
                    icon: _obscure1
                        ? HugeIcons.strokeRoundedViewOff
                        : HugeIcons.strokeRoundedView,
                    size: 14,
                    strokeWidth: 2,
                    color: onSurface.withOpacity(0.65),
                  ),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? tr("auth.password_required") : null,
              ),

              const SizedBox(height: 14),

              // Confirm password
              AuthUI.label(tr("auth.confirm_password"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _confirmPassword,
                hint: tr("auth.confirm_password_hint"),
                enabled: !_isBusy,
                obscure: _obscure2,
                prefixIcon: HugeIcons.strokeRoundedLockPassword,
                suffix: IconButton(
                  onPressed: _isBusy ? null : () => setState(() => _obscure2 = !_obscure2),
                  icon: HugeIcon(
                    icon: _obscure2
                        ? HugeIcons.strokeRoundedViewOff
                        : HugeIcons.strokeRoundedView,
                    size: 14,
                    strokeWidth: 2,
                    color: onSurface.withOpacity(0.65),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return tr("auth.confirm_password_required");
                  if (v != _password.text) return tr("auth.passwords_mismatch");
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Create account (premium loader)
              _PrimaryPillButton(
                label: tr("auth.create_account"),
                busy: _isBusy,
                onTap: _isBusy ? null : _onCreate,
              ),

              const SizedBox(height: 18),
              AuthUI.orDivider(),
              const SizedBox(height: 14),

              // Google (same logic)
              _GoogleButton(
                busy: _isBusy,
                onTap: _isBusy ? null : _onGoogleSignUp,
                label: tr("auth.sign_in_google"),
              ),

              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${tr("auth.have_account")} ",
                    style: TextStyle(
                      color: onSurface.withOpacity(0.60),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  InkWell(
                    onTap: _isBusy
                        ? null
                        : () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                    child: Text(
                      tr("auth.sign_in"),
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                        decorationColor: scheme.primary,
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
// Premium building blocks (UI-only, no logic changes)
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
            color: scheme.surface.withOpacity(0.55),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GlassWrap extends StatefulWidget {
  final Widget child;
  const _GlassWrap({required this.child});

  @override
  State<_GlassWrap> createState() => _GlassWrapState();
}

class _GlassWrapState extends State<_GlassWrap> {
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
            child: widget.child,
          ),
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
    this.readOnly = false,
    this.onTap,
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
              obscureText: widget.obscure,
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/images/google.png",
      width: 22,
      height: 22,
      filterQuality: FilterQuality.high,
    );
  }
}
