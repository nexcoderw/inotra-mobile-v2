import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "package_models.dart";

class PackageOverviewTab extends StatelessWidget {
  final PackageDetailData pkg;

  const PackageOverviewTab({super.key, required this.pkg});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _StatsRow(pkg: pkg, lang: lang, scheme: scheme),
        const SizedBox(height: 16),

        if (pkg.description.isNotEmpty) ...[
          _SectionHeader(
            icon: HugeIcons.strokeRoundedTextAlignLeft01,
            label: t(lang, "listings.overview_title"),
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _ContentCard(
            scheme: scheme,
            child: Text(
              pkg.description,
              style: TextStyle(
                fontSize: 12,
                height: 1.65,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (pkg.location.isNotEmpty) ...[
          _SectionHeader(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: t(lang, "listings.address"),
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _ContentCard(
            scheme: scheme,
            child: Row(
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedMapsLocation02,
                  size: 16,
                  color: scheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pkg.location,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.86),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final PackageDetailData pkg;
  final String lang;
  final ColorScheme scheme;

  const _StatsRow({
    required this.pkg,
    required this.lang,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <({dynamic icon, String value})>[
      if (pkg.durationDays != null)
        (
          icon: HugeIcons.strokeRoundedClock01,
          value:
              "${pkg.durationDays} ${pkg.durationDays == 1 ? t(lang, "trips.day") : t(lang, "trips.days")}",
        ),
      if (pkg.activities.isNotEmpty)
        (
          icon: HugeIcons.strokeRoundedActivity01,
          value: "${pkg.activities.length} ${t(lang, "trips.activities")}",
        ),
    ];

    if (chips.isEmpty) return const SizedBox.shrink();

    return Row(
      children: [
        for (final chip in chips) ...[
          Expanded(
            child: _StatChip(
              icon: chip.icon,
              value: chip.value,
              scheme: scheme,
            ),
          ),
          if (chip != chips.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final dynamic icon;
  final String value;
  final ColorScheme scheme;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.primary.withValues(alpha: 0.08),
            border: Border.all(color: scheme.primary.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, size: 15, color: scheme.primary),
              const SizedBox(width: 7),
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
        HugeIcon(
          icon: icon,
          size: 15,
          color: scheme.onSurface.withValues(alpha: 0.65),
        ),
        const SizedBox(width: 7),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withValues(alpha: 0.85),
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _ContentCard extends StatelessWidget {
  final Widget child;
  final ColorScheme scheme;

  const _ContentCard({required this.child, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.18),
            border: Border.all(
              color: scheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
