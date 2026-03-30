import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "trip_reservations_dialogs.dart";
import "trip_reservations_models.dart";
import "trip_reservations_shared.dart";

class TripReservationsDocumentsSection extends StatelessWidget {
  const TripReservationsDocumentsSection({
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
          icon: HugeIcons.strokeRoundedFiles01,
          iconColor: const Color(0xFF1877B8),
          title: t(lang, "trip_reservations.documents_title"),
          subtitle: t(lang, "trip_reservations.documents_subtitle"),
        ),
        const SizedBox(height: 14),
        TripReservationsSurfaceCard(
          child: Column(
            children: [
              for (var index = 0; index < reservations.length; index++) ...[
                _DocumentReservationTile(
                  reservation: reservations[index],
                  billedName: billedName,
                  billedEmail: billedEmail,
                ),
                if (index != reservations.length - 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      height: 1,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.10),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DocumentReservationTile extends StatelessWidget {
  const _DocumentReservationTile({
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          reservation.packageName,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.92),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          reservation.destination,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.50),
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final stackActions = constraints.maxWidth < 360;
            final invoiceTile = _DocumentActionTile(
              icon: HugeIcons.strokeRoundedInvoice03,
              accent: const Color(0xFF0F8F5F),
              label: t(lang, "trip_reservations.invoice"),
              detail: reservation.invoice.invoiceNumber,
              onTap: () => showTripInvoiceDialog(
                context,
                reservation: reservation,
                billedName: billedName ?? "",
                billedEmail: billedEmail,
              ),
            );
            final ticketTile = _DocumentActionTile(
              icon: HugeIcons.strokeRoundedTicket01,
              accent: const Color(0xFF1877B8),
              label: t(lang, "trip_reservations.tickets"),
              detail: t(
                lang,
                "trip_reservations.ticket_count",
              ).replaceAll("{count}", "${reservation.tickets.length}"),
              onTap: () =>
                  showTripTicketsDialog(context, reservation: reservation),
            );

            if (stackActions) {
              return Column(
                children: [invoiceTile, const SizedBox(height: 10), ticketTile],
              );
            }

            return Row(
              children: [
                Expanded(child: invoiceTile),
                const SizedBox(width: 10),
                Expanded(child: ticketTile),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _DocumentActionTile extends StatelessWidget {
  const _DocumentActionTile({
    required this.icon,
    required this.accent,
    required this.label,
    required this.detail,
    required this.onTap,
  });

  final dynamic icon;
  final Color accent;
  final String label;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: HugeIcon(icon: icon, color: accent, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface.withValues(alpha: 0.86),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.52),
                      ),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: accent,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
