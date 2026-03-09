import "dart:ui";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hugeicons/hugeicons.dart";

import "listing_details_shared.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ListingTransportTab extends StatelessWidget {
  final PlaceDetails place;
  const ListingTransportTab({super.key, required this.place});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final noData = t(lang, "listings.no_data");

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GlassSection(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  icon: HugeIcons.strokeRoundedSmartPhone01,
                  label: t(lang, "listings.transport_title"),
                  scheme: scheme,
                ),
                const SizedBox(height: 12),
                _ContactRow(
                  icon: HugeIcons.strokeRoundedCall,
                  label: place.phone.isNotEmpty ? place.phone : noData,
                  hasValue: place.phone.isNotEmpty,
                  scheme: scheme,
                  context: context,
                ),
                const SizedBox(height: 8),
                _ContactRow(
                  icon: HugeIcons.strokeRoundedMessage02,
                  label: place.whatsapp.isNotEmpty ? place.whatsapp : noData,
                  hasValue: place.whatsapp.isNotEmpty,
                  scheme: scheme,
                  context: context,
                ),
                const SizedBox(height: 8),
                _ContactRow(
                  icon: HugeIcons.strokeRoundedMail02,
                  label: place.email.isNotEmpty ? place.email : noData,
                  hasValue: place.email.isNotEmpty,
                  scheme: scheme,
                  context: context,
                ),
                const SizedBox(height: 8),
                _ContactRow(
                  icon: HugeIcons.strokeRoundedGlobe02,
                  label: place.website.isNotEmpty ? place.website : noData,
                  hasValue: place.website.isNotEmpty,
                  scheme: scheme,
                  context: context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- Glass section ----------------------------- */

class _GlassSection extends StatelessWidget {
  final Widget child;
  const _GlassSection({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.surface.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 8),
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/* ----------------------------- Section header ----------------------------- */

class _SectionHeader extends StatelessWidget {
  final dynamic icon;
  final String label;
  final ColorScheme scheme;
  const _SectionHeader({
    required this.icon,
    required this.label,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: HugeIcon(icon: icon, size: 14, color: scheme.primary),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withValues(alpha: 0.92),
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }
}

/* ----------------------------- Contact row ----------------------------- */

class _ContactRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  final bool hasValue;
  final ColorScheme scheme;
  final BuildContext context;

  const _ContactRow({
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.scheme,
    required this.context,
  });

  void _copy() {
    if (!hasValue) return;
    Clipboard.setData(ClipboardData(text: label));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Copied to clipboard"),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext _) {
    return GestureDetector(
      onLongPress: hasValue ? _copy : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: hasValue
              ? scheme.primary.withValues(alpha: 0.06)
              : scheme.surfaceContainerHighest.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasValue
                ? scheme.primary.withValues(alpha: 0.14)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: hasValue
                    ? scheme.primary.withValues(alpha: 0.12)
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(9),
              ),
              child: HugeIcon(
                icon: icon,
                size: 15,
                color: hasValue
                    ? scheme.primary
                    : scheme.onSurface.withValues(alpha: 0.35),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                  color: hasValue
                      ? scheme.onSurface.withValues(alpha: 0.88)
                      : scheme.onSurface.withValues(alpha: 0.38),
                ),
              ),
            ),
            if (hasValue) ...[
              const SizedBox(width: 8),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 14,
                color: scheme.onSurface.withValues(alpha: 0.30),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
