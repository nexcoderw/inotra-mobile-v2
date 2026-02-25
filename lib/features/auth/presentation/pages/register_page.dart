import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nationality = TextEditingController();

  String _preferredLanguage = "English";

  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _nationality.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onCreate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isBusy = false);

    Navigator.pushNamed(context, AppRoutes.confirmRegistrationOtp);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUI.heading("Sign Up"),
            const SizedBox(height: 6),
            AuthUI.subheading("Please enter your information to proceed"),
            const SizedBox(height: 26),

            AuthUI.label("Name"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _name,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter your name",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedUser),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Name is required" : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label("Email"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter your email",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedMail01),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Email is required" : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label("Phone number"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: AuthUI.fieldDecoration(
                hint: "780 000 000",
                prefix: const _PhonePrefix(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? "Phone is required" : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label("Nationality"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _nationality,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter your Nationality",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedGlobe),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Nationality is required" : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label("Preferred Language"),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _preferredLanguage,
              items: const [
                DropdownMenuItem(value: "Kinyarwanda", child: Text("Kinyarwanda")),
                DropdownMenuItem(value: "English", child: Text("English")),
                DropdownMenuItem(value: "French", child: Text("French")),
                DropdownMenuItem(value: "German", child: Text("German")),
                DropdownMenuItem(value: "Spanish", child: Text("Spanish")),
              ],
              decoration: AuthUI.fieldDecoration(
                hint: "Choose Language",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedMic01),
              ),
              onChanged: (v) => setState(() => _preferredLanguage = v ?? "English"),
            ),

            const SizedBox(height: 18),

            AuthUI.label("Password"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _password,
              obscureText: _obscure1,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter password",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedLockPassword),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                  icon: HugeIcon(
                    icon: _obscure1 ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
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

            AuthUI.label("Confirm Password"),
            const SizedBox(height: 10),
            TextFormField(
              controller: _confirmPassword,
              obscureText: _obscure2,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter Confirm Password",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedLockPassword),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                  icon: HugeIcon(
                    icon: _obscure2 ? HugeIcons.strokeRoundedViewOff : HugeIcons.strokeRoundedView,
                    size: 22,
                    strokeWidth: 2,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Confirm password is required";
                if (v != _password.text) return "Passwords do not match";
                return null;
              },
            ),

            const SizedBox(height: 22),

            AuthUI.primaryPillButton(
              text: "Create Account",
              busy: _isBusy,
              onPressed: _isBusy ? null : _onCreate,
            ),

            const SizedBox(height: 22),
            AuthUI.orDivider(),
            const SizedBox(height: 18),

            // Google (static)
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Google sign up coming soon"),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide(color: Colors.black.withOpacity(0.08)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _GoogleMark(),
                    const SizedBox(width: 12),
                    Text(
                      "Continue with Google",
                      style: TextStyle(
                        color: Colors.black.withOpacity(0.70),
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already have an account ",
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

class _PhonePrefix extends StatelessWidget {
  const _PhonePrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 14, right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.black.withOpacity(0.10)),
              color: const Color(0xFF2D9CDB),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 7,
                decoration: const BoxDecoration(
                  color: Color(0xFFF2C94C),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text("+250", style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(width: 6),
          Icon(Icons.keyboard_arrow_down_rounded, color: Colors.black.withOpacity(0.40)),
          const SizedBox(width: 6),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: const Center(
        child: Text("G", style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}