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
    final localizations = MaterialLocalizations.of(context);
    final statusTone = tripReservationTone(
      reservation.statusKey,
      Theme.of(context).colorScheme,
    );
    final paymentTone = tripReservationTone(
      reservation.paymentStatusKey,
      Theme.of(context).colorScheme,
    );
    final amountPaidLabel = RwfCurrency.format(reservation.amountPaidRwf);
    final paymentStatusLabel = t(lang, reservation.paymentStatusKey);
    final progressLabel = "${(reservation.paymentProgress * 100).round()}%";
    final travelWindow =
        "${localizations.formatShortMonthDay(reservation.startDate)} - ${localizations.formatShortMonthDay(reservation.endDate)}";
    final travelersLabel = t(
      lang,
      "trip_reservations.travelers_count",
    ).replaceAll("{count}", "${reservation.travelers}");
    final balanceLabel = reservation.balanceRwf == 0
        ? t(lang, "trip_reservations.balance_cleared")
        : t(
            lang,
            "trip_reservations.balance_remaining",
          ).replaceAll("{amount}", RwfCurrency.format(reservation.balanceRwf));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: reservation.accent.withValues(alpha: 0.26)),
        boxShadow: [
          BoxShadow(
            color: reservation.accent.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final stackHeader = constraints.maxWidth < 340;
                final heading = _CardHeading(
                  title: reservation.packageName,
                  subtitle: reservation.destination,
                );

                if (stackHeader) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      heading,
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
                    Expanded(child: heading),
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
            Row(
              children: [
                Expanded(
                  child: _FactTile(
                    icon: HugeIcons.strokeRoundedUserGroup,
                    value: travelersLabel,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FactTile(
                    icon: HugeIcons.strokeRoundedShield01,
                    value: reservation.confirmationCode,
                    color: reservation.accent,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FactTile(
                    icon: HugeIcons.strokeRoundedCalendar03,
                    value: travelWindow,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _PaymentSummaryCard(
              amountLabel: amountPaidLabel,
              paymentStatusLabel: paymentStatusLabel,
              progressLabel: progressLabel,
              balanceLabel: balanceLabel,
              progress: reservation.paymentProgress,
              tone: paymentTone,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: _ActionButton(
                      icon: HugeIcons.strokeRoundedTicket01,
                      label: t(lang, "trip_reservations.tickets"),
                      color: const Color(0xFF1877B8),
                      onTap: () => showTripTicketsDialog(
                        context,
                        reservation: reservation,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: _ActionButton(
                      icon: HugeIcons.strokeRoundedInvoice03,
                      label: t(lang, "trip_reservations.invoice"),
                      color: const Color(0xFF0F8F5F),
                      onTap: () => showTripInvoiceDialog(
                        context,
                        reservation: reservation,
                        billedName: billedName ?? "",
                        billedEmail: billedEmail,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CardHeading extends StatelessWidget {
  const _CardHeading({this.title = "", this.subtitle = ""});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: Color(0xFF14231C),
            letterSpacing: -0.35,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF5E6D64),
          ),
        ),
      ],
    );
  }
}

class _FactTile extends StatelessWidget {
  const _FactTile({required this.icon, required this.value, this.color});

  final dynamic icon;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final tone = color ?? const Color(0xFF5E6D64);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4EBE7)),
      ),
      child: Row(
        children: [
          HugeIcon(icon: icon, color: tone, size: 14),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF14231C),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({
    required this.amountLabel,
    required this.paymentStatusLabel,
    required this.progressLabel,
    required this.balanceLabel,
    required this.progress,
    required this.tone,
  });

  final String amountLabel;
  final String paymentStatusLabel;
  final String progressLabel;
  final String balanceLabel;
  final double progress;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBE7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _PaymentMetric(
                  label: t(lang, "trip_reservations.amount_paid"),
                  value: amountLabel,
                  valueColor: const Color(0xFF14231C),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _PaymentMetric(
                  label: t(lang, "trip_reservations.payment_status"),
                  value: paymentStatusLabel,
                  valueColor: tone,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _StaticProgressBar(progress: progress, tone: tone),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  balanceLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF5E6D64),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                progressLabel,
                style: TextStyle(
                  fontSize: 10.5,
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

class _PaymentMetric extends StatelessWidget {
  const _PaymentMetric({
    required this.label,
    required this.value,
    required this.valueColor,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Color(0xFF5E6D64),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _StaticProgressBar extends StatelessWidget {
  const _StaticProgressBar({required this.progress, required this.tone});

  final double progress;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 8,
        color: const Color(0xFFE4EBE7),
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final dynamic icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, color: color, size: 15),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF14231C),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
