import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";

class ConfirmPasswordResetPage extends StatefulWidget {
  final String? email;
  const ConfirmPasswordResetPage({super.key, this.email});

  @override
  State<ConfirmPasswordResetPage> createState() => _ConfirmPasswordResetPageState();
}

class _ConfirmPasswordResetPageState extends State<ConfirmPasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _isBusy = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onConfirm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);

    // TODO: Call API auth/password/reset/confirm/ (new password confirm endpoint) if required.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isBusy = false);
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Confirm Password Reset",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.email != null && widget.email!.isNotEmpty) ...[
              Text("Account: ${widget.email}"),
              const SizedBox(height: 10),
            ],
            TextFormField(
              controller: _newPassword,
              obscureText: _obscure1,
              decoration: InputDecoration(
                labelText: "New password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                  icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (v) {
                final value = v ?? "";
                if (value.isEmpty) return "New password is required";
                if (value.length < 6) return "Password must be at least 6 characters";
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _obscure2,
              decoration: InputDecoration(
                labelText: "Confirm new password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                  icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (v) {
                if ((v ?? "").isEmpty) return "Confirm password is required";
                if (v != _newPassword.text) return "Passwords do not match";
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isBusy ? null : _onConfirm,
              child: Text(_isBusy ? "Saving..." : "Confirm"),
            ),
          ],
        ),
      ),
    );
  }
}