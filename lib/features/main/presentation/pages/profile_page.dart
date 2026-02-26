import "dart:convert";
import "dart:typed_data";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../core/config/api.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/api/auth_endpoints.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/auth_storage.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _phone;
  late String _preferredLanguage;
  Uint8List? _avatarBytes;
  String? _avatarName;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final user = AuthSession.instance.value.user ?? {};
    _name = TextEditingController(text: (user["name"] ?? "") as String);
    _username = TextEditingController(text: (user["username"] ?? "") as String);
    _phone = TextEditingController(text: (user["phone_number"] ?? "") as String);
    final preferred = user["preferred_language"] as String? ?? "en";
    _preferredLanguage = _normalize(preferred);
  }

  String _normalize(String v) {
    final l = v.toLowerCase();
    if (l.startsWith("rw")) return "rw";
    if (l.startsWith("fr")) return "fr";
    if (l.startsWith("es")) return "es";
    if (l.startsWith("de")) return "de";
    return "en";
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;
    setState(() {
      _avatarBytes = file.bytes;
      _avatarName = file.name;
    });
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
      final uri = Api.url(AuthEndpoints.meUpdate);
      final req = http.MultipartRequest("PATCH", uri);
      req.headers["Authorization"] = "Bearer $token";
      req.fields["name"] = _name.text.trim();
      req.fields["username"] = _username.text.trim();
      req.fields["phone_number"] = _phone.text.trim();
      req.fields["preferred_language"] = _codeToBackendLabel(_preferredLanguage);
      req.fields["preferred_languages"] = jsonEncode([_codeToBackendLabel(_preferredLanguage)]);

      if (_avatarBytes != null && _avatarName != null) {
        req.files.add(http.MultipartFile.fromBytes(
          "image",
          _avatarBytes!,
          filename: _avatarName!,
        ));
      }

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 401) {
        await AuthSession.instance.signOut();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
        return;
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = _safeJson(resp.body) ?? {};
        final updatedUser = body["user"] as Map<String, dynamic>? ?? body as Map<String, dynamic>? ?? {};
        // fallback: if API returns message only, keep old user
        final nextUser = updatedUser.isNotEmpty ? updatedUser : (session.user ?? {});

        await AuthStorage.saveSession(
          tokens: {
            "access": session.accessToken ?? "",
            "refresh": session.refreshToken ?? "",
          },
          user: nextUser,
          theme: session.theme,
        );
        AuthSession.instance.signIn(
          user: nextUser,
          accessToken: session.accessToken ?? "",
          refreshToken: session.refreshToken ?? "",
          theme: session.theme,
        );

        if (mounted) {
          toastification.show(
            context: context,
            type: ToastificationType.success,
            style: ToastificationStyle.fillColored,
            title: Text(t(_preferredLanguage, "auth.update_success")),
            description: Text(t(_preferredLanguage, "profile.user_profile")),
            alignment: Alignment.topCenter,
            autoCloseDuration: const Duration(seconds: 3),
          );
        }
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
      title: Text(t(_preferredLanguage, "auth.update_failed")),
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

  String _codeToBackendLabel(String code) => switch (code) {
        "rw" => "Kinyarwanda",
        "fr" => "French",
        "es" => "Spanish",
        "de" => "German",
        _ => "English",
      };

  @override
  Widget build(BuildContext context) {
    final lang = _preferredLanguage;
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "profile.title"),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _busy ? null : _pickAvatar,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: scheme.primary.withOpacity(0.12),
                          backgroundImage:
                              _avatarBytes != null ? MemoryImage(_avatarBytes!) : null,
                          child: _avatarBytes == null
                              ? Icon(Icons.person, size: 38, color: scheme.primary)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: scheme.primary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: scheme.surface, width: 2),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(lang, "profile.user_profile"),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            _Input(label: t(lang, "auth.name"), controller: _name),
            const SizedBox(height: 14),
            _Input(label: "Username", controller: _username),
            const SizedBox(height: 14),
            _Input(label: t(lang, "auth.phone"), controller: _phone, keyboard: TextInputType.phone),
            const SizedBox(height: 14),

            Text(
              t(lang, "auth.preferred_language"),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _preferredLanguage,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: "en", child: Text("English")),
                DropdownMenuItem(value: "rw", child: Text("Kinyarwanda")),
                DropdownMenuItem(value: "fr", child: Text("French")),
                DropdownMenuItem(value: "es", child: Text("Spanish")),
                DropdownMenuItem(value: "de", child: Text("German")),
              ],
              onChanged: (v) => setState(() => _preferredLanguage = v ?? "en"),
            ),

            const SizedBox(height: 20),

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
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _busy
                  ? null
                  : () {
                      AuthSession.instance.signOut();
                      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                    },
              child: Text(
                t(lang, "nav.logout"),
                style: TextStyle(
                  color: scheme.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboard;

  const _Input({
    required this.label,
    required this.controller,
    this.keyboard = TextInputType.text,
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
          keyboardType: keyboard,
          style: const TextStyle(color: Colors.black),
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? "$label is required" : null,
        ),
      ],
    );
  }
}
