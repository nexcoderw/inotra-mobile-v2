import "dart:convert";
import "dart:typed_data";
import "dart:ui";

import "package:file_picker/file_picker.dart";
import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/auth_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../core/services/auth_storage.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../widgets/main_scaffold.dart";
import "../../widgets/page_header.dart";

class ProfileAccountDetailsPage extends StatefulWidget {
  const ProfileAccountDetailsPage({super.key});

  @override
  State<ProfileAccountDetailsPage> createState() =>
      _ProfileAccountDetailsPageState();
}

class _ProfileAccountDetailsPageState extends State<ProfileAccountDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _username;
  late final TextEditingController _phone;
  late final TextEditingController _email;

  Uint8List? _avatarBytes;
  String? _avatarName;
  bool _busy = false;
  String _currentPhoneIso = "RW";

  @override
  void initState() {
    super.initState();
    final user = AuthSession.instance.value.user ?? {};
    _name = TextEditingController(text: (user["name"] ?? "") as String);
    _username = TextEditingController(text: (user["username"] ?? "") as String);
    final phoneRaw = (user["phone_number"] ?? "") as String;
    final normalized = _normalizePhone(phoneRaw, _currentPhoneIso);
    _phone = TextEditingController(text: normalized);
    _email = TextEditingController(text: (user["email"] ?? "") as String);
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "profile.account_details"),
      showAppBar: false,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            PageHeader(
              title: t(lang, "profile.account_details"),
              onBack: () => Navigator.of(context).pop(),
            ),
            const SizedBox(height: 10),

            // ✅ Premium glass header (avatar + hint)
            _GlassCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _AvatarPicker(
                    bytes: _avatarBytes,
                    imageUrl:
                        AuthSession.instance.value.user?["image"] as String?,
                    onPick: _pickAvatar,
                    busy: _busy,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t(lang, "profile.user_profile"),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t(lang, "profile.account_details_sub"),
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.2,
                      color: scheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ✅ Glass form container
            _GlassCard(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
              child: Column(
                children: [
                  _Input(
                    label: t(lang, "auth.name"),
                    controller: _name,
                    requiredMessage: t(lang, "auth.required_field"),
                    icon: HugeIcons.strokeRoundedUser,
                    enabled: !_busy,
                    badge: _FieldBadge.required,
                  ),
                  const SizedBox(height: 12),
                  _Input(
                    label: t(lang, "auth.username"),
                    controller: _username,
                    requiredMessage: t(lang, "auth.required_field"),
                    icon: HugeIcons.strokeRoundedUserIdVerification,
                    enabled: !_busy,
                    badge: _FieldBadge.required,
                  ),
                  const SizedBox(height: 12),
                  _Input(
                    label: t(lang, "auth.phone"),
                    controller: _phone,
                    keyboard: TextInputType.phone,
                    requiredMessage: t(lang, "auth.required_field"),
                    icon: HugeIcons.strokeRoundedCall,
                    enabled: !_busy,
                    badge: _FieldBadge.required,
                    hint:
                        "${t(lang, 'auth.phone_hint')} (+ country code)",
                  ),
                  const SizedBox(height: 12),
                  _Input(
                    label: t(lang, "auth.email"),
                    controller: _email,
                    readOnly: true,
                    requiredMessage: t(lang, "auth.required_field"),
                    icon: HugeIcons.strokeRoundedMail01,
                    enabled: false,
                    badge: _FieldBadge.readonly,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ✅ Premium primary CTA
            _PrimaryButton(
              label: t(lang, "auth.save_changes"),
              busy: _busy,
              onTap: _busy ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
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
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
      }
      return;
    }

    try {
      final uri = Api.url(AuthEndpoints.meUpdate);
      final req = http.MultipartRequest("PATCH", uri);
      req.headers["Authorization"] = "Bearer $token";
      req.fields["name"] = _name.text.trim();
      req.fields["username"] = _username.text.trim();
      req.fields["phone_number"] = _normalizePhone(_phone.text.trim(), _currentPhoneIso);

      if (_avatarBytes != null && _avatarName != null) {
        req.files.add(
          http.MultipartFile.fromBytes(
            "image",
            _avatarBytes!,
            filename: _avatarName!,
          ),
        );
      }

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode == 401) {
        await AuthSession.instance.signOut();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
        }
        return;
      }

      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final body = _safeJson(resp.body) ?? {};
        final updatedUser = body["user"] as Map<String, dynamic>? ??
            body as Map<String, dynamic>? ??
            {};
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
            title: Text(t(currentLangSync(), "auth.update_success")),
            description: Text(t(currentLangSync(), "profile.account_details")),
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

  (String, String) _splitPhone(String raw) {
    if (raw.isEmpty) return ("RW", "");
    var p = raw.trim();
    if (p.startsWith("+")) p = p.substring(1);
    // Extract leading country code digits (up to 3)
    String code = "250";
    String number = p;
    if (p.startsWith("250")) {
      code = "250";
      number = p.substring(3);
    } else if (p.startsWith("33")) {
      code = "33";
      number = p.substring(2);
    } else if (p.startsWith("49")) {
      code = "49";
      number = p.substring(2);
    } else if (p.startsWith("34")) {
      code = "34";
      number = p.substring(2);
    } else if (p.startsWith("44")) {
      code = "44";
      number = p.substring(2);
    } else if (p.startsWith("1")) {
      code = "1";
      number = p.substring(1);
    } else if (p.startsWith("0")) {
      code = "250";
      number = p.substring(1);
    }
    final iso = _guessIso("+$code");
    return (iso, number);
  }

  String _normalizePhone(String raw, String iso) {
    if (raw.isEmpty) return raw;
    if (raw.startsWith("+")) return raw;
    final digits = raw.replaceAll(RegExp(r"[^0-9]"), "");
    final dial = _isoToDial(iso);
    if (digits.startsWith(dial)) return "+$digits";
    if (digits.startsWith("0")) return "+$dial${digits.substring(1)}";
    return "+$dial$digits";
  }

  String _guessIso(String phone) {
    final p = phone.trim();
    if (p.startsWith("+250")) return "RW";
    if (p.startsWith("+33")) return "FR";
    if (p.startsWith("+49")) return "DE";
    if (p.startsWith("+34")) return "ES";
    if (p.startsWith("+44")) return "GB";
    if (p.startsWith("+1")) return "US";
    if (p.startsWith("250")) return "RW";
    return "RW";
  }

  String _isoToDial(String iso) => switch (iso.toUpperCase()) {
        "RW" => "250",
        "FR" => "33",
        "DE" => "49",
        "ES" => "34",
        "GB" => "44",
        "US" => "1",
        _ => "250",
      };
}

class _AvatarPicker extends StatefulWidget {
  final Uint8List? bytes;
  final String? imageUrl;
  final VoidCallback onPick;
  final bool busy;

  const _AvatarPicker({
    required this.bytes,
    required this.imageUrl,
    required this.onPick,
    required this.busy,
  });

  @override
  State<_AvatarPicker> createState() => _AvatarPickerState();
}

class _AvatarPickerState extends State<_AvatarPicker> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final ImageProvider<Object>? image = widget.bytes != null
        ? MemoryImage(widget.bytes!)
        : (widget.imageUrl != null && widget.imageUrl!.isNotEmpty
            ? NetworkImage(widget.imageUrl!)
            : null);

    final isActive = _pressed || _hovered;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTap: widget.busy ? null : widget.onPick,
        onTapDown: widget.busy ? null : (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          scale: _pressed ? 0.98 : 1,
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.10),
                      blurRadius: 16,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: scheme.primary.withOpacity(0.12),
                  backgroundImage: image,
                  child: image == null
                      ? Icon(Icons.person, size: 40, color: scheme.primary)
                      : null,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  color: scheme.primary,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: scheme.surface, width: 2),
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 14, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _FieldBadge { required, optional, readonly }

class _Input extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboard;
  final String requiredMessage;
  final bool readOnly;
  final dynamic icon;
  final bool enabled;
  final _FieldBadge badge;
  final String? hint;

  const _Input({
    required this.label,
    required this.controller,
    this.keyboard = TextInputType.text,
    required this.requiredMessage,
    this.readOnly = false,
    required this.icon,
    this.enabled = true,
    this.badge = _FieldBadge.required,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _LabelRow(label: label, badge: badge),
        const SizedBox(height: 8),
        _GlassTextField(
          controller: controller,
          keyboard: keyboard,
          readOnly: readOnly,
          enabled: enabled,
          hintText: hint ?? label,
          prefixIcon: icon,
          validator: (v) => readOnly
              ? null
              : (v == null || v.trim().isEmpty)
                  ? requiredMessage
                  : null,
        ),
      ],
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final _FieldBadge badge;

  const _LabelRow({required this.label, required this.badge});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    final badgeText = switch (badge) {
      _FieldBadge.required => t(lang, "form.required"),
      _FieldBadge.optional => t(lang, "form.optional"),
      _FieldBadge.readonly => t(lang, "form.readonly"),
    };
    final badgeColor = switch (badge) {
      _FieldBadge.required => scheme.primary.withOpacity(0.12),
      _FieldBadge.optional => scheme.onSurface.withOpacity(0.08),
      _FieldBadge.readonly => scheme.onSurface.withOpacity(0.06),
    };
    final badgeTextColor = switch (badge) {
      _FieldBadge.required => scheme.primary.withOpacity(0.95),
      _FieldBadge.optional => scheme.onSurface.withOpacity(0.70),
      _FieldBadge.readonly => scheme.onSurface.withOpacity(0.70),
    };

    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withOpacity(0.92),
          ),
        ),
        const SizedBox(width: 8),
        _Badge(
          text: badgeText,
          background: badgeColor,
          foreground: badgeTextColor,
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;

  const _Badge({
    required this.text,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

// Phone field removed in favor of simpler text input (handled by _Input)

class _GlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final TextInputType keyboard;
  final bool readOnly;
  final bool enabled;
  final String hintText;
  final dynamic prefixIcon;
  final String? Function(String?)? validator;

  const _GlassTextField({
    required this.controller,
    required this.keyboard,
    required this.readOnly,
    required this.enabled,
    required this.hintText,
    required this.prefixIcon,
    required this.validator,
  });

  @override
  State<_GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<_GlassTextField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final borderColor = _focused
        ? scheme.primary.withOpacity(0.35)
        : scheme.onSurface.withOpacity(0.10);

    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: TextFormField(
              controller: widget.controller,
              keyboardType: widget.keyboard,
              readOnly: widget.readOnly,
              enabled: widget.enabled,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurface.withOpacity(0.92),
              ),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: scheme.onSurface.withOpacity(0.45),
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                border: InputBorder.none,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(left: 12, right: 8),
                  child: Center(
                    widthFactor: 1,
                    child: widget.prefixIcon is IconData
                        ? Icon(
                            widget.prefixIcon as IconData,
                            size: 14,
                            color: scheme.primary.withOpacity(0.95),
                          )
                        : HugeIcon(
                            icon: widget.prefixIcon,
                            size: 14,
                            strokeWidth: 2,
                            color: scheme.primary.withOpacity(0.95),
                          ),
                  ),
                ),
              ),
              validator: widget.validator,
            ),
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatefulWidget {
  final String label;
  final bool busy;
  final VoidCallback? onTap;

  const _PrimaryButton({
    required this.label,
    required this.busy,
    required this.onTap,
  });

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;
  bool _hovered = false;

  void _setPressed(bool v) => setState(() => _pressed = v);
  void _setHovered(bool v) => setState(() => _hovered = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        onTapDown: widget.onTap == null ? null : (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOut,
          scale: _pressed ? 0.99 : 1,
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: widget.onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: scheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                widget.busy ? t(currentLangSync(), "auth.wait") : widget.label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: scheme.surface.withOpacity(0.55),
            border: Border.all(
              color: scheme.onSurface.withOpacity(0.10),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
