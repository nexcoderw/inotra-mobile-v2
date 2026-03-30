import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../core/utils/rwf_currency.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "event_tickets_models.dart";
import "event_tickets_shared.dart";

Future<void> showEventTicketPassDialog(
  BuildContext context,
  EventTicketPreview ticket,
) {
  final lang = currentLangSync();
  final accent = eventTicketTone(
    ticket.ticketStateKey,
    Theme.of(context).colorScheme,
  );

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return _EventTicketDialogShell(
        title: t(lang, "my_events.tickets.pass_dialog_title"),
        subtitle: ticket.eventTitle,
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
                      EventTicketsStateBadge(
                        label: t(lang, ticket.ticketStateKey),
                        color: accent,
                      ),
                      const Spacer(),
                      Text(
                        RwfCurrency.format(ticket.totalPaidRwf),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    ticket.eventTitle,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: Theme.of(dialogContext).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    formatEventWindow(
                      dialogContext,
                      ticket.startAt,
                      ticket.endAt,
                    ),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(
                        dialogContext,
                      ).colorScheme.onSurface.withValues(alpha: 0.62),
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
                      color: Theme.of(
                        dialogContext,
                      ).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t(lang, "my_events.tickets.ticket_code"),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                            color: Theme.of(
                              dialogContext,
                            ).colorScheme.onSurface.withValues(alpha: 0.48),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          ticket.ticketCode,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Theme.of(
                              dialogContext,
                            ).colorScheme.onSurface,
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
                  label: t(lang, "my_events.tickets.issued_to"),
                  value: ticket.holderName,
                ),
                _DialogFact(
                  label: t(lang, "my_events.tickets.quantity"),
                  value: _countLabel(lang, ticket.quantity),
                ),
                _DialogFact(
                  label: t(lang, "my_events.tickets.section"),
                  value: ticket.sectionLabel,
                ),
                _DialogFact(
                  label: t(lang, "my_events.tickets.entry_window"),
                  value: ticket.entryWindow,
                ),
              ],
            ),
            if (ticket.perkKeys.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                t(lang, "my_events.tickets.includes"),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(dialogContext).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final perkKey in ticket.perkKeys)
                    EventTicketsMetaPill(
                      icon: HugeIcons.strokeRoundedCheckmarkBadge01,
                      label: t(lang, perkKey),
                      color: accent,
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

Future<void> showEventTicketPaymentDialog(
  BuildContext context,
  EventTicketPreview ticket,
) {
  final lang = currentLangSync();
  final accent = eventTicketTone(
    ticket.ticketStateKey,
    Theme.of(context).colorScheme,
  );

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final scheme = Theme.of(dialogContext).colorScheme;

      return _EventTicketDialogShell(
        title: t(lang, "my_events.tickets.payment_dialog_title"),
        subtitle: ticket.orderNumber,
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
                  Text(
                    t(lang, "my_events.tickets.total_paid"),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    RwfCurrency.format(ticket.totalPaidRwf),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.7,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticket.eventTitle,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            _DialogRow(
              label: t(lang, "my_events.tickets.payment_method"),
              value: t(lang, ticket.paymentMethodKey),
            ),
            _DialogRow(
              label: t(lang, "my_events.tickets.payment_reference"),
              value: ticket.paymentReference,
            ),
            _DialogRow(
              label: t(lang, "my_events.tickets.purchased_on"),
              value: formatIssuedDate(dialogContext, ticket.purchasedAt),
            ),
            _DialogRow(
              label: t(lang, "my_events.tickets.order_number"),
              value: ticket.orderNumber,
            ),
            _DialogRow(
              label: t(lang, "my_events.tickets.ticket_code"),
              value: ticket.ticketCode,
            ),
            _DialogRow(
              label: t(lang, "my_events.tickets.quantity"),
              value: _countLabel(lang, ticket.quantity),
            ),
            _DialogRow(
              label: t(lang, "my_events.tickets.unit_price"),
              value: RwfCurrency.format(ticket.unitPriceRwf),
            ),
            _DialogRow(
              label: t(lang, "my_events.tickets.section"),
              value: ticket.sectionLabel,
              isLast: ticket.perkKeys.isEmpty,
            ),
            if (ticket.perkKeys.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                t(lang, "my_events.tickets.includes"),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final perkKey in ticket.perkKeys)
                    EventTicketsMetaPill(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                      label: t(lang, perkKey),
                      color: accent,
                    ),
                ],
              ),
            ],
          ],
        ),
      );
    },
  );
}

class _EventTicketDialogShell extends StatelessWidget {
  const _EventTicketDialogShell({
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
        child: EventTicketsSurfaceCard(
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
                        icon: HugeIcons.strokeRoundedTicket02,
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

String _countLabel(String lang, int count) {
  return t(
    lang,
    "my_events.tickets.quantity_count",
  ).replaceAll("{count}", "$count");
}
