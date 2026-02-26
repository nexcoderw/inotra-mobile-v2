import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/auth_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../widgets/main_scaffold.dart";
import "../../widgets/page_header.dart";

class ProfileChangePasswordPage extends StatefulWidget {
  const ProfileChangePasswordPage({super.key});

  @override
  State<ProfileChangePasswordPage> createState() => _ProfileChangePasswordPageState();
}

class _ProfileChangePasswordPageState extends State<ProfileChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _ob1 = true;
  bool _ob2 = true;
  bool _busy = false;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    return MainScaffold(
      title: t(lang, "profile.change_password"),
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          PageHeader(
            title: t(lang, "profile.change_password"),
            onBack: () => Navigator.of(context).pop(),
          ),
          _Input(
            label: t(lang, "profile.current_password"),
            controller: _current,
            obscure: true,
            requiredMessage: t(lang, "auth.required_field"),
          ),
          const SizedBox(height: 14),
          _Input(
            label: t(lang, "profile.new_password"),
            controller: _new,
            obscure: _ob1,
            toggle: () => setState(() => _ob1 = !_ob1),
            requiredMessage: t(lang, "auth.required_field"),
          ),
          const SizedBox(height: 14),
          _Input(
            label: t(lang, "profile.confirm_password"),
            controller: _confirm,
            obscure: _ob2,
            toggle: () => setState(() => _ob2 = !_ob2),
            requiredMessage: t(lang, "auth.required_field"),
            validator: (v) {
              if (v == null || v.isEmpty) return t(lang, "auth.required_field");
              if (v != _new.text) return t(lang, "auth.passwords_mismatch");
              return null;
            },
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _busy ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _busy
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    )
                  : Text(
                      t(lang, "auth.save_changes"),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final session = AuthSession.instance.value;
    final token = session.accessToken ?? "";
    if (token.isEmpty) {
      await AuthSession.instance.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }
    try {
      final uri = Api.url(AuthEndpoints.mePasswordChange);
      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "current_password": _current.text,
          "new_password": _new.text,
          "confirm_new_password": _confirm.text,
        }),
      );

      if (resp.statusCode == 401) {
        await AuthSession.instance.signOut();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
        return;
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        await AuthSession.instance.signOut();
        if (!mounted) return;
        toastification.show(
          context: context,
          type: ToastificationType.success,
          style: ToastificationStyle.fillColored,
          title: Text(t(currentLangSync(), "auth.password_updated")),
          description: Text(t(currentLangSync(), "auth.password_updated_desc")),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 3),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
        return;
      }

      _showError(resp);
    } catch (e) {
      _showError(null, fallback: e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(http.Response? resp, {String? fallback}) {
    final detail = resp != null ? _extractError(resp) : (fallback ?? "Update failed");
    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: Text(t(currentLangSync(), "auth.update_failed")),
      description: Text(detail),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }

  Map<String, dynamic>? _safeJson(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  String _extractError(http.Response response) {
    final body = _safeJson(response.body);
    final detail = body?["detail"] ?? body?["message"] ?? body?["error"];
    if (detail is String && detail.trim().isNotEmpty) return detail.trim();
    return "Update failed (${response.statusCode})";
  }
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback? toggle;
  final String requiredMessage;
  final String? Function(String?)? validator;

  const _Input({
    required this.label,
    required this.controller,
    this.obscure = false,
    this.toggle,
    required this.requiredMessage,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(color: Colors.black, fontSize: 12),
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            suffixIcon: toggle == null
                ? null
                : IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 18,
                      color: scheme.onSurface.withOpacity(0.65),
                    ),
                    onPressed: toggle,
                  ),
          ),
          validator: validator ??
              (v) => (v == null || v.trim().isEmpty) ? requiredMessage : null,
        ),
      ],
    );
  }
}
