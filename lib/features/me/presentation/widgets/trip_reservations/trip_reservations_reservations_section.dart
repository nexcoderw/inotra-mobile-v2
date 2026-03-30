import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/utils/rwf_currency.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "trip_reservations_dialogs.dart";
import "trip_reservations_models.dart";
import "trip_reservations_shared.dart";

class TripReservationsSection extends StatelessWidget {
  const TripReservationsSection({
    super.key,
    required this.reservations,
    required this.billedName,
    required this.billedEmail,
  });

  final List<TripReservationPreview> reservations;
  final String? billedName;
  final String billedEmail;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TripReservationsSectionHeader(
          icon: HugeIcons.strokeRoundedLuggage01,
          iconColor: const Color(0xFF0F8F5F),
          title: t(lang, "trip_reservations.reservations_title"),
          subtitle: t(lang, "trip_reservations.reservations_subtitle"),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < reservations.length; index++) ...[
          _ReservationCard(
            reservation: reservations[index],
            billedName: billedName,
            billedEmail: billedEmail,
          ),
          if (index != reservations.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.billedName,
    required this.billedEmail,
  });

  final TripReservationPreview reservation;
  final String? billedName;
  final String billedEmail;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final statusTone = tripReservationTone(reservation.statusKey, scheme);
    final paymentTone = tripReservationTone(
      reservation.paymentStatusKey,
      scheme,
    );
    final balanceLabel = reservation.balanceRwf == 0
        ? t(lang, "trip_reservations.balance_cleared")
        : t(
            lang,
            "trip_reservations.balance_remaining",
          ).replaceAll("{amount}", RwfCurrency.format(reservation.balanceRwf));

    return TripReservationsSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final stackHeader = constraints.maxWidth < 520;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.packageName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface.withValues(alpha: 0.94),
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reservation.destination,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.56),
                    ),
                  ),
                ],
              );

              if (stackHeader) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    TripReservationStateBadge(
                      label: t(lang, reservation.statusKey),
                      color: statusTone,
                    ),
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 12),
                  TripReservationStateBadge(
                    label: t(lang, reservation.statusKey),
                    color: statusTone,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              TripReservationMetaPill(
                icon: HugeIcons.strokeRoundedCalendar03,
                label: formatTripWindow(
                  context,
                  reservation.startDate,
                  reservation.endDate,
                ),
              ),
              TripReservationMetaPill(
                icon: HugeIcons.strokeRoundedUserGroup,
                label: t(
                  lang,
                  "trip_reservations.travelers_count",
                ).replaceAll("{count}", "${reservation.travelers}"),
              ),
              TripReservationMetaPill(
                icon: HugeIcons.strokeRoundedMoon02,
                label: t(
                  lang,
                  "trip_reservations.nights_count",
                ).replaceAll("{count}", "${reservation.nights}"),
              ),
              TripReservationMetaPill(
                icon: HugeIcons.strokeRoundedShield01,
                label: reservation.confirmationCode,
                color: reservation.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final showInlineStats = constraints.maxWidth >= 580;

              final amountBlock = _InfoBlock(
                label: t(lang, "trip_reservations.amount_paid"),
                value: RwfCurrency.format(reservation.amountPaidRwf),
              );
              final paymentBlock = _InfoBlock(
                label: t(lang, "trip_reservations.payment_status"),
                value: t(lang, reservation.paymentStatusKey),
                tone: paymentTone,
              );
              final documentBlock = _InfoBlock(
                label: t(lang, "trip_reservations.ready_documents"),
                value: t(
                  lang,
                  "trip_reservations.ticket_count",
                ).replaceAll("{count}", "${reservation.tickets.length}"),
              );

              if (showInlineStats) {
                return Row(
                  children: [
                    Expanded(child: amountBlock),
                    const SizedBox(width: 12),
                    Expanded(child: paymentBlock),
                    const SizedBox(width: 12),
                    Expanded(child: documentBlock),
                  ],
                );
              }

              return Column(
                children: [
                  amountBlock,
                  const SizedBox(height: 10),
                  paymentBlock,
                  const SizedBox(height: 10),
                  documentBlock,
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: reservation.paymentProgress,
                    minHeight: 9,
                    backgroundColor: scheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(paymentTone),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "${(reservation.paymentProgress * 100).round()}%",
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: paymentTone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            balanceLabel,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              TripReservationActionButton(
                icon: HugeIcons.strokeRoundedTicket01,
                label: t(lang, "trip_reservations.tickets"),
                color: const Color(0xFF1877B8),
                onTap: () =>
                    showTripTicketsDialog(context, reservation: reservation),
              ),
              TripReservationActionButton(
                icon: HugeIcons.strokeRoundedInvoice03,
                label: t(lang, "trip_reservations.invoice"),
                color: const Color(0xFF0F8F5F),
                isFilled: true,
                onTap: () => showTripInvoiceDialog(
                  context,
                  reservation: reservation,
                  billedName: billedName ?? "",
                  billedEmail: billedEmail,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.label, required this.value, this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tone ?? scheme.onSurface.withValues(alpha: 0.82);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.46),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
