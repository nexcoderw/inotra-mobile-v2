import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/utils/rwf_currency.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "../../widgets/my-events/tickets/event_tickets_header.dart";
import "../../widgets/my-events/tickets/event_tickets_list_section.dart";
import "../../widgets/my-events/tickets/event_tickets_metrics_row.dart";
import "../../widgets/my-events/tickets/event_tickets_models.dart";

class EventTicketsPage extends StatelessWidget {
  const EventTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final tickets = sampleEventTickets;

    final upcomingCount = tickets.where((ticket) => ticket.isUpcoming).length;
    final totalEntries = tickets.fold<int>(
      0,
      (sum, ticket) => sum + ticket.quantity,
    );
    final totalPaidRwf = tickets.fold<int>(
      0,
      (sum, ticket) => sum + ticket.totalPaidRwf,
    );
    final paymentMethodCount = tickets
        .map((ticket) => ticket.paymentMethodKey)
        .toSet()
        .length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width >= 1180
            ? 28.0
            : width >= 760
            ? 24.0
            : 16.0;

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface,
                Theme.of(
                  context,
                ).colorScheme.surfaceContainerLowest.withValues(alpha: 0.96),
              ],
            ),
          ),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  32,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const EventTicketsHeader(),
                      const SizedBox(height: 16),
                      EventTicketsMetricsRow(
                        items: [
                          EventTicketMetricItem(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            label: t(
                              lang,
                              "my_events.tickets.summary_upcoming",
                            ),
                            value: "$upcomingCount",
                            detail: t(
                              lang,
                              "my_events.tickets.summary_upcoming_sub",
                            ),
                            accent: const Color(0xFF0F8F5F),
                          ),
                          EventTicketMetricItem(
                            icon: HugeIcons.strokeRoundedTicket01,
                            label: t(lang, "my_events.tickets.summary_owned"),
                            value: "$totalEntries",
                            detail: t(
                              lang,
                              "my_events.tickets.summary_owned_sub",
                            ),
                            accent: const Color(0xFF1877B8),
                          ),
                          EventTicketMetricItem(
                            icon: HugeIcons.strokeRoundedWallet02,
                            label: t(lang, "my_events.tickets.summary_paid"),
                            value: RwfCurrency.format(totalPaidRwf),
                            detail: t(
                              lang,
                              "my_events.tickets.summary_paid_sub",
                            ),
                            accent: const Color(0xFFC07A12),
                          ),
                          EventTicketMetricItem(
                            icon: HugeIcons.strokeRoundedCreditCard,
                            label: t(lang, "my_events.tickets.summary_methods"),
                            value: "$paymentMethodCount",
                            detail: t(
                              lang,
                              "my_events.tickets.summary_methods_sub",
                            ),
                            accent: const Color(0xFF5E6B7A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      EventTicketsListSection(tickets: tickets),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
