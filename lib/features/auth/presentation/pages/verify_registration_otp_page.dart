import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class ConfirmRegistrationOtpPage extends StatefulWidget {
  const ConfirmRegistrationOtpPage({super.key});

  @override
  State<ConfirmRegistrationOtpPage> createState() => _ConfirmRegistrationOtpPageState();
}

class _ConfirmRegistrationOtpPageState extends State<ConfirmRegistrationOtpPage> {
  final _email = TextEditingController();

  final List<TextEditingController> _c = [];
  final List<FocusNode> _f = [];

  bool _isBusy = false;
  String? _initialEmail;

  void _ensureOtpFields() {
    while (_c.length < 6) {
      _c.add(TextEditingController());
    }
    while (_f.length < 6) {
      _f.add(FocusNode());
    }
  }

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
    if (_otp.trim().length != 6) {
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: const Text("Invalid code"),
        description: const Text("Enter the 6-digit code we sent to your email."),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );
      return;
    }

    setState(() => _isBusy = true);
    try {
      final uri = Api.url(AuthEndpoints.registerVerify);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _email.text.trim(),
          "otp": _otp.trim(),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: const Text("Account verified"),
          description: const Text("You can now sign in to your account."),
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
        title: const Text("Verification failed"),
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
          description: const Text("Unable to verify account. Try again in a moment."),
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
    return "Invalid or expired code. Please try again.";
  }

  @override
  Widget build(BuildContext context) {
    _ensureOtpFields();
    // pick up email from navigation args once
    _initialEmail ??= ModalRoute.of(context)?.settings.arguments as String?;
    if ((_initialEmail ?? "").isNotEmpty && _email.text.isEmpty) {
      _email.text = _initialEmail!;
    }

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
      AuthUI.heading("Verify Account"),
      const SizedBox(height: 6),
      AuthUI.subheading("We just sent a 6-digit code to your email, enter it below:"),
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
            children: List.generate(6, (i) {
              return SizedBox(
                width: 48,
                height: 52,
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
