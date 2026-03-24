import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/my_event_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../../../main/presentation/widgets/page_header.dart";

const double _kDeletePageFontSize = 12;

class MyEventDeletePage extends StatefulWidget {
  final String? eventId;
  final String? title;

  const MyEventDeletePage({super.key, this.eventId, this.title});

  @override
  State<MyEventDeletePage> createState() => _MyEventDeletePageState();
}

class _MyEventDeletePageState extends State<MyEventDeletePage> {
  final TextEditingController _confirmationCtrl = TextEditingController();
  bool _busy = false;

  String get _lang => currentLangSync();

  String get _eventTitle {
    final raw = widget.title?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return "Event";
  }

  bool get _canDelete =>
      !_busy &&
      (widget.eventId?.trim().isNotEmpty ?? false) &&
      _confirmationCtrl.text.trim().toUpperCase() == "DELETE";

  @override
  void dispose() {
    _confirmationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Theme(
      data: _buildPageTheme(context),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
          children: [
            PageHeader(
              title: t(_lang, "my_events.delete_event"),
              titleStyle: const TextStyle(
                fontSize: _kDeletePageFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: "DMSans",
              ),
            ),
            const SizedBox(height: 10),
            const _HeroCard(
              title: "Delete this event permanently",
              subtitle:
                  "This action removes the event from your portfolio and customers will no longer be able to discover it.",
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: "Event summary",
              icon: Icons.event_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: "Event", value: _eventTitle),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: "Event ID",
                    value: widget.eventId?.trim().isNotEmpty == true
                        ? widget.eventId!.trim()
                        : "Unavailable",
                    subtle: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const _SectionCard(
              title: "What will happen",
              icon: Icons.warning_amber_rounded,
              child: Column(
                children: [
                  _ImpactTile(
                    icon: Icons.event_busy_outlined,
                    title: "The event will be removed",
                    subtitle:
                        "Attendees will no longer see it in the explore experience.",
                  ),
                  SizedBox(height: 12),
                  _ImpactTile(
                    icon: Icons.confirmation_number_outlined,
                    title: "Linked event data may be lost",
                    subtitle:
                        "Associated presentation details tied to this record will no longer be available.",
                  ),
                  SizedBox(height: 12),
                  _ImpactTile(
                    icon: Icons.undo_rounded,
                    title: "This action cannot be undone",
                    subtitle:
                        "You would need to create the event again if you change your mind later.",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: "Final confirmation",
              icon: Icons.lock_outline_rounded,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Type DELETE below to confirm that you want to permanently remove this event.",
                    style: TextStyle(
                      fontSize: _kDeletePageFontSize,
                      fontFamily: "DMSans",
                      height: 1.5,
                      color: scheme.onSurface.withValues(alpha: 0.68),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _confirmationCtrl,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      fontSize: _kDeletePageFontSize,
                      fontFamily: "DMSans",
                      height: 1.2,
                    ),
                    decoration: InputDecoration(
                      labelText: "Type DELETE",
                      filled: true,
                      fillColor: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.65),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.65),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide(color: scheme.error, width: 1.3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.maybePop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text("Keep event"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canDelete ? _deleteEvent : null,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      backgroundColor: scheme.error,
                      foregroundColor: scheme.onError,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Text("Delete event"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  ThemeData _buildPageTheme(BuildContext context) {
    final base = Theme.of(context);
    final textTheme = base.textTheme;

    TextStyle normalize(
      TextStyle? style, {
      FontWeight? weight,
      double? height,
    }) {
      return (style ?? const TextStyle()).copyWith(
        fontSize: _kDeletePageFontSize,
        fontFamily: "DMSans",
        fontWeight: weight ?? style?.fontWeight,
        height: height ?? style?.height,
      );
    }

    return base.copyWith(
      textTheme: textTheme.copyWith(
        displayLarge: normalize(textTheme.displayLarge),
        displayMedium: normalize(textTheme.displayMedium),
        displaySmall: normalize(textTheme.displaySmall),
        headlineLarge: normalize(textTheme.headlineLarge),
        headlineMedium: normalize(textTheme.headlineMedium),
        headlineSmall: normalize(textTheme.headlineSmall),
        titleLarge: normalize(textTheme.titleLarge, weight: FontWeight.w700),
        titleMedium: normalize(textTheme.titleMedium, weight: FontWeight.w700),
        titleSmall: normalize(textTheme.titleSmall, weight: FontWeight.w700),
        bodyLarge: normalize(textTheme.bodyLarge),
        bodyMedium: normalize(textTheme.bodyMedium),
        bodySmall: normalize(textTheme.bodySmall),
        labelLarge: normalize(textTheme.labelLarge, weight: FontWeight.w700),
        labelMedium: normalize(textTheme.labelMedium, weight: FontWeight.w700),
        labelSmall: normalize(textTheme.labelSmall, weight: FontWeight.w700),
      ),
    );
  }

  Future<void> _deleteEvent() async {
    final eventId = widget.eventId?.trim();
    if (eventId == null || eventId.isEmpty) {
      _showErrorToast("Missing event identifier.");
      return;
    }

    final valid = await AuthSession.instance.ensureValid();
    if (!valid) {
      await _forceSignIn();
      return;
    }

    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) {
      await _forceSignIn();
      return;
    }

    setState(() => _busy = true);

    try {
      final response = await http.delete(
        Api.url(MyEventEndpoints.delete(eventId)),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _forceSignIn();
        return;
      }

      Map<String, dynamic>? body;
      if (response.body.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(response.body);
          body = decoded is Map<String, dynamic> ? decoded : null;
        } catch (_) {}
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = (body?["message"] ?? "").toString().trim();
        throw _ApiException(
          message.isNotEmpty
              ? message
              : "We could not delete this event right now. Please try again.",
        );
      }

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        title: const Text("Event deleted"),
        description: Text("$_eventTitle has been removed successfully."),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );

      Navigator.pop(context, true);
    } on _ApiException catch (error) {
      _showErrorToast(error.message);
    } catch (_) {
      _showErrorToast(
        "We could not delete this event right now. Please try again.",
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _forceSignIn() async {
    await AuthSession.instance.signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    toastification.show(
      context: context,
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      title: const Text("Unable to continue"),
      description: Text(message),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _HeroCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.error.withValues(alpha: 0.12),
            scheme.errorContainer.withValues(alpha: 0.22),
            scheme.surface.withValues(alpha: 0.96),
          ],
        ),
        border: Border.all(color: scheme.error.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: scheme.error.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.delete_forever_outlined,
              color: scheme.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: _kDeletePageFontSize,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: _kDeletePageFontSize,
                    height: 1.45,
                    color: scheme.onSurface.withValues(alpha: 0.70),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: scheme.error.withValues(alpha: 0.10),
                    ),
                    child: Icon(icon, color: scheme.error, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: _kDeletePageFontSize,
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool subtle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.subtle = false,
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
            fontSize: _kDeletePageFontSize,
            fontFamily: "DMSans",
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: _kDeletePageFontSize,
            fontFamily: "DMSans",
            fontWeight: subtle ? FontWeight.w600 : FontWeight.w900,
            color: subtle
                ? scheme.onSurface.withValues(alpha: 0.72)
                : scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ImpactTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ImpactTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.30),
          ),
          child: Icon(icon, size: 18, color: scheme.error),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: _kDeletePageFontSize,
                  fontFamily: "DMSans",
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: _kDeletePageFontSize,
                  fontFamily: "DMSans",
                  height: 1.45,
                  color: scheme.onSurface.withValues(alpha: 0.68),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ApiException implements Exception {
  final String message;

  const _ApiException(this.message);
}
