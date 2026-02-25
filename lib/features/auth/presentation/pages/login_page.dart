import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/app_colors.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _password = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;
  bool _isBusy = false;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;
    setState(() => _isBusy = false);

    // static navigation for now
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthUI.heading("Sign in"),
            const SizedBox(height: 6),
            AuthUI.subheading("Please enter your information to proceed"),
            const SizedBox(height: 26),

            AuthUI.label("Phone number"),
            const SizedBox(height: 10),

            TextFormField(
              controller: _phone,
              style: AuthUI.fieldTextStyle,
              keyboardType: TextInputType.phone,
              decoration: AuthUI.fieldDecoration(
                hint: "780 000 000",
                prefix: _PhonePrefix(
                  code: "+250",
                  onTap: () {
                    // static for now; later can open country picker
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Country picker coming soon"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Phone number is required" : null,
            ),

            const SizedBox(height: 18),

            AuthUI.label("Password"),
            const SizedBox(height: 10),

            TextFormField(
              controller: _password,
              obscureText: _obscure,
              style: AuthUI.fieldTextStyle,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter password",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedLockPassword),
                suffix: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: HugeIcon(
                    icon: _obscure
                        ? HugeIcons.strokeRoundedViewOff
                        : HugeIcons.strokeRoundedView,
                    size: 18,
                    strokeWidth: 2,
                    color: Colors.black.withOpacity(0.55),
                  ),
                ),
              ),
              validator: (v) =>
                  (v == null || v.isEmpty) ? "Password is required" : null,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.30),
                            width: 1.4,
                          ),
                          color: _rememberMe ? AppColors.primary : Colors.transparent,
                        ),
                        child: _rememberMe
                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        "Remember me",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.60),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, AppRoutes.forgotPassword),
                  child: Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.55),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.black.withOpacity(0.55),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                // Sign In pill
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isBusy ? null : _onLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: Text(
                        _isBusy ? "Signing In..." : "Sign In",
                        style: AuthUI.buttonTextStyle,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Biometric circle button
                SizedBox(
                  width: 48,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Biometric sign-in coming soon"),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: const CircleBorder(),
                    ),
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedFaceId,
                      size: 32,
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            AuthUI.orDivider(),

            const SizedBox(height: 18),

            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Google login coming soon"),
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
                        fontSize: 14,
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
                  "Don't have an account? ",
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.35),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.register),
                  child: Text(
                    "Sign Up",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.primary,
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
  final String code;
  final VoidCallback onTap;

  const _PhonePrefix({
    required this.code,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 14, right: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Static Rwanda flag look (no extra assets needed)
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
            Text(
              code,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.black.withOpacity(0.40),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    // Simple “G” mark without assets; replace later with actual Google icon if needed
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: const Center(
        child: Text(
          "G",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}
