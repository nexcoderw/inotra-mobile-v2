import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _email.dispose();
    _otp.dispose();
    super.dispose();
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isBusy = false);

    Navigator.pushNamed(context, AppRoutes.confirmPasswordReset);
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