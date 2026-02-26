import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/reset_password_cache.dart";
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
  final List<TextEditingController> _otp = [];
  final List<FocusNode> _f = [];
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final cachedEmail = ResetPasswordCache.instance.email;
    _email = TextEditingController(text: widget.email ?? cachedEmail ?? "");
  }

  @override
  void dispose() {
    _email.dispose();
    for (final c in _otp) {
      c.dispose();
    }
    for (final f in _f) {
      f.dispose();
    }
    super.dispose();
  }

  void _ensureOtpFields() {
    while (_otp.length < 6) {
      _otp.add(TextEditingController());
    }
    while (_f.length < 6) {
      _f.add(FocusNode());
    }
  }

  Future<void> _onContinue() async {
    _ensureOtpFields();
    if (!_formKey.currentState!.validate()) return;

    final otp = _otp.map((e) => e.text).join().trim();
    if (otp.length != 6) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text("Invalid code"),
        description: const Text("Enter the 6-digit code we emailed you."),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isBusy = true);

    ResetPasswordCache.instance
      ..setEmail(_email.text.trim())
      ..setOtp(otp);

    if (mounted) {
      Navigator.pushNamed(
        context,
        AppRoutes.confirmPasswordReset,
        arguments: _email.text.trim().isEmpty ? null : _email.text.trim(),
      );
    }

    if (mounted) setState(() => _isBusy = false);
  }

  @override
  Widget build(BuildContext context) {
    _ensureOtpFields();
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
              style: AuthUI.fieldTextStyle,
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
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 48,
                  height: 52,
                  child: TextField(
                    controller: _otp[i],
                    focusNode: _f[i],
                    style: AuthUI.fieldTextStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 1,
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: const Color(0xFFF3F4F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _f[i + 1].requestFocus();
                      }
                      if (v.isEmpty && i > 0) {
                        _f[i - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
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
