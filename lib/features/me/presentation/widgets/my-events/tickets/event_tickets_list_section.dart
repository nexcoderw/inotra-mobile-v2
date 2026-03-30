import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../core/utils/rwf_currency.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "event_tickets_dialogs.dart";
import "event_tickets_models.dart";
import "event_tickets_shared.dart";

class EventTicketsListSection extends StatelessWidget {
  const EventTicketsListSection({super.key, required this.tickets});

  final List<EventTicketPreview> tickets;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EventTicketsSectionHeader(
          icon: HugeIcons.strokeRoundedTicket01,
          iconColor: const Color(0xFF0F8F5F),
          title: t(lang, "my_events.tickets.list_title"),
          subtitle: t(lang, "my_events.tickets.list_subtitle"),
        ),
        const SizedBox(height: 14),
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
                for (final ticket in tickets)
                  SizedBox(
                    width: cardWidth,
                    child: _EventTicketCard(ticket: ticket),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _EventTicketCard extends StatelessWidget {
  const _EventTicketCard({required this.ticket});

  final EventTicketPreview ticket;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();

    return EventTicketsSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: ticket.accent.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: _TicketLead(ticket: ticket),
          ),
          _TicketDividerBand(accent: ticket.accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TotalPaidSection(ticket: ticket),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wideFacts = constraints.maxWidth >= 720;
                    final factWidth = wideFacts
                        ? (constraints.maxWidth - 24) / 3
                        : (constraints.maxWidth - 10) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        _TicketFact(
                          width: factWidth,
                          label: t(lang, "my_events.tickets.ticket_code"),
                          value: ticket.ticketCode,
                        ),
                        _TicketFact(
                          width: factWidth,
                          label: t(lang, "my_events.tickets.purchased_on"),
                          value: formatIssuedDate(context, ticket.purchasedAt),
                        ),
                        _TicketFact(
                          width: factWidth,
                          label: t(lang, "my_events.tickets.payment_reference"),
                          value: ticket.paymentReference,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(child: _TicketPriceRow(ticket: ticket)),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 126,
                      child: EventTicketsActionButton(
                        icon: HugeIcons.strokeRoundedView,
                        label: t(lang, "my_events.tickets.details"),
                        onTap: () =>
                            showEventTicketDetailsDialog(context, ticket),
                        color: Theme.of(context).colorScheme.primary,
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

class _TicketLead extends StatelessWidget {
  const _TicketLead({required this.ticket});

  final EventTicketPreview ticket;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                ticket.eventTitle,
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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.primary.withValues(alpha: 0.14),
                ),
              ),
              child: Text(
                t(lang, ticket.ticketCategoryKey),
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
        Row(
          children: [
            Expanded(
              child: _HeaderMeta(
                icon: HugeIcons.strokeRoundedLocation01,
                label: "${ticket.venue} · ${ticket.city}",
              ),
            ),
            const SizedBox(width: 12),
            _HeaderMeta(
              icon: HugeIcons.strokeRoundedCalendar03,
              label: formatEventMonthDay(context, ticket.startAt),
            ),
          ],
        ),
      ],
    );
  }
}

class _TotalPaidSection extends StatelessWidget {
  const _TotalPaidSection({required this.ticket});

  final EventTicketPreview ticket;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ticket.accent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: ticket.accent.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "my_events.tickets.total_paid"),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: ticket.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            RwfCurrency.format(ticket.totalPaidRwf),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
              color: scheme.onSurface,
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

class _TicketPriceRow extends StatelessWidget {
  const _TicketPriceRow({required this.ticket});

  final EventTicketPreview ticket;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t(lang, "my_events.tickets.ticket_price"),
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.50),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          RwfCurrency.format(ticket.unitPriceRwf),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TicketFact extends StatelessWidget {
  const _TicketFact({
    required this.width,
    required this.label,
    required this.value,
  });

  final double width;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.92),
            ),
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
