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
    final scheme = Theme.of(context).colorScheme;
    final eventTone = eventTicketTone(ticket.eventStatusKey, scheme);
    final ticketTone = eventTicketTone(ticket.ticketStateKey, scheme);

    return EventTicketsSurfaceCard(
      padding: EdgeInsets.zero,
      borderColor: ticket.accent.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final stackedLayout = constraints.maxWidth < 560;
                final ticketLead = _TicketLead(
                  ticket: ticket,
                  eventTone: eventTone,
                  ticketTone: ticketTone,
                );
                final priceStub = _TicketPriceStub(ticket: ticket);

                return stackedLayout
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ticketLead,
                          const SizedBox(height: 16),
                          priceStub,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: ticketLead),
                          const SizedBox(width: 16),
                          SizedBox(width: 210, child: priceStub),
                        ],
                      );
              },
            ),
          ),
          _TicketDividerBand(accent: ticket.accent),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                  children: [
                    Expanded(
                      child: EventTicketsActionButton(
                        icon: HugeIcons.strokeRoundedTicket02,
                        label: t(lang, "my_events.tickets.view_pass"),
                        onTap: () => showEventTicketPassDialog(context, ticket),
                        color: ticket.accent,
                        isFilled: true,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: EventTicketsActionButton(
                        icon: HugeIcons.strokeRoundedInvoice03,
                        label: t(lang, "my_events.tickets.payment_details"),
                        onTap: () =>
                            showEventTicketPaymentDialog(context, ticket),
                        color: ticket.accent,
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
  const _TicketLead({
    required this.ticket,
    required this.eventTone,
    required this.ticketTone,
  });

  final EventTicketPreview ticket;
  final Color eventTone;
  final Color ticketTone;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final hasConsumable =
        ticket.consumable &&
        (ticket.consumableDescription ?? "").trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            EventTicketsMetaPill(
              icon: HugeIcons.strokeRoundedBookmark01,
              label: ticket.orderNumber,
              color: ticket.accent,
            ),
            EventTicketsStateBadge(
              label: t(lang, ticket.eventStatusKey),
              color: eventTone,
            ),
            EventTicketsStateBadge(
              label: t(lang, ticket.ticketStateKey),
              color: ticketTone,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Text(
          ticket.eventTitle,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.4,
            color: scheme.onSurface.withValues(alpha: 0.95),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "${ticket.venue} · ${ticket.city}",
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            EventTicketsMetaPill(
              icon: HugeIcons.strokeRoundedCalendar03,
              label: formatEventWindow(context, ticket.startAt, ticket.endAt),
            ),
            EventTicketsMetaPill(
              icon: HugeIcons.strokeRoundedTicket01,
              label: t(lang, ticket.ticketCategoryKey),
              color: ticket.accent,
            ),
            EventTicketsMetaPill(
              icon: HugeIcons.strokeRoundedUserGroup,
              label: t(
                lang,
                "my_events.tickets.quantity_count",
              ).replaceAll("{count}", "${ticket.quantity}"),
            ),
          ],
        ),
        if (hasConsumable) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: ticket.accent.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: ticket.accent.withValues(alpha: 0.10)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  size: 15,
                  color: ticket.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 11.5,
                        height: 1.4,
                        color: scheme.onSurface.withValues(alpha: 0.76),
                      ),
                      children: [
                        TextSpan(
                          text: "${t(lang, "my_events.tickets.consumables")}: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        TextSpan(text: ticket.consumableDescription!.trim()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TicketPriceStub extends StatelessWidget {
  const _TicketPriceStub({required this.ticket});

  final EventTicketPreview ticket;

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Container(
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
          const SizedBox(height: 14),
          _PaymentFact(
            label: t(lang, "my_events.tickets.payment_method"),
            value: t(lang, ticket.paymentMethodKey),
          ),
          const SizedBox(height: 10),
          _PaymentFact(
            label: t(lang, "my_events.tickets.order_number"),
            value: ticket.orderNumber,
          ),
        ],
      ),
    );
  }
}

class _PaymentFact extends StatelessWidget {
  const _PaymentFact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
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
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withValues(alpha: 0.92),
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
