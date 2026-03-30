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
    final travelersLabel = t(
      lang,
      "trip_reservations.travelers_count",
    ).replaceAll("{count}", "${reservation.travelers}");
    final nightsLabel = t(
      lang,
      "trip_reservations.nights_count",
    ).replaceAll("{count}", "${reservation.nights}");

    return TripReservationsSurfaceCard(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              reservation.accent.withValues(alpha: 0.08),
              scheme.surfaceContainerLowest.withValues(alpha: 0.98),
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: reservation.accent.withValues(alpha: 0.10)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final stackCard = constraints.maxWidth < 560;

                  final travelDock = _TravelDock(
                    accent: reservation.accent,
                    startLabel: localizations.formatShortMonthDay(
                      reservation.startDate,
                    ),
                    endLabel: localizations.formatShortMonthDay(
                      reservation.endDate,
                    ),
                    durationLabel: nightsLabel,
                  );

                  final details = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LayoutBuilder(
                        builder: (context, headerConstraints) {
                          final stackHeader = headerConstraints.maxWidth < 320;

                          final titleBlock = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                reservation.packageName,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.95,
                                  ),
                                  letterSpacing: -0.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                reservation.destination,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.58,
                                  ),
                                ),
                              ),
                            ],
                          );

                          if (stackHeader) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                titleBlock,
                                const SizedBox(height: 10),
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
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _CompactFact(
                            icon: HugeIcons.strokeRoundedUserGroup,
                            label: travelersLabel,
                          ),
                          _CompactFact(
                            icon: HugeIcons.strokeRoundedShield01,
                            label: reservation.confirmationCode,
                            color: reservation.accent,
                          ),
                          _CompactFact(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            label: travelWindow,
                          ),
                        ],
                      ),
                    ],
                  );

                  final paymentCard = _PaymentSummaryCard(
                    tone: paymentTone,
                    statusLabel: paymentStatusLabel,
                    amountLabel: amountPaidLabel,
                    progressLabel: progressLabel,
                    balanceLabel: balanceLabel,
                    progress: reservation.paymentProgress,
                  );

                  if (stackCard) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        travelDock,
                        const SizedBox(height: 12),
                        details,
                        const SizedBox(height: 12),
                        paymentCard,
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 104, child: travelDock),
                      const SizedBox(width: 12),
                      Expanded(child: details),
                      const SizedBox(width: 12),
                      SizedBox(width: 188, child: paymentCard),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Divider(height: 1, color: scheme.outline.withValues(alpha: 0.10)),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compactFooter = constraints.maxWidth < 560;
                  final documentsCard = _DocumentsCard(
                    accent: reservation.accent,
                    invoiceNumber: reservation.invoice.invoiceNumber,
                    ticketCountLabel: ticketCountLabel,
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
                        documentsCard,
                        const SizedBox(height: 12),
                        SizedBox(width: double.infinity, child: ticketsButton),
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: invoiceButton),
                      ],
                    );
                  }

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(flex: 4, child: documentsCard),
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

class _TravelDock extends StatelessWidget {
  const _TravelDock({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            startLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.94),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 1,
            color: accent.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 10),
          Text(
            endLabel,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              durationLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactFact extends StatelessWidget {
  const _CompactFact({required this.icon, required this.label, this.color});

  final dynamic icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = color ?? scheme.onSurface.withValues(alpha: 0.56);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, color: tone, size: 14),
          const SizedBox(width: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.92),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: tone,
                  ),
                ),
              ),
              Text(
                progressLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: tone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StaticProgressBar(progress: progress, tone: tone),
          const SizedBox(height: 8),
          Text(
            balanceLabel,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.54),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaticProgressBar extends StatelessWidget {
  const _StaticProgressBar({required this.progress, required this.tone});

  final double progress;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: scheme.surfaceContainerHighest,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: tone,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  const _DocumentsCard({
    required this.accent,
    required this.invoiceNumber,
    required this.ticketCountLabel,
  });

  final Color accent;
  final String invoiceNumber;
  final String ticketCountLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFile01,
                color: accent,
                size: 15,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoiceNumber,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.84),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  ticketCountLabel,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface.withValues(alpha: 0.54),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
