import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../core/utils/rwf_currency.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "my_listing_bookings_models.dart";
import "my_listing_bookings_shared.dart";

class MyListingBookingHeader extends StatelessWidget {
  const MyListingBookingHeader({
    super.key,
    required this.displayName,
    required this.email,
    required this.nextBooking,
    required this.isLoading,
  });

  final String displayName;
  final String email;
  final MyListingBookingPreview? nextBooking;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF142A22), const Color(0xFF08130F)]
              : [const Color(0xFF163629), const Color(0xFF09150F)],
        ),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0C1F16).withValues(alpha: 0.16),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showInlinePanel = constraints.maxWidth >= 860;

          return showInlinePanel
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLead(context)),
                    const SizedBox(width: 18),
                    SizedBox(width: 304, child: _buildNextPanel(context)),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLead(context),
                    const SizedBox(height: 16),
                    _buildNextPanel(context),
                  ],
                );
        },
      ),
    );
  }

  Widget _buildLead(BuildContext context) {
    final lang = currentLangSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t(lang, "my_listings.bookings.header_eyebrow"),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: Colors.white.withValues(alpha: 0.56),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t(lang, "nav.listing_booking"),
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.9,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t(
            lang,
            "my_listings.bookings.header_subtitle",
          ).replaceAll("{name}", displayName),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.45,
            color: Colors.white.withValues(alpha: 0.70),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.56),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNextPanel(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    if (nextBooking == null) {
      final titleKey = isLoading
          ? "my_listings.bookings.loading_panel_title"
          : "my_listings.bookings.empty_panel_title";
      final subtitleKey = isLoading
          ? "my_listings.bookings.loading_panel_subtitle"
          : "my_listings.bookings.empty_panel_subtitle";

      return MyListingBookingSurfaceCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedHome05,
                  color: scheme.primary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t(lang, titleKey),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              t(lang, subtitleKey),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: scheme.onSurface.withValues(alpha: 0.58),
              ),
            ),
          ],
        ),
      );
    }

    final tone = myListingBookingTone(nextBooking!.statusKey, scheme);

    return MyListingBookingSurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "my_listings.bookings.next_stay"),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: tone,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            nextBooking!.listingName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            formatListingStayWindow(
              context,
              nextBooking!.checkIn,
              nextBooking!.checkOut,
            ),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              MyListingBookingStateBadge(
                label: t(lang, nextBooking!.statusKey),
                color: tone,
              ),
              MyListingBookingMetaPill(
                icon: HugeIcons.strokeRoundedLocation01,
                label: nextBooking!.locationLabel.isEmpty
                    ? t(lang, "my_listings.bookings.location_fallback")
                    : nextBooking!.locationLabel,
                color: scheme.onSurface.withValues(alpha: 0.56),
              ),
              MyListingBookingMetaPill(
                icon: HugeIcons.strokeRoundedWallet02,
                label: RwfCurrency.compact(nextBooking!.totalPaidRwf),
                color: tone,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
