import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../../core/utils/rwf_currency.dart";
import "../../../../../../i18n/lang.dart";
import "../../../../../../i18n/translations.dart";
import "event_tickets_models.dart";
import "event_tickets_shared.dart";

Future<void> showEventTicketDetailsDialog(
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
        title: t(lang, "my_events.tickets.details_dialog_title"),
        subtitle: ticket.eventTitle,
        accent: accent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t(lang, "my_events.tickets.ticket_price"),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: accent,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                RwfCurrency.format(ticket.unitPriceRwf),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.8,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
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
