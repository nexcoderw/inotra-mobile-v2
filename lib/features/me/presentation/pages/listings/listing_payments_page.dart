import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../main/presentation/widgets/page_header.dart";
import "../../../../../core/constants/app_colors.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";

class ListingPaymentsPage extends StatelessWidget {
  const ListingPaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
        children: [
          PageHeader(title: t(lang, "nav.listing_payments")),
          const SizedBox(height: 8),
          _PaymentInfoCard(scheme: scheme, isDark: isDark, lang: lang),
          const SizedBox(height: 16),
          _FeaturePreviewList(scheme: scheme, lang: lang),
        ],
      ),
    );
  }
}

class _PaymentInfoCard extends StatelessWidget {
  final ColorScheme scheme;
  final bool isDark;
  final String lang;

  const _PaymentInfoCard({
    required this.scheme,
    required this.isDark,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1A2F20), const Color(0xFF0F1E14)]
              : [AppColors.primary, const Color(0xFF0D5231)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedWallet02,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(lang, "nav.listing_payments"),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        t(lang, "payments.integration_badge"),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            t(lang, "payments.listing_description"),
            style: TextStyle(
              fontSize: 13.5,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePreviewList extends StatelessWidget {
  final ColorScheme scheme;
  final String lang;

  const _FeaturePreviewList({required this.scheme, required this.lang});

  @override
  Widget build(BuildContext context) {
    final features = [
      (HugeIcons.strokeRoundedChartLineData01, t(lang, "payments.feature_revenue")),
      (HugeIcons.strokeRoundedInvoice03, t(lang, "payments.feature_invoices")),
      (HugeIcons.strokeRoundedSmartPhone01, t(lang, "payments.feature_mobile_money")),
      (HugeIcons.strokeRoundedBank, t(lang, "payments.feature_payout")),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "payments.whats_included"),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          for (final (icon, label) in features) ...[
            Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.80),
                    ),
                  ),
                ),
              ],
            ),
            if (features.last.$2 != label) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
