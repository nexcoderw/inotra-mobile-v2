import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
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
    _email = TextEditingController(text: widget.email ?? "");
  }

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;
    final code = _otp.text.trim();
    if (code.length != 6) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text("Invalid code"),
        description: const Text("Enter the 6-digit code we emailed you."),
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
