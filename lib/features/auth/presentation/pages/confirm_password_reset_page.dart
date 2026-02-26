import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/reset_password_cache.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class ConfirmPasswordResetPage extends StatefulWidget {
  final String? email;
  const ConfirmPasswordResetPage({super.key, this.email});

  @override
  State<ConfirmPasswordResetPage> createState() => _ConfirmPasswordResetPageState();
}

class _ConfirmPasswordResetPageState extends State<ConfirmPasswordResetPage> {
  final _formKey = GlobalKey<FormState>();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  late final String _email;
  late final String _otp;

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    final cache = ResetPasswordCache.instance;
    _email = widget.email ?? cache.email ?? "";
    _otp = cache.otp ?? "";
  }

  @override
  void dispose() {
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);

    try {
      final uri = Api.url(AuthEndpoints.passwordResetConfirm);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email,
          "otp": _otp,
          "new_password": _newPassword.text,
          "confirm_new_password": _confirmPassword.text,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ResetPasswordCache.instance.clear();

        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text("Password updated"),
          description: const Text("You can now sign in with your new password."),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );

        Navigator.pushReplacementNamed(context, AppRoutes.login);
        return;
      }

      final detail = _extractError(response);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text("Reset failed"),
        description: Text(detail),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 4),
      );
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text("Network error"),
          description: const Text("Unable to save password. Try again shortly."),
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
    return "We couldn't reset your password. Please double-check the code and try again.";
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
              style: AuthUI.fieldTextStyle,
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
              style: AuthUI.fieldTextStyle,
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
