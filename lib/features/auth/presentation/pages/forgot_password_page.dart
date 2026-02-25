import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";

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

  Future<void> _onRequest() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);

    // TODO: Call API auth/password/reset/request/ here.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isBusy = false);

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.resetPassword,
      arguments: _email.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Forgot Password",
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
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isBusy ? null : _onRequest,
              child: Text(_isBusy ? "Sending..." : "Send OTP"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
              child: const Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}