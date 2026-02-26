import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/reset_password_cache.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _onReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    try {
      final uri = Api.url(AuthEndpoints.passwordResetRequest);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _email.text.trim()}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ResetPasswordCache.instance
          ..setEmail(_email.text.trim())
          ..setOtp(null);

        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text("Reset email sent"),
          description: const Text("Check your email for the 6-digit code."),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );

        Navigator.pushNamed(
          context,
          AppRoutes.resetPassword,
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
        title: const Text("Reset failed"),
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
          title: const Text("Network error"),
          description: const Text("Unable to request reset. Try again shortly."),
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
    return "Could not start password reset. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUI.heading("Forget Password"),
            const SizedBox(height: 6),
            AuthUI.subheading("Please enter your information to proceed"),
            const SizedBox(height: 26),

            AuthUI.label("Email"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              style: AuthUI.fieldTextStyle,
              keyboardType: TextInputType.emailAddress,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter your email",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedMail01),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Email is required" : null,
            ),

            const SizedBox(height: 18),

            AuthUI.primaryPillButton(
              text: "Reset Password",
              busy: _isBusy,
              onPressed: _isBusy ? null : _onReset,
            ),

            const SizedBox(height: 22),
            AuthUI.orDivider(),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Back to ",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.35),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
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
