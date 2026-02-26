import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
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

class ProfileDangerZonePage extends StatefulWidget {
  const ProfileDangerZonePage({super.key});

  @override
  State<ProfileDangerZonePage> createState() => _ProfileDangerZonePageState();
}

class _ProfileDangerZonePageState extends State<ProfileDangerZonePage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    return MainScaffold(
      title: t(lang, "profile.danger_zone"),
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          PageHeader(
            title: t(lang, "profile.danger_zone"),
            onBack: () => Navigator.of(context).pop(),
            icon: HugeIcons.strokeRoundedArrowLeft01,
          ),
          const SizedBox(height: 12),
          _DangerCard(
            color: scheme.error,
            title: t(lang, "profile.deactivate"),
            description: t(lang, "profile.deactivate_desc"),
            actionLabel: t(lang, "profile.deactivate_action"),
            busy: _busy,
            onConfirm: () => _doAction(AuthEndpoints.meDeactivate),
          ),
          const SizedBox(height: 12),
          _DangerCard(
            color: Colors.red.shade900,
            title: t(lang, "profile.delete_account"),
            description: t(lang, "profile.delete_desc"),
            actionLabel: t(lang, "profile.delete_action"),
            busy: _busy,
            onConfirm: () => _doAction(AuthEndpoints.meDeleteRequest),
          ),
        ],
      ),
    );
  }

  Future<void> _doAction(String endpoint) async {
    setState(() => _busy = true);
    final session = AuthSession.instance.value;
    final token = session.accessToken ?? "";
    if (token.isEmpty) {
      await AuthSession.instance.signOut();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      return;
    }
    try {
      final uri = Api.url(endpoint);
      final resp = await http.post(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({}),
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
          title: Text(t(currentLangSync(), "auth.update_success")),
          description: Text(t(currentLangSync(), "profile.danger_zone")),
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
    final detail = resp != null ? _extractError(resp) : (fallback ?? "Action failed");
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
    return "Action failed (${response.statusCode})";
  }
}

class _DangerCard extends StatelessWidget {
  final Color color;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onConfirm;
  final bool busy;

  const _DangerCard({
    required this.color,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onConfirm,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: color,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(fontSize: 12, height: 1.3),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: busy ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: busy
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
