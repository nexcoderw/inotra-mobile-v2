import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/registration_cache.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
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
        title: Text(tr("auth.invalid_code")),
        description: Text(tr("auth.invalid_code_desc")),
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
          title: Text(tr("auth.account_verified")),
          description: Text(tr("auth.account_verified_desc")),
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
        title: Text(tr("auth.verification_failed")),
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
          title: Text(tr("auth.network_error")),
          description: Text(tr("auth.verify_retry")),
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
    return tr("auth.invalid_code_desc");
  }

  @override
  Widget build(BuildContext context) {
    _ensureOtpFields();
    // pick up email from navigation args once
    _initialEmail ??=
        ModalRoute.of(context)?.settings.arguments as String? ?? RegistrationCache.instance.email;
    if ((_initialEmail ?? "").isNotEmpty && _email.text.isEmpty) {
      _email.text = _initialEmail!;
    }

    return AuthScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
      AuthUI.heading(tr("auth.verify_heading")),
      const SizedBox(height: 6),
      AuthUI.subheading(tr("auth.verify_desc")),
          const SizedBox(height: 26),

          AuthUI.label(tr("auth.email_label")),
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

          AuthUI.label(tr("auth.otp_code")),
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
            text: tr("auth.verify_heading"),
            busy: _isBusy,
            onPressed: _isBusy ? null : _verify,
          ),

          const SizedBox(height: 18),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${tr("auth.have_account")} ",
                style: TextStyle(
                  color: Colors.black.withOpacity(0.35),
                  fontWeight: FontWeight.w700,
                ),
              ),
              InkWell(
                onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                child: Text(
                  tr("auth.sign_in"),
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
