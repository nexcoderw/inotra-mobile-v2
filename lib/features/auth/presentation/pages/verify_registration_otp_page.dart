import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class ConfirmRegistrationOtpPage extends StatefulWidget {
  const ConfirmRegistrationOtpPage({super.key});

  @override
  State<ConfirmRegistrationOtpPage> createState() => _ConfirmRegistrationOtpPageState();
}

class _ConfirmRegistrationOtpPageState extends State<ConfirmRegistrationOtpPage> {
  final _email = TextEditingController(text: "example@email.com");

  final _c = List.generate(5, (_) => TextEditingController());
  final _f = List.generate(5, (_) => FocusNode());

  bool _isBusy = false;

  @override
  void dispose() {
    _email.dispose();
    for (final c in _c) {
      c.dispose();
    }
    for (final f in _f) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _c.map((e) => e.text).join();

  Future<void> _verify() async {
    if (_otp.trim().length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Enter the 5-digit code"),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isBusy = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isBusy = false);

    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AuthUI.heading("Verify Account"),
          const SizedBox(height: 6),
          AuthUI.subheading("We just sent 5-digit code to your email, enter it bellow:"),
          const SizedBox(height: 26),

          AuthUI.label("Email"),
          const SizedBox(height: 10),
          TextFormField(
            controller: _email,
            readOnly: true,
            style: AuthUI.fieldTextStyle,
            decoration: AuthUI.fieldDecoration(
              hint: "",
              prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedMail01),
            ),
          ),

          const SizedBox(height: 18),

          AuthUI.label("OTP Code"),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(5, (i) {
              return SizedBox(
                width: 58,
                height: 58,
                child: TextField(
                  controller: _c[i],
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
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty && i < 4) {
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

          const SizedBox(height: 22),

          AuthUI.primaryPillButton(
            text: "Verify Account",
            busy: _isBusy,
            onPressed: _isBusy ? null : _verify,
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Back to? ",
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
    );
  }
}
