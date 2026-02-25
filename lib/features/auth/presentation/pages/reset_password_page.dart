import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";

class ResetPasswordPage extends StatefulWidget {
  final String? email;
  const ResetPasswordPage({super.key, this.email});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _otp = TextEditingController();
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _email.text = widget.email ?? "";
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

    // TODO: Call API auth/password/reset/confirm/ here (email + otp) if needed.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isBusy = false);

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.confirmPasswordReset,
      arguments: _email.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Reset Password",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                final value = (v ?? "").trim();
                if (value.isEmpty) return "Email is required";
                if (!value.contains("@")) return "Enter a valid email";
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _otp,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "OTP",
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? "OTP is required" : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isBusy ? null : _onContinue,
              child: Text(_isBusy ? "Continuing..." : "Continue"),
            ),
          ],
        ),
      ),
    );
  }
}