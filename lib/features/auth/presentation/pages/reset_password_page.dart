import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/reset_password_cache.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
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
        title: Text(tr("auth.invalid_code_short")),
        description: Text(tr("auth.invalid_code_email")),
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
            AuthUI.heading(tr("auth.reset_heading")),
            const SizedBox(height: 6),
            AuthUI.subheading(tr("auth.reset_sub")),
            const SizedBox(height: 26),

            AuthUI.label(tr("auth.email_label")),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              style: AuthUI.fieldTextStyle.copyWith(color: Colors.black),
              keyboardType: TextInputType.emailAddress,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.email_hint"),
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedMail01),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr("auth.email_required") : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label(tr("auth.otp_code")),
            const SizedBox(height: 10),
            TextFormField(
              controller: _otp,
              style: AuthUI.fieldTextStyle.copyWith(color: Colors.black),
              keyboardType: TextInputType.number,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.otp_code"),
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedKey01),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr("auth.otp_required") : null,
            ),

            const SizedBox(height: 18),

            AuthUI.primaryPillButton(
              text: tr("auth.continue"),
              busy: _isBusy,
              onPressed: _isBusy ? null : _onContinue,
            ),
          ],
        ),
      ),
    );
  }
}
