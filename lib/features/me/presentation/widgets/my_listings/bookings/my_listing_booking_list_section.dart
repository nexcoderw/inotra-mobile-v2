import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../core/utils/rwf_currency.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "my_listing_booking_dialogs.dart";
import "my_listing_bookings_models.dart";
import "my_listing_bookings_shared.dart";

class MyListingBookingListSection extends StatelessWidget {
  const MyListingBookingListSection({
    super.key,
    required this.bookings,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  final List<MyListingBookingPreview> bookings;
  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MyListingBookingSectionHeader(
          icon: HugeIcons.strokeRoundedCalendarCheckIn01,
          iconColor: const Color(0xFF1877B8),
          title: t(lang, "my_listings.bookings.list_title"),
          subtitle: t(lang, "my_listings.bookings.list_subtitle"),
        ),
        const SizedBox(height: 14),
        if (isLoading && bookings.isEmpty)
          _LoadingState()
        else if (errorMessage != null && bookings.isEmpty)
          _ErrorState(message: errorMessage!, onRetry: onRetry)
        else if (bookings.isEmpty)
          const _EmptyState()
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final showTwoColumns = constraints.maxWidth >= 1120;
              final cardWidth = showTwoColumns
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;

              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final booking in bookings)
                    SizedBox(
                      width: cardWidth,
                      child: _ListingBookingCard(booking: booking),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _ListingBookingCard extends StatelessWidget {
  const _ListingBookingCard({required this.booking});

  final MyListingBookingPreview booking;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MyListingBookingSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: booking.accent.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        booking.listingName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                          color: scheme.onSurface.withValues(alpha: 0.95),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: scheme.primary.withValues(alpha: 0.14),
                        ),
                      ),
                      child: Text(
                        booking.stayLabel.isEmpty
                            ? t(lang, "my_listings.bookings.stay_fallback")
                            : booking.stayLabel,
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _HeaderMeta(
                      icon: HugeIcons.strokeRoundedLocation01,
                      label: booking.locationLabel.isEmpty
                          ? t(lang, "my_listings.bookings.location_fallback")
                          : booking.locationLabel,
                    ),
                    _HeaderMeta(
                      icon: HugeIcons.strokeRoundedCalendar03,
                      label: formatListingStayWindow(
                        context,
                        booking.checkIn,
                        booking.checkOut,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _TicketDividerBand(accent: booking.accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: booking.accent.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: booking.accent.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t(lang, "my_listings.bookings.total_paid"),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: booking.accent,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        RwfCurrency.format(booking.totalPaidRwf),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: scheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t(lang, "my_listings.bookings.nightly_rate"),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface.withValues(alpha: 0.50),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            RwfCurrency.format(booking.nightlyRateRwf),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 126,
                      child: MyListingBookingActionButton(
                        icon: HugeIcons.strokeRoundedView,
                        label: t(lang, "my_listings.bookings.details"),
                        onTap: () =>
                            showMyListingBookingDetailsDialog(context, booking),
                        color: scheme.primary,
                        isFilled: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({required this.icon, required this.label});

  final dynamic icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          size: 14,
          color: scheme.onSurface.withValues(alpha: 0.48),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index == 2 ? 0 : 16),
          child: MyListingBookingSurfaceCard(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 180,
                  height: 14,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  height: 12,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 78,
                  decoration: BoxDecoration(
                    color: scheme.onSurface.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(22),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 18,
                        decoration: BoxDecoration(
                          color: scheme.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 126,
                      height: 48,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MyListingBookingSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCalendarRemove02,
                color: scheme.primary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t(lang, "my_listings.bookings.empty_title"),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(lang, "my_listings.bookings.empty_subtitle"),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MyListingBookingSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD64545).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedAlert02,
                color: Color(0xFFD64545),
                size: 18,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t(lang, "my_listings.bookings.error_title"),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: scheme.onSurface.withValues(alpha: 0.60),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () {
              onRetry();
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(t(lang, "common.try_again")),
          ),
        ],
      ),
    );
  }
}

class _TicketDividerBand extends StatelessWidget {
  const _TicketDividerBand({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cutoutColor = Theme.of(context).scaffoldBackgroundColor;

    return SizedBox(
      height: 26,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final dashCount = (constraints.maxWidth / 14).floor().clamp(
                8,
                40,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    dashCount,
                    (index) => Container(
                      width: 7,
                      height: 1.5,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.24),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: -11,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: cutoutColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
          Positioned(
            right: -11,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: cutoutColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: scheme.outline.withValues(alpha: 0.08),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
