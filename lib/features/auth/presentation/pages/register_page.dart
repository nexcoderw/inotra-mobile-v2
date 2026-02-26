import "dart:convert";
import "dart:math" as math;
import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:hugeicons/hugeicons.dart";
import "package:intl_phone_field/intl_phone_field.dart";
import "package:intl_phone_field/phone_number.dart";
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
import "../../../../i18n/translations.dart";
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
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _nationality.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final uri = Api.url(AuthEndpoints.register);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": _name.text.trim(),
          "email": _email.text.trim(),
          "phone_number": _phone.text.trim(),
          "nationality": _nationality.text.trim(),
          "preferred_languages": [_preferredLanguage],
          "password": _password.text,
          "confirm_password": _confirmPassword.text,
        }),
      );

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
      _error = detail;

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
    } catch (_) {
      final message = tr("auth.signup_retry");
      _error = message;

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.network_error")),
        description: Text(message),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
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

  Future<void> _onGoogleSignUp() async {
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

  Future<void> _chooseCountry() async {
    final chosen = await showModalBottomSheet<WorldCountry?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: _GlassCard(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.72,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    // keep it readable even in dark mode for the picker internals
                    canvasColor: scheme.surface,
                  ),
                  child: CountryPicker(
                    onSelect: (country) => Navigator.pop(context, country),
                    showSearchBar: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
    final onSurface = scheme.onSurface;

    final score = _passwordScore(_password.text);
    final match = _confirmPassword.text.isNotEmpty && _confirmPassword.text == _password.text;

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
              const SizedBox(height: 16),

              if (_error != null && _error!.trim().isNotEmpty) ...[
                _ErrorPill(text: _error!),
                const SizedBox(height: 14),
              ],

              AuthUI.label(tr("auth.name"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _name,
                hint: tr("auth.name_hint"),
                prefixIcon: HugeIcons.strokeRoundedUser,
                enabled: !_isBusy,
                validator: (v) => (v == null || v.trim().isEmpty) ? tr("auth.name_required") : null,
              ),

              const SizedBox(height: 14),

              AuthUI.label(tr("auth.email"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _email,
                hint: tr("auth.email_hint"),
                keyboardType: TextInputType.emailAddress,
                prefixIcon: HugeIcons.strokeRoundedMail01,
                enabled: !_isBusy,
                validator: (v) => (v == null || v.trim().isEmpty) ? tr("auth.email_required") : null,
              ),

              const SizedBox(height: 14),

              AuthUI.label(tr("auth.phone"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassPhoneField(
                controller: _phone,
                enabled: !_isBusy,
                initialCountryCode: "RW",
                validator: (phone) => (phone == null || phone.number.trim().isEmpty)
                    ? tr("auth.phone_required")
                    : null,
              ),

              const SizedBox(height: 14),

              // Nationality + Preferred language (same row)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthUI.label(tr("auth.nationality"), color: onSurface.withOpacity(0.92)),
                        const SizedBox(height: 10),
                        _GlassField(
                          controller: _nationality,
                          hint: tr("auth.nationality_hint"),
                          prefixIcon: HugeIcons.strokeRoundedGlobe,
                          enabled: !_isBusy,
                          readOnly: true,
                          onTap: _isBusy ? null : _chooseCountry,
                          suffix: HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowDown01,
                            size: 14,
                            strokeWidth: 2,
                            color: onSurface.withOpacity(0.55),
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? tr("auth.nationality_required")
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AuthUI.label(
                          tr("auth.preferred_language"),
                          color: onSurface.withOpacity(0.92),
                        ),
                        const SizedBox(height: 10),
                        _GlassDropdown(
                          value: _preferredLanguage,
                          enabled: !_isBusy,
                          prefixIcon: HugeIcons.strokeRoundedLanguageSkill,
                          items: const [
                            "Kinyarwanda",
                            "English",
                            "French",
                            "German",
                            "Spanish",
                          ],
                          onChanged: (v) => setState(() => _preferredLanguage = v ?? "English"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Strength row (premium, subtle)
              _StrengthRow(score: score, label: _passwordLabel(score)),

              const SizedBox(height: 14),

              AuthUI.label(tr("auth.password"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _password,
                hint: tr("auth.password_hint"),
                prefixIcon: HugeIcons.strokeRoundedLockPassword,
                enabled: !_isBusy,
                obscure: _obscure1,
                suffix: IconButton(
                  onPressed: _isBusy ? null : () => setState(() => _obscure1 = !_obscure1),
                  icon: HugeIcon(
                    icon: _obscure1 ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                    size: 14,
                    strokeWidth: 2,
                    color: onSurface.withOpacity(0.65),
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? tr("auth.password_required") : null,
              ),

              const SizedBox(height: 14),

              AuthUI.label(tr("auth.confirm_password"), color: onSurface.withOpacity(0.92)),
              const SizedBox(height: 10),
              _GlassField(
                controller: _confirmPassword,
                hint: tr("auth.confirm_password_hint"),
                prefixIcon: HugeIcons.strokeRoundedLockPassword,
                enabled: !_isBusy,
                obscure: _obscure2,
                trailingBadge: _MatchBadge(
                  visible: _confirmPassword.text.isNotEmpty,
                  ok: match,
                ),
                suffix: IconButton(
                  onPressed: _isBusy ? null : () => setState(() => _obscure2 = !_obscure2),
                  icon: HugeIcon(
                    icon: _obscure2 ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
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

              _PrimaryPillButton(
                label: tr("auth.create_account"),
                busy: _isBusy,
                onTap: _isBusy ? null : _onCreate,
              ),

              const SizedBox(height: 18),

              AuthUI.orDivider(),
              const SizedBox(height: 14),

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
// Premium pieces (glass, loaders, badges)
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
            // ✅ no border / no shadow / no gradient
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
  final bool obscure;
  final dynamic prefixIcon;
  final Widget? suffix;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? Function(String?) validator;
  final Widget? trailingBadge;

  const _GlassField({
    required this.controller,
    required this.hint,
    required this.validator,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.obscure = false,
    this.suffix,
    this.readOnly = false,
    this.onTap,
    this.trailingBadge,
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
            child: Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: widget.controller,
                    enabled: widget.enabled,
                    obscureText: widget.obscure,
                    keyboardType: widget.keyboardType,
                    cursorColor: scheme.primary,
                    readOnly: widget.readOnly,
                    onTap: widget.onTap,
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
                        color: scheme.onSurface.withOpacity(0.45),
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
                            color: scheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ),
                      suffixIcon: widget.suffix,
                    ),
                    validator: widget.validator,
                  ),
                ),
                if (widget.trailingBadge != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: widget.trailingBadge!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPhoneField extends StatefulWidget {
  final TextEditingController controller;
  final bool enabled;
  final String initialCountryCode;
  final String? Function(PhoneNumber?) validator;

  const _GlassPhoneField({
    required this.controller,
    required this.enabled,
    required this.initialCountryCode,
    required this.validator,
  });

  @override
  State<_GlassPhoneField> createState() => _GlassPhoneFieldState();
}

class _GlassPhoneFieldState extends State<_GlassPhoneField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final borderColor = _focused
        ? scheme.primary.withOpacity(0.32)
        : scheme.onSurface.withOpacity(0.10);

    return SizedBox(
      height: 56,
      child: Focus(
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
              child: IntlPhoneField(
                controller: widget.controller,
                enabled: widget.enabled,
                initialCountryCode: widget.initialCountryCode,
                dropdownIconPosition: IconPosition.trailing,
                dropdownIcon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
                showCountryFlag: !kIsWeb,
                flagsButtonPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                keyboardType: TextInputType.phone,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withOpacity(0.92),
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: false,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  prefixIconConstraints:
                      BoxConstraints(minWidth: 0, maxWidth: 120),
                ),
                validator: widget.validator,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassDropdown extends StatelessWidget {
  final String value;
  final bool enabled;
  final dynamic prefixIcon;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _GlassDropdown({
    required this.value,
    required this.enabled,
    required this.prefixIcon,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(0.55),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.onSurface.withOpacity(0.10), width: 1),
          ),
          child: Row(
            children: [
              const SizedBox(width: 12),
              HugeIcon(
                icon: prefixIcon,
                size: 14,
                strokeWidth: 2,
                color: scheme.onSurface.withOpacity(0.65),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isExpanded: true,
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowDown01,
                      size: 14,
                      strokeWidth: 2,
                      color: scheme.onSurface.withOpacity(0.55),
                    ),
                    dropdownColor: scheme.surface,
                    onChanged: enabled ? onChanged : null,
                    items: items
                        .map((e) => DropdownMenuItem<String>(
                              value: e,
                              child: Text(
                                e,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface.withOpacity(0.92),
                                ),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
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
          backgroundColor: scheme.surface.withOpacity(0.45),
          side: BorderSide(color: scheme.onSurface.withOpacity(0.10)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _GoogleMark(),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: scheme.onSurface.withOpacity(0.85),
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: scheme.onSurface.withOpacity(0.10)),
        color: scheme.surface.withOpacity(0.55),
      ),
      child: Center(
        child: Text(
          "G",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withOpacity(0.85),
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
            color: scheme.error.withOpacity(0.10),
            border: Border.all(color: scheme.error.withOpacity(0.25)),
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
                    color: scheme.onSurface.withOpacity(0.90),
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
