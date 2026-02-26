import "dart:convert";

import "package:flutter/material.dart";
import "package:flutter/foundation.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:hugeicons/hugeicons.dart";
import "package:intl_phone_field/intl_phone_field.dart";
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
  late final GoogleSignIn _googleSignIn;

  @override
  void initState() {
    super.initState();
    _googleSignIn = GoogleSignIn(
      clientId: Env.googleClientId,
      serverClientId: Env.googleClientId,
      scopes: ["email", "profile", "openid"],
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

    setState(() => _isBusy = true);

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
        description: Text(tr("auth.signup_retry")),
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
    return tr("auth.signup_retry");
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

  Future<void> _chooseCountry() async {
    final chosen = await showModalBottomSheet<WorldCountry?>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: CountryPicker(
              onSelect: (country) => Navigator.pop(context, country),
              showSearchBar: true,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        );
      },
    );

    if (chosen != null) {
      setState(() => _nationality.text = chosen.name.common);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUI.heading(tr("auth.sign_up")),
            const SizedBox(height: 6),
            AuthUI.subheading(tr("auth.sign_up_title")),
            const SizedBox(height: 26),

            AuthUI.label(tr("auth.name")),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              style: AuthUI.fieldTextStyle,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.name_hint"),
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedUser),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? tr("auth.name_required") : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label(tr("auth.email")),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              style: AuthUI.fieldTextStyle,
              keyboardType: TextInputType.emailAddress,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.email_hint"),
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedMail01),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? tr("auth.email_required") : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label(tr("auth.phone")),
            const SizedBox(height: 10),
            IntlPhoneField(
              controller: _phone,
              style: AuthUI.fieldTextStyle,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.phone_hint"),
              ).copyWith(
                // widen prefix area to avoid overflow with flag + dial code row
                prefixIconConstraints: const BoxConstraints(minWidth: 0, maxWidth: 120),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              ),
              initialCountryCode: "RW",
              dropdownIconPosition: IconPosition.trailing,
              dropdownIcon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.black.withOpacity(0.45)),
              showCountryFlag: !kIsWeb, // avoid web asset fetch failures
              flagsButtonPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              keyboardType: TextInputType.phone,
              validator: (phone) =>
                  (phone == null || phone.number.trim().isEmpty) ? tr("auth.phone_required") : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label(tr("auth.nationality")),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nationality,
              style: AuthUI.fieldTextStyle,
              readOnly: true,
              onTap: _chooseCountry,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.nationality_hint"),
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedGlobe),
                suffix: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Colors.black.withOpacity(0.45),
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr("auth.nationality_required") : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label(tr("auth.preferred_language")),
            const SizedBox(height: 10),
            SizedBox(
              height: 56,
              child: DropdownButtonFormField<String>(
                initialValue: _preferredLanguage,
                icon: const SizedBox.shrink(), // using custom suffix icon
                dropdownColor: Colors.white,
                decoration: AuthUI.fieldDecoration(
                  hint: tr("auth.preferred_language_hint"),
                  prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedMic01),
                  suffix: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
                style: AuthUI.fieldTextStyle.copyWith(fontWeight: FontWeight.w700),
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

            const SizedBox(height: 18),

            AuthUI.label(tr("auth.password")),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              style: AuthUI.fieldTextStyle,
              obscureText: _obscure1,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.password_hint"),
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedLockPassword),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                  icon: HugeIcon(
                    icon: _obscure1 ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                    size: 22,
                    strokeWidth: 2,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? tr("auth.password_required") : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label(tr("auth.confirm_password")),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPassword,
              style: AuthUI.fieldTextStyle,
              obscureText: _obscure2,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.confirm_password_hint"),
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedLockPassword),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                  icon: HugeIcon(
                    icon: _obscure2 ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                    size: 22,
                    strokeWidth: 2,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return tr("auth.confirm_password_required");
                if (v != _password.text) return tr("auth.passwords_mismatch");
                return null;
              },
            ),

            const SizedBox(height: 22),

            AuthUI.primaryPillButton(
              text: tr("auth.create_account"),
              busy: _isBusy,
              onPressed: _isBusy ? null : _onCreate,
            ),

            const SizedBox(height: 22),
            AuthUI.orDivider(),
            const SizedBox(height: 18),

            // Google (static)
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _isBusy ? null : _onGoogleSignUp,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.black.withOpacity(0.08)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleMark(),
                    const SizedBox(width: 12),
                    Text(
                      tr("auth.sign_in_google"),
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.70),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${tr("auth.have_account")} ",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.35),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: Text(
                    tr("auth.sign_in"),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
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
        child: Text("G", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}
