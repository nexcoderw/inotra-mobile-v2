import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
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
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isBusy = false);

    Navigator.pushNamed(context, AppRoutes.resetPassword);
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