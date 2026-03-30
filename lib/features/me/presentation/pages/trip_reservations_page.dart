import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/services/auth_session.dart";
import "../../../../core/utils/rwf_currency.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/trip_reservations/trip_reservations_documents_section.dart";
import "../widgets/trip_reservations/trip_reservations_header.dart";
import "../widgets/trip_reservations/trip_reservations_metrics_row.dart";
import "../widgets/trip_reservations/trip_reservations_models.dart";
import "../widgets/trip_reservations/trip_reservations_reservations_section.dart";

class TripReservationsPage extends StatelessWidget {
  const TripReservationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final session = AuthSession.instance.value;
    final email = (session.user?["email"] ?? "traveler@inotra.app").toString();
    final displayName = _displayName(session.displayName, email, lang);
    final reservations = sampleTripReservations;

    final upcomingCount = reservations.where((item) => item.isUpcoming).length;
    final totalPasses = reservations.fold<int>(
      0,
      (sum, item) => sum + item.tickets.length,
    );
    final totalPaidRwf = reservations.fold<int>(
      0,
      (sum, item) => sum + item.amountPaidRwf,
    );
    final nextTrip = reservations.firstWhere(
      (item) => item.isUpcoming,
      orElse: () => reservations.first,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width >= 1180
            ? 28.0
            : width >= 760
            ? 24.0
            : 16.0;
        final contentWidth = math.max(0.0, width - (horizontalPadding * 2));
        final showSideDocuments = contentWidth >= 1060;

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
                      TripReservationsHeader(
                        displayName: displayName,
                        email: email,
                        nextTrip: nextTrip,
                      ),
                      const SizedBox(height: 16),
                      TripReservationsMetricsRow(
                        items: [
                          TripReservationMetricItem(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            label: t(
                              lang,
                              "trip_reservations.summary_upcoming",
                            ),
                            value: "$upcomingCount",
                            detail: t(
                              lang,
                              "trip_reservations.summary_upcoming_sub",
                            ),
                            accent: const Color(0xFF0F8F5F),
                          ),
                          TripReservationMetricItem(
                            icon: HugeIcons.strokeRoundedTicket01,
                            label: t(lang, "trip_reservations.summary_passes"),
                            value: "$totalPasses",
                            detail: t(
                              lang,
                              "trip_reservations.summary_passes_sub",
                            ),
                            accent: const Color(0xFF1877B8),
                          ),
                          TripReservationMetricItem(
                            icon: HugeIcons.strokeRoundedInvoice03,
                            label: t(
                              lang,
                              "trip_reservations.summary_invoices",
                            ),
                            value: "${reservations.length}",
                            detail: t(
                              lang,
                              "trip_reservations.summary_invoices_sub",
                            ),
                            accent: const Color(0xFFC07A12),
                          ),
                          TripReservationMetricItem(
                            icon: HugeIcons.strokeRoundedWallet02,
                            label: t(
                              lang,
                              "trip_reservations.summary_total_paid",
                            ),
                            value: RwfCurrency.format(totalPaidRwf),
                            detail: t(
                              lang,
                              "trip_reservations.summary_total_paid_sub",
                            ),
                            accent: const Color(0xFF5E6B7A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (showSideDocuments)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: TripReservationsSection(
                                reservations: reservations,
                                billedName: session.displayName,
                                billedEmail: email,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 5,
                              child: TripReservationsDocumentsSection(
                                reservations: reservations,
                                billedName: session.displayName,
                                billedEmail: email,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        TripReservationsSection(
                          reservations: reservations,
                          billedName: session.displayName,
                          billedEmail: email,
                        ),
                        const SizedBox(height: 18),
                        TripReservationsDocumentsSection(
                          reservations: reservations,
                          billedName: session.displayName,
                          billedEmail: email,
                        ),
                      ],
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

  String _displayName(String? displayName, String email, String lang) {
    final trimmed = (displayName ?? "").trim();
    if (trimmed.isNotEmpty) {
      return trimmed.split(" ").first;
    }

    final emailName = email.split("@").first.trim();
    if (emailName.isNotEmpty) {
      return emailName;
    }

    return t(lang, "trip_reservations.guest_fallback");
  }
}
