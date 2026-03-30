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
    final localizations = MaterialLocalizations.of(context);
    final statusTone = tripReservationTone(reservation.statusKey, scheme);
    final paymentTone = tripReservationTone(
      reservation.paymentStatusKey,
      scheme,
    );
    final travelWindow = formatTripWindow(
      context,
      reservation.startDate,
      reservation.endDate,
    );
    final paymentStatusLabel = t(lang, reservation.paymentStatusKey);
    final amountPaidLabel = RwfCurrency.format(reservation.amountPaidRwf);
    final ticketCountLabel = t(
      lang,
      "trip_reservations.ticket_count",
    ).replaceAll("{count}", "${reservation.tickets.length}");
    final progressLabel = "${(reservation.paymentProgress * 100).round()}%";
    final balanceLabel = reservation.balanceRwf == 0
        ? t(lang, "trip_reservations.balance_cleared")
        : t(
            lang,
            "trip_reservations.balance_remaining",
          ).replaceAll("{amount}", RwfCurrency.format(reservation.balanceRwf));

    return TripReservationsSurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              reservation.accent.withValues(alpha: 0.10),
              scheme.surfaceContainerLowest.withValues(alpha: 0.98),
              scheme.surfaceContainerLowest.withValues(alpha: 0.94),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: reservation.accent.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 760;
                  final isMedium = constraints.maxWidth >= 540;

                  final headerContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          TripReservationStateBadge(
                            label: t(lang, reservation.statusKey),
                            color: statusTone,
                          ),
                          TripReservationMetaPill(
                            icon: HugeIcons.strokeRoundedWallet02,
                            label: paymentStatusLabel,
                            color: paymentTone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Text(
                        reservation.packageName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface.withValues(alpha: 0.95),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        reservation.destination,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.56),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            color: reservation.accent,
                            size: 15,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              travelWindow,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: scheme.onSurface.withValues(alpha: 0.72),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );

                  final routePanel = SizedBox(
                    width: isWide ? 148 : 132,
                    child: _RouteWindowPanel(
                      accent: reservation.accent,
                      startLabel: localizations.formatShortMonthDay(
                        reservation.startDate,
                      ),
                      endLabel: localizations.formatShortMonthDay(
                        reservation.endDate,
                      ),
                      durationLabel: t(
                        lang,
                        "trip_reservations.nights_count",
                      ).replaceAll("{count}", "${reservation.nights}"),
                    ),
                  );

                  final amountPanel = _AmountSpotlight(
                    accent: reservation.accent,
                    label: t(lang, "trip_reservations.amount_paid"),
                    value: amountPaidLabel,
                    caption: balanceLabel,
                  );

                  if (isWide) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        routePanel,
                        const SizedBox(width: 16),
                        Expanded(child: headerContent),
                        const SizedBox(width: 16),
                        SizedBox(width: 190, child: amountPanel),
                      ],
                    );
                  }

                  if (isMedium) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        routePanel,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              headerContent,
                              const SizedBox(height: 14),
                              amountPanel,
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      routePanel,
                      const SizedBox(height: 14),
                      headerContent,
                      const SizedBox(height: 14),
                      amountPanel,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.68),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: scheme.outline.withValues(alpha: 0.08),
                  ),
                ),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    TripReservationMetaPill(
                      icon: HugeIcons.strokeRoundedUserGroup,
                      label: t(
                        lang,
                        "trip_reservations.travelers_count",
                      ).replaceAll("{count}", "${reservation.travelers}"),
                    ),
                    TripReservationMetaPill(
                      icon: HugeIcons.strokeRoundedTicket01,
                      label: ticketCountLabel,
                      color: const Color(0xFF1877B8),
                    ),
                    TripReservationMetaPill(
                      icon: HugeIcons.strokeRoundedShield01,
                      label: reservation.confirmationCode,
                      color: reservation.accent,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PaymentStrip(
                tone: paymentTone,
                statusLabel: paymentStatusLabel,
                amountLabel: amountPaidLabel,
                progressLabel: progressLabel,
                balanceLabel: balanceLabel,
                progress: reservation.paymentProgress,
              ),
              const SizedBox(height: 14),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compactFooter = constraints.maxWidth < 640;
                  final documentsNote = _DocumentsNote(
                    accent: reservation.accent,
                    label:
                        "$ticketCountLabel • ${reservation.invoice.invoiceNumber}",
                  );

                  final ticketsButton = TripReservationActionButton(
                    icon: HugeIcons.strokeRoundedTicket01,
                    label: t(lang, "trip_reservations.tickets"),
                    color: const Color(0xFF1877B8),
                    onTap: () => showTripTicketsDialog(
                      context,
                      reservation: reservation,
                    ),
                  );
                  final invoiceButton = TripReservationActionButton(
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
                  );

                  if (compactFooter) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        documentsNote,
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: ticketsButton),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: invoiceButton),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: documentsNote),
                      const SizedBox(width: 12),
                      Expanded(child: ticketsButton),
                      const SizedBox(width: 10),
                      Expanded(child: invoiceButton),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteWindowPanel extends StatelessWidget {
  const _RouteWindowPanel({
    required this.accent,
    required this.startLabel,
    required this.endLabel,
    required this.durationLabel,
  });

  final Color accent;
  final String startLabel;
  final String endLabel;
  final String durationLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RouteStop(label: startLabel, accent: accent, emphasize: true),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Container(
              width: 1.5,
              height: 20,
              color: accent.withValues(alpha: 0.26),
            ),
          ),
          _RouteStop(label: endLabel, accent: accent),
          const SizedBox(height: 12),
          Text(
            durationLabel,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.64),
            ),
          ),
        ],
      ),
    );
  }
}

class _RouteStop extends StatelessWidget {
  const _RouteStop({
    required this.label,
    required this.accent,
    this.emphasize = false,
  });

  final String label;
  final Color accent;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: emphasize ? accent : accent.withValues(alpha: 0.16),
            shape: BoxShape.circle,
            border: Border.all(color: accent.withValues(alpha: 0.30)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(
                alpha: emphasize ? 0.90 : 0.62,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AmountSpotlight extends StatelessWidget {
  const _AmountSpotlight({
    required this.accent,
    required this.label,
    required this.value,
    required this.caption,
  });

  final Color accent;
  final String label;
  final String value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.92),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            caption,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: scheme.onSurface.withValues(alpha: 0.56),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStrip extends StatelessWidget {
  const _PaymentStrip({
    required this.tone,
    required this.statusLabel,
    required this.amountLabel,
    required this.progressLabel,
    required this.balanceLabel,
    required this.progress,
  });

  final Color tone;
  final String statusLabel;
  final String amountLabel;
  final String progressLabel;
  final String balanceLabel;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.74),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t(lang, "trip_reservations.payment_status"),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface.withValues(alpha: 0.46),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: tone,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    t(lang, "trip_reservations.amount_paid"),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurface.withValues(alpha: 0.46),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    amountLabel,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface.withValues(alpha: 0.92),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(tone),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  balanceLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.54),
                  ),
                ),
              ),
              Text(
                progressLabel,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: tone,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentsNote extends StatelessWidget {
  const _DocumentsNote({required this.accent, required this.label});

  final Color accent;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedFile01,
              color: accent,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.58),
            ),
          ),
        ),
      ],
    );
  }
}
