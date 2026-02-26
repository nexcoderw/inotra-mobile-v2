import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/config/api.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/reset_password_cache.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/auth_scaffold.dart";
import "../widgets/auth_ui.dart";

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _isBusy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _onReset() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isBusy = true);
    try {
      final uri = Api.url(AuthEndpoints.passwordResetRequest);
      final response = await http.post(
        uri,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": _email.text.trim()}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ResetPasswordCache.instance
          ..setEmail(_email.text.trim())
          ..setOtp(null);

        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text(tr("auth.reset_email_sent")),
          description: Text(tr("auth.reset_email_desc")),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );

        Navigator.pushNamed(
          context,
          AppRoutes.resetPassword,
          arguments: _email.text.trim().isEmpty ? null : _email.text.trim(),
        );
        return;
      }

      final detail = _extractError(response);
      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.error,
        style: ToastificationStyle.fillColored,
        title: Text(tr("auth.reset_failed")),
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
          description: Text(tr("auth.reset_retry")),
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
    return tr("auth.reset_retry");
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
              style: AuthUI.fieldTextStyle,
              keyboardType: TextInputType.emailAddress,
              decoration: AuthUI.fieldDecoration(
                hint: tr("auth.email_hint"),
                prefix: AuthUI.prefixIcon(HugeIcons.strokeRoundedMail01),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? tr("auth.email_required") : null,
            ),

            const SizedBox(height: 18),

            AuthUI.primaryPillButton(
              text: tr("auth.reset_action"),
              busy: _isBusy,
              onPressed: _isBusy ? null : _onReset,
            ),

            const SizedBox(height: 22),
            AuthUI.orDivider(),
            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "${tr("auth.back_to")} ",
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
      ),
    );
  }
}
