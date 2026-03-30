import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../core/utils/rwf_currency.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "my_listing_bookings_models.dart";
import "my_listing_bookings_shared.dart";

Future<void> showMyListingBookingDetailsDialog(
  BuildContext context,
  MyListingBookingPreview booking,
) {
  final lang = currentLangSync();
  final accent = myListingBookingTone(
    booking.statusKey,
    Theme.of(context).colorScheme,
  );

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;

      return _MyListingBookingDialogShell(
        title: t(lang, "my_listings.bookings.details_dialog_title"),
        subtitle: booking.listingName,
        accent: accent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: accent.withValues(alpha: 0.18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
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
                      const Spacer(),
                      MyListingBookingStateBadge(
                        label: t(lang, booking.statusKey),
                        color: accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    booking.listingName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    booking.locationLabel.isEmpty
                        ? t(lang, "my_listings.bookings.location_fallback")
                        : booking.locationLabel,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatListingStayWindow(
                      dialogContext,
                      booking.checkIn,
                      booking.checkOut,
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(lang, "my_listings.bookings.booking_code"),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: scheme.onSurface.withValues(alpha: 0.48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          booking.bookingCode,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _DialogFact(
                  label: t(lang, "my_listings.bookings.guests"),
                  value: t(
                    lang,
                    "my_listings.bookings.guests_count",
                  ).replaceAll("{count}", "${booking.guestCount}"),
                ),
                _DialogFact(
                  label: t(lang, "my_listings.bookings.nights"),
                  value: t(
                    lang,
                    "my_listings.bookings.nights_count",
                  ).replaceAll("{count}", "${booking.nights}"),
                ),
                _DialogFact(
                  label: t(lang, "my_listings.bookings.booked_on"),
                  value: formatListingDate(dialogContext, booking.bookedOn),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DialogRow(
              label: t(lang, "my_listings.bookings.payment_method"),
              value: t(lang, booking.paymentMethodKey),
            ),
            _DialogRow(
              label: t(lang, "my_listings.bookings.payment_reference"),
              value: booking.paymentReference,
            ),
            _DialogRow(
              label: t(lang, "my_listings.bookings.check_in"),
              value: formatListingDate(dialogContext, booking.checkIn),
            ),
            _DialogRow(
              label: t(lang, "my_listings.bookings.check_out"),
              value: formatListingDate(dialogContext, booking.checkOut),
            ),
            _DialogRow(
              label: t(lang, "my_listings.bookings.nightly_rate"),
              value: RwfCurrency.format(booking.nightlyRateRwf),
            ),
            _DialogRow(
              label: t(lang, "my_listings.bookings.total_paid"),
              value: RwfCurrency.format(booking.totalPaidRwf),
              isLast: true,
            ),
          ],
        ),
      );
    },
  );
}

class _MyListingBookingDialogShell extends StatelessWidget {
  const _MyListingBookingDialogShell({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: MyListingBookingSurfaceCard(
          padding: const EdgeInsets.all(20),
          borderColor: accent.withValues(alpha: 0.22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedHome05,
                        color: accent,
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
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface.withValues(alpha: 0.56),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      size: 18,
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
                    tooltip: t(lang, "common.cancel"),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.68,
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: child,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.56),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogFact extends StatelessWidget {
  const _DialogFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.52),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
