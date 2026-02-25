import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";

class VerifyRegistrationOtpPage extends StatefulWidget {
  final String? email;
  const VerifyRegistrationOtpPage({super.key, this.email});

  @override
  State<VerifyRegistrationOtpPage> createState() => _VerifyRegistrationOtpPageState();
}

class _VerifyRegistrationOtpPageState extends State<VerifyRegistrationOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _otp.dispose();
    super.dispose();
  }

  Future<void> _onVerify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);

    // TODO: Call API auth/register/verify/ here.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isBusy = false);
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Confirm Registration OTP",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.email != null && widget.email!.isNotEmpty) ...[
              Text("OTP sent to: ${widget.email}"),
              const SizedBox(height: 10),
            ],
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
              onPressed: _isBusy ? null : _onVerify,
              child: Text(_isBusy ? "Verifying..." : "Verify"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.login,
                (_) => false,
              ),
              child: const Text("Back to Login"),
            ),
          ],
        ),
      ),
    );
  }
}