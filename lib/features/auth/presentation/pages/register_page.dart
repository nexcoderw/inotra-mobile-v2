import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _fullname = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _nationality = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  String _preferredLanguage = "English";
  bool _isBusy = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  static const _languages = <String>[
    "Kinyarwanda",
    "English",
    "French",
    "German",
    "Spanish",
  ];

  @override
  void dispose() {
    _fullname.dispose();
    _phone.dispose();
    _email.dispose();
    _nationality.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    // TODO: Call API auth/register/ here.
    await Future<void>.delayed(const Duration(milliseconds: 700));

    if (!mounted) return;
    setState(() => _isBusy = false);

    Navigator.pushReplacementNamed(
      context,
      AppRoutes.verifyRegistrationOtp,
      arguments: _email.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: "Create Account",
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _fullname,
              decoration: const InputDecoration(
                labelText: "Full name",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Full name is required" : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Phone number",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Phone number is required" : null,
            ),
            const SizedBox(height: 12),
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
              controller: _nationality,
              decoration: const InputDecoration(
                labelText: "Nationality",
                hintText: "e.g. Rwandan",
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Nationality is required" : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _preferredLanguage,
              items: _languages
                  .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                  .toList(),
              decoration: const InputDecoration(
                labelText: "Preferred language",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _preferredLanguage = v ?? "English"),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              obscureText: _obscure1,
              decoration: InputDecoration(
                labelText: "Password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                  icon: Icon(_obscure1 ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (v) {
                final value = v ?? "";
                if (value.isEmpty) return "Password is required";
                if (value.length < 6) return "Password must be at least 6 characters";
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _obscure2,
              decoration: InputDecoration(
                labelText: "Confirm password",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                  icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: (v) {
                if ((v ?? "").isEmpty) return "Confirm password is required";
                if (v != _password.text) return "Passwords do not match";
                return null;
              },
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _isBusy ? null : _onRegister,
              child: Text(_isBusy ? "Creating..." : "Register"),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }
}