import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";
import "package:http/http.dart" as http;

import "../../widgets/main_scaffold.dart";
import "../../widgets/page_header.dart";
import "../../../../../core/config/api.dart";
import "../../../../../core/constants/api/auth_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../core/services/language_service.dart";
import "../../../../../i18n/translations.dart";

class SettingsLanguagePage extends StatefulWidget {
  const SettingsLanguagePage({super.key});

  @override
  State<SettingsLanguagePage> createState() => _SettingsLanguagePageState();
}

class _SettingsLanguagePageState extends State<SettingsLanguagePage> {
  late String _selected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final current = AuthSession.instance.value.user?["preferred_language"] as String?;
    _selected = current?.isNotEmpty == true ? _normalizeToCode(current!) : "en";
  }

  String _normalizeToCode(String v) {
    final lower = v.toLowerCase();
    if (lower.startsWith("en")) return "en";
    if (lower.startsWith("rw")) return "rw";
    if (lower.startsWith("fr")) return "fr";
    if (lower.startsWith("es")) return "es";
    if (lower.startsWith("de")) return "de";
    return "en";
  }

  String _codeToBackendLabel(String code) => switch (code) {
        "rw" => "Kinyarwanda",
        "fr" => "French",
        "es" => "Spanish",
        "de" => "German",
        _ => "English",
      };

  Future<void> _select(String code) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final tokens = AuthSession.instance.value.accessToken;
      if (tokens == null || tokens.isEmpty) {
        throw Exception("Missing access token");
      }

      final uri = Api.url(AuthEndpoints.meLanguage);
      final response = await http.patch(
        uri,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $tokens",
        },
        body: jsonEncode({
          "preferred_language": _codeToBackendLabel(code),
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        _selected = code;
        await LanguageService.save(code);

        final current = AuthSession.instance.value.user ?? {};
        final updatedUser = {
          ...current,
          "preferred_language": code,
          "preferred_languages": [code],
        };
        AuthSession.instance.signIn(
          user: updatedUser,
          accessToken: AuthSession.instance.value.accessToken ?? "",
          refreshToken: AuthSession.instance.value.refreshToken ?? "",
          theme: AuthSession.instance.value.theme,
        );

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: Text(t(_selected, "settings.language")),
            description: Text("Language updated"),
            alignment: Alignment.topCenter,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
      } else {
        throw Exception("Status ${response.statusCode}");
      }
    } catch (e) {
      if (mounted) {
        toastification.show(
          context: context,
          type: ToastificationType.error,
          style: ToastificationStyle.fillColored,
          title: const Text("Update failed"),
          description: Text(e.toString()),
          alignment: Alignment.topCenter,
          autoCloseDuration: const Duration(seconds: 4),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Language",
      showAppBar: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const PageHeader(title: "Language"),
          const SizedBox(height: 10),
          Text(
            "Choose your preferred language",
            style: TextStyle(
              fontSize: 12,
              height: 1.25,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.68),
            ),
          ),
          const SizedBox(height: 14),
          ...supportedLanguages.map((code) => _LanguageTile(
                code: code,
                selected: _selected == code,
                onTap: () => _select(code),
              )),
        ],
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String code;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.code,
    required this.selected,
    required this.onTap,
  });

  String get _label => switch (code) {
        "en" => "English",
        "rw" => "Kinyarwanda",
        "fr" => "French",
        "es" => "Spanish",
        "de" => "German",
        _ => code,
      };

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: scheme.primary.withOpacity(0.12),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedLanguageSkill,
            size: 18,
            strokeWidth: 2,
            color: scheme.primary,
          ),
        ),
        title: Text(
          _label,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        trailing: selected
            ? Icon(Icons.check_circle, color: scheme.primary)
            : Icon(Icons.radio_button_unchecked, color: scheme.onSurface.withOpacity(0.4)),
        onTap: onTap,
      ),
    );
  }
}
