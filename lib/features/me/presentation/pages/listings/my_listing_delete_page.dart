import "dart:ui";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "package:toastification/toastification.dart";

import "../../../../../core/config/api.dart";
import "../../../../../core/config/app_routes.dart";
import "../../../../../core/constants/api/my_listing_endpoints.dart";
import "../../../../../core/services/auth_session.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../../../main/presentation/widgets/page_header.dart";

const double _kDeletePageFontSize = 12;

class MyListingDeletePage extends StatefulWidget {
  final String? listingId;
  final String? title;

  const MyListingDeletePage({super.key, this.listingId, this.title});

  @override
  State<MyListingDeletePage> createState() => _MyListingDeletePageState();
}

class _MyListingDeletePageState extends State<MyListingDeletePage> {
  final TextEditingController _confirmationCtrl = TextEditingController();
  bool _busy = false;

  String get _lang => currentLangSync();

  String get _listingTitle {
    final raw = widget.title?.trim();
    if (raw != null && raw.isNotEmpty) return raw;
    return t(_lang, "my_listings.fallback_title");
  }

  bool get _canDelete =>
      !_busy &&
      (widget.listingId?.trim().isNotEmpty ?? false) &&
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
              title: t(_lang, "my_listings.delete_listing"),
              titleStyle: const TextStyle(
                fontSize: _kDeletePageFontSize,
                fontWeight: FontWeight.w700,
                fontFamily: "DMSans",
              ),
            ),
            const SizedBox(height: 10),
            _HeroCard(
              title: "Delete this listing permanently",
              subtitle:
                  "This action removes the listing from your portfolio and cannot be undone. Review the details carefully before you continue.",
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: "Listing summary",
              icon: Icons.storefront_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: "Listing", value: _listingTitle),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: "Listing ID",
                    value: widget.listingId?.trim().isNotEmpty == true
                        ? widget.listingId!.trim()
                        : "Unavailable",
                    subtle: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: "What will happen",
              icon: Icons.warning_amber_rounded,
              child: const Column(
                children: [
                  _ImpactTile(
                    icon: Icons.delete_sweep_outlined,
                    title: "The listing will be removed",
                    subtitle:
                        "Customers will no longer be able to discover or open it.",
                  ),
                  SizedBox(height: 12),
                  _ImpactTile(
                    icon: Icons.image_not_supported_outlined,
                    title: "Related listing media will be deleted",
                    subtitle:
                        "Uploaded listing images associated with this record will be removed.",
                  ),
                  SizedBox(height: 12),
                  _ImpactTile(
                    icon: Icons.undo_rounded,
                    title: "This action cannot be undone",
                    subtitle:
                        "You would need to create a new listing again if you change your mind.",
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
                    "Type DELETE below to confirm that you want to permanently remove this listing.",
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
                    child: const Text("Keep listing"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _canDelete ? _deleteListing : null,
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
                        : const Text("Delete listing"),
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

  Future<void> _deleteListing() async {
    final listingId = widget.listingId?.trim();
    if (listingId == null || listingId.isEmpty) {
      _showErrorToast("Missing listing identifier.");
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
        Api.url(MyListingEndpoints.delete(listingId)),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _forceSignIn();
        return;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw _ApiException(
          "We could not delete this listing right now. Please try again.",
        );
      }

      if (!mounted) return;
      toastification.show(
        context: context,
        type: ToastificationType.success,
        style: ToastificationStyle.fillColored,
        title: const Text("Listing deleted"),
        description: Text("$_listingTitle has been removed successfully."),
        alignment: Alignment.topCenter,
        autoCloseDuration: const Duration(seconds: 3),
      );

      Navigator.pop(context, true);
    } on _ApiException catch (error) {
      _showErrorToast(error.message);
    } catch (_) {
      _showErrorToast(
        "We could not delete this listing right now. Please try again.",
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
