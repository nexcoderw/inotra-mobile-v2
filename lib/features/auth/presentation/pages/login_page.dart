import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();
  bool _isBusy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isBusy = true);

    // TODO: Call API auth/login/ here.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;
    setState(() => _isBusy = false);
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Login",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _identifier,
              decoration: const InputDecoration(
                labelText: "Identifier",
                hintText: "Email or phone number",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Identifier is required" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Password is required" : null,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isBusy ? null : _onLogin,
              child: Text(_isBusy ? "Signing in..." : "Login"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
              child: const Text("Forgot password?"),
            ),
            const Divider(height: 28),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
              child: const Text("Create an account"),
            ),
          ],
        ),
      ),
    );
  }
}