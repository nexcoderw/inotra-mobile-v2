import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class ConfirmPasswordResetPage extends StatefulWidget {
  const ConfirmPasswordResetPage({super.key});

  @override
  State<ConfirmPasswordResetPage> createState() => _ConfirmPasswordResetPageState();
}

class _ConfirmPasswordResetPageState extends State<ConfirmPasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isBusy = false);

    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUI.heading("Set New Password"),
            const SizedBox(height: 6),
            AuthUI.subheading("Create new password"),
            const SizedBox(height: 26),

            AuthUI.label("New Password"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _newPassword,
              obscureText: _obscure1,
              decoration: AuthUI.fieldDecoration(
                hint: "**********",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedLockPassword),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                  icon: HugeIcon(
                    icon: _obscure1
                        ? HugeIcons.strokeRoundedViewOff
                        : HugeIcons.strokeRoundedView,
                    size: 22,
                    strokeWidth: 2,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Password is required" : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label("Confirm New Password"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _obscure2,
              decoration: AuthUI.fieldDecoration(
                hint: "**********",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedLockPassword),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                  icon: HugeIcon(
                    icon: _obscure2
                        ? HugeIcons.strokeRoundedViewOff
                        : HugeIcons.strokeRoundedView,
                    size: 22,
                    strokeWidth: 2,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Confirm password is required";
                if (v != _newPassword.text) return "Passwords do not match";
                return null;
              },
            ),

            const SizedBox(height: 22),

            AuthUI.primaryPillButton(
              text: "Save Changes",
              busy: _isBusy,
              onPressed: _isBusy ? null : _onSave,
            ),
          ],
        ),
      ),
    );
  }
}