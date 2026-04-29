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
    final routeLabel = pkg.routeLabel;
    final overview = pkg.displayDescription;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _StatsRow(pkg: pkg, lang: lang, scheme: scheme),
        const SizedBox(height: 16),

        if (overview.isNotEmpty) ...[
          _SectionHeader(
            icon: HugeIcons.strokeRoundedTextAlignLeft01,
            label: t(lang, "listings.overview_title"),
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _ContentCard(
            scheme: scheme,
            child: Text(
              overview,
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

        if (routeLabel.isNotEmpty) ...[
          _SectionHeader(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: "Route",
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
                    routeLabel,
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
          const SizedBox(height: 16),
        ],

        if (pkg.travelerFit.trim().isNotEmpty) ...[
          _SectionHeader(
            icon: HugeIcons.strokeRoundedUserMultiple,
            label: "Best For",
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _ContentCard(
            scheme: scheme,
            child: Text(
              pkg.travelerFit.trim(),
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                fontWeight: FontWeight.w500,
                color: scheme.onSurface.withValues(alpha: 0.82),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        if (pkg.includedItems.trim().isNotEmpty ||
            pkg.excludedItems.trim().isNotEmpty ||
            pkg.whatToBring.trim().isNotEmpty ||
            pkg.importantNotes.trim().isNotEmpty ||
            pkg.pricingNotes.trim().isNotEmpty ||
            pkg.childPricingNote.trim().isNotEmpty ||
            pkg.addOnsSummary.trim().isNotEmpty) ...[
          _SectionHeader(
            icon: HugeIcons.strokeRoundedInformationCircle,
            label: "Planning Notes",
            scheme: scheme,
          ),
          const SizedBox(height: 10),
          _ContentCard(
            scheme: scheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pkg.includedItems.trim().isNotEmpty)
                  _TextBlock(label: "Included", value: pkg.includedItems),
                if (pkg.excludedItems.trim().isNotEmpty)
                  _TextBlock(label: "Excluded", value: pkg.excludedItems),
                if (pkg.whatToBring.trim().isNotEmpty)
                  _TextBlock(label: "What to bring", value: pkg.whatToBring),
                if (pkg.importantNotes.trim().isNotEmpty)
                  _TextBlock(
                    label: "Important notes",
                    value: pkg.importantNotes,
                  ),
                if (pkg.pricingNotes.trim().isNotEmpty)
                  _TextBlock(label: "Pricing notes", value: pkg.pricingNotes),
                if (pkg.childPricingNote.trim().isNotEmpty)
                  _TextBlock(
                    label: "Child pricing",
                    value: pkg.childPricingNote,
                  ),
                if (pkg.addOnsSummary.trim().isNotEmpty)
                  _TextBlock(label: "Add-ons", value: pkg.addOnsSummary),
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
      if (pkg.resolvedDaysCount > 0)
        (
          icon: HugeIcons.strokeRoundedClock01,
          value:
              "${pkg.resolvedDaysCount} ${pkg.resolvedDaysCount == 1 ? t(lang, "trips.day") : t(lang, "trips.days")}",
        ),
      if (pkg.resolvedActivitiesCount > 0)
        (
          icon: HugeIcons.strokeRoundedActivity01,
          value:
              "${pkg.resolvedActivitiesCount} ${t(lang, "trips.activities")}",
        ),
      if (pkg.durationNights != null && pkg.durationNights! > 0)
        (
          icon: HugeIcons.strokeRoundedMoon02,
          value: "${pkg.durationNights} nights",
        ),
      if (pkg.depositAmount != null)
        (
          icon: HugeIcons.strokeRoundedWallet03,
          value:
              "Deposit ${pkg.depositCurrency ?? pkg.priceCurrency ?? "RWF"} ${pkg.depositAmount}",
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

class _TextBlock extends StatelessWidget {
  final String label;
  final String value;

  const _TextBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.trim(),
            style: TextStyle(
              fontSize: 12,
              height: 1.6,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.78),
            ),
          ),
        ],
      ),
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
            border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
          ),
          child: child,
        ),
      ),
    );
  }
}
