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
    final cachedEmail = ResetPasswordCache.instance.email;
    _email = TextEditingController(text: widget.email ?? cachedEmail ?? "");
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);

    try {
      final uri = Api.url(AuthEndpoints.passwordResetResend);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text.trim(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ResetPasswordCache.instance
          ..setEmail(_email.text.trim())
          ..setOtp(_otp.text.trim());

        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text("Code accepted"),
          description: const Text("Enter your new password on the next step."),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );

        Navigator.pushNamed(
          context,
          AppRoutes.confirmPasswordReset,
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
        title: const Text("OTP check failed"),
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
          description: const Text("Unable to verify code. Try again shortly."),
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
    return "The code could not be verified. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUI.heading("Reset Password"),
            const SizedBox(height: 6),
            AuthUI.subheading("Enter your email and OTP code"),
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

            AuthUI.label("OTP Code"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _otp,
              style: AuthUI.fieldTextStyle,
              keyboardType: TextInputType.number,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter OTP",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedKey01),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "OTP is required" : null,
            ),

            const SizedBox(height: 18),

            AuthUI.primaryPillButton(
              text: "Continue",
              busy: _isBusy,
              onPressed: _isBusy ? null : _onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
