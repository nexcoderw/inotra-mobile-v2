import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/constants/app_colors.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _identifier = TextEditingController();
  final _password = TextEditingController();

  bool _rememberMe = false;
  bool _obscure = true;
  bool _isBusy = false;
  String? _error;

  @override
  void dispose() {
    _identifier.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isBusy = true;
      _error = null;
    });

    try {
      final uri = Api.url(AuthEndpoints.login);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "identifier": _identifier.text.trim(),
          "password": _password.text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _safeJson(response.body);
        final displayName =
            body?["user"]?["name"] as String? ?? _identifier.text.trim();

        AuthSession.instance.signIn(displayName: displayName);

        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text("Signed in"),
          description: const Text("Welcome back to Inotra."),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );

        Navigator.pushReplacementNamed(context, AppRoutes.home);
        return;
      }

      final detail = _extractError(response);
      _error = detail;

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text("Sign in failed"),
        description: Text(detail),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (e) {
      final message = "Unable to sign in. Please check your connection and try again.";
      _error = message;

      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text("Network error"),
          description: Text(message),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Map<String, dynamic>? _safeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(http.Response response) {
    final body = _safeJson(response.body);
    final detail = body?["detail"] ?? body?["message"] ?? body?["error"];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    return "Incorrect credentials. Please try again.";
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

            AuthUI.label("Email / Phone / Username"),
            const SizedBox(height: 10),

            TextFormField(
              controller: _identifier,
              style: AuthUI.fieldTextStyle,
              keyboardType: TextInputType.emailAddress,
              decoration: AuthUI.fieldDecoration(
                hint: "Enter email, phone number, or username",
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedUser),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Identifier is required" : null,
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
