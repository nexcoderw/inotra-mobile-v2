import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/utils/rwf_currency.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "trip_reservations_models.dart";
import "trip_reservations_shared.dart";

Future<void> showTripInvoiceDialog(
  BuildContext context, {
  required TripReservationPreview reservation,
  required String billedName,
  required String billedEmail,
}) {
  final scheme = Theme.of(context).colorScheme;
  final lang = currentLangSync();
  final tone = tripReservationTone(reservation.invoice.statusKey, scheme);
  final displayName = billedName.trim().isEmpty
      ? t(lang, "trip_reservations.guest_fallback")
      : billedName.trim();

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final width = MediaQuery.sizeOf(dialogContext).width;

      return Dialog(
        insetPadding: EdgeInsets.symmetric(
          horizontal: width >= 720 ? 32 : 18,
          vertical: 24,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 720,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.84,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DialogTag(
                              icon: HugeIcons.strokeRoundedInvoice03,
                              label: t(lang, "trip_reservations.invoice"),
                              accent: tone,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              reservation.invoice.invoiceNumber,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface.withValues(alpha: 0.94),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              reservation.packageName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface.withValues(alpha: 0.64),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            TripReservationMetaPill(
                              icon: HugeIcons.strokeRoundedTick02,
                              label: t(lang, reservation.invoice.statusKey),
                              color: tone,
                            ),
                            TripReservationMetaPill(
                              icon: HugeIcons.strokeRoundedCalendar03,
                              label: formatFullDate(
                                context,
                                reservation.invoice.issuedOn,
                              ),
                            ),
                            TripReservationMetaPill(
                              icon: HugeIcons.strokeRoundedWallet02,
                              label: t(
                                lang,
                                reservation.invoice.paymentMethodKey,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _InvoiceInfoGrid(
                          children: [
                            _InfoTile(
                              label: t(lang, "trip_reservations.billed_to"),
                              value: displayName,
                            ),
                            _InfoTile(
                              label: t(lang, "auth.email"),
                              value: billedEmail,
                            ),
                            _InfoTile(
                              label: t(lang, "trip_reservations.travel_window"),
                              value: formatTripWindow(
                                context,
                                reservation.startDate,
                                reservation.endDate,
                              ),
                            ),
                            _InfoTile(
                              label: t(lang, "trip_reservations.reference"),
                              value: reservation.invoice.paymentReference,
                            ),
                            _InfoTile(
                              label: t(
                                lang,
                                "trip_reservations.confirmation_code",
                              ),
                              value: reservation.confirmationCode,
                            ),
                            _InfoTile(
                              label: t(
                                lang,
                                "trip_reservations.payment_recorded",
                              ),
                              value: formatFullDate(
                                context,
                                reservation.invoice.paidOn,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text(
                          t(lang, "trip_reservations.charges"),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface.withValues(alpha: 0.92),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _InvoiceLineTile(
                          title: reservation.packageName,
                          subtitle:
                              t(lang, "trip_reservations.package_line_subtitle")
                                  .replaceAll(
                                    "{count}",
                                    "${reservation.travelers}",
                                  )
                                  .replaceAll(
                                    "{nights}",
                                    "${reservation.nights}",
                                  ),
                          amount: RwfCurrency.format(
                            reservation.basePackageAmountRwf,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...reservation.invoice.lineItems.map(
                          (line) => Padding(
                            padding: EdgeInsets.only(
                              bottom: line == reservation.invoice.lineItems.last
                                  ? 0
                                  : 10,
                            ),
                            child: _InvoiceLineTile(
                              title: t(lang, line.titleKey),
                              subtitle: t(lang, line.subtitleKey),
                              amount: RwfCurrency.format(line.amountRwf),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest.withValues(
                              alpha: 0.86,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Column(
                            children: [
                              _AmountRow(
                                label: t(lang, "trip_reservations.subtotal"),
                                value: RwfCurrency.format(
                                  reservation.totalAmountRwf -
                                      reservation.invoice.serviceFeeRwf,
                                ),
                              ),
                              const SizedBox(height: 10),
                              _AmountRow(
                                label: t(lang, "trip_reservations.service_fee"),
                                value: RwfCurrency.format(
                                  reservation.invoice.serviceFeeRwf,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1),
                              ),
                              _AmountRow(
                                label: t(lang, "trip_reservations.total"),
                                value: RwfCurrency.format(
                                  reservation.totalAmountRwf,
                                ),
                                emphasize: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> showTripTicketsDialog(
  BuildContext context, {
  required TripReservationPreview reservation,
}) {
  final scheme = Theme.of(context).colorScheme;
  final lang = currentLangSync();
  final tone = tripReservationTone(reservation.statusKey, scheme);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.80,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _DialogTag(
                              icon: HugeIcons.strokeRoundedTicket01,
                              label: t(lang, "trip_reservations.tickets"),
                              accent: tone,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              reservation.packageName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: scheme.onSurface.withValues(alpha: 0.94),
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatTripWindow(
                                context,
                                reservation.startDate,
                                reservation.endDate,
                              ),
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface.withValues(alpha: 0.56),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    itemCount: reservation.tickets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ticket = reservation.tickets[index];
                      final ticketTone = tripReservationTone(
                        ticket.stateKey,
                        scheme,
                      );

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLowest.withValues(
                            alpha: 0.82,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: scheme.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    t(lang, ticket.labelKey),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.92,
                                      ),
                                    ),
                                  ),
                                ),
                                TripReservationStateBadge(
                                  label: t(lang, ticket.stateKey),
                                  color: ticketTone,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                TripReservationMetaPill(
                                  icon: HugeIcons.strokeRoundedUser,
                                  label: ticket.holder,
                                ),
                                TripReservationMetaPill(
                                  icon: HugeIcons.strokeRoundedQrCode,
                                  label: ticket.code,
                                  color: tone,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _DialogTag extends StatelessWidget {
  const _DialogTag({
    required this.icon,
    required this.label,
    required this.accent,
  });

  final dynamic icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: accent, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceInfoGrid extends StatelessWidget {
  const _InvoiceInfoGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showTwoColumns = constraints.maxWidth >= 520;
        final itemWidth = showTwoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.48),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.90),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLineTile extends StatelessWidget {
  const _InvoiceLineTile({
    required this.title,
    required this.subtitle,
    required this.amount,
  });

  final String title;
  final String subtitle;
  final String amount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.92),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.52),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amount,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.90),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 13 : 12,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: scheme.onSurface.withValues(
                alpha: emphasize ? 0.88 : 0.62,
              ),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 14 : 12.5,
            fontWeight: emphasize ? FontWeight.w900 : FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}
