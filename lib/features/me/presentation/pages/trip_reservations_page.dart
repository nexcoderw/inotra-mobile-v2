import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/utils/rwf_currency.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class TripReservationsPage extends StatelessWidget {
  const TripReservationsPage({super.key});

  static const _reservations = [
    _TripReservation(
      packageName: "Volcano Ridge Escape",
      destination: "Musanze, Rwanda",
      travelWindow: "06 Apr - 10 Apr 2026",
      durationLabel: "4 nights",
      confirmationCode: "INO-TRP-24061",
      status: "Upcoming",
      paymentStatus: "Paid in full",
      totalAmountRwf: 1860000,
      amountPaidRwf: 1860000,
      travelers: 3,
      coverTone: Color(0xFF0F8F5F),
      supportNote:
          "Airport transfer, permit confirmation and lodge check-in are already locked in.",
      ticketSummary:
          "3 digital travel passes are ready for lodge access and activity check-in.",
      tickets: [
        _TripTicket(
          label: "Traveler Pass",
          holder: "Primary Guest",
          code: "TRV-901-24A",
          state: "Active",
        ),
        _TripTicket(
          label: "Traveler Pass",
          holder: "Guest 02",
          code: "TRV-901-24B",
          state: "Active",
        ),
        _TripTicket(
          label: "Permit Access",
          holder: "Guest 03",
          code: "PRM-771-09C",
          state: "Issued",
        ),
      ],
      invoice: _InvoicePreview(
        invoiceNumber: "INV-TRIP-24061",
        issuedOn: "30 Mar 2026",
        paidOn: "30 Mar 2026",
        paymentMethod: "Card payment",
        paymentReference: "PYR-448201",
        status: "Paid",
        lineItems: [
          _InvoiceLine(
            title: "Volcano Ridge Escape package",
            subtitle: "3 travelers · 4 nights",
            amountRwf: 1620000,
          ),
          _InvoiceLine(
            title: "Private airport transfer",
            subtitle: "Arrival and departure",
            amountRwf: 120000,
          ),
          _InvoiceLine(
            title: "Permit handling",
            subtitle: "Processing and issuance",
            amountRwf: 90000,
          ),
        ],
        serviceFeeRwf: 30000,
      ),
    ),
    _TripReservation(
      packageName: "Lake Kivu Signature Retreat",
      destination: "Karongi, Rwanda",
      travelWindow: "18 Apr - 21 Apr 2026",
      durationLabel: "3 nights",
      confirmationCode: "INO-TRP-24092",
      status: "Confirmed",
      paymentStatus: "Deposit received",
      totalAmountRwf: 980000,
      amountPaidRwf: 420000,
      travelers: 2,
      coverTone: Color(0xFFC07A12),
      supportNote:
          "Your room category is reserved. Final confirmation will clear automatically after balance payment.",
      ticketSummary:
          "2 digital boarding vouchers will be released immediately after the remaining balance is settled.",
      tickets: [
        _TripTicket(
          label: "Reservation Voucher",
          holder: "Primary Guest",
          code: "RSV-518-72A",
          state: "Pending release",
        ),
        _TripTicket(
          label: "Reservation Voucher",
          holder: "Guest 02",
          code: "RSV-518-72B",
          state: "Pending release",
        ),
      ],
      invoice: _InvoicePreview(
        invoiceNumber: "INV-TRIP-24092",
        issuedOn: "31 Mar 2026",
        paidOn: "Deposit on 31 Mar 2026",
        paymentMethod: "Mobile money",
        paymentReference: "MOMO-981504",
        status: "Partially paid",
        lineItems: [
          _InvoiceLine(
            title: "Lake Kivu Signature Retreat",
            subtitle: "2 travelers · 3 nights",
            amountRwf: 840000,
          ),
          _InvoiceLine(
            title: "Sunset boat cruise",
            subtitle: "Private session",
            amountRwf: 90000,
          ),
        ],
        serviceFeeRwf: 50000,
      ),
    ),
    _TripReservation(
      packageName: "Akagera Premium Safari",
      destination: "Eastern Province, Rwanda",
      travelWindow: "09 Mar - 12 Mar 2026",
      durationLabel: "3 nights",
      confirmationCode: "INO-TRP-23814",
      status: "Completed",
      paymentStatus: "Closed",
      totalAmountRwf: 2240000,
      amountPaidRwf: 2240000,
      travelers: 4,
      coverTone: Color(0xFF1877B8),
      supportNote:
          "This stay is completed. Your invoice, itinerary copy and access passes remain available below.",
      ticketSummary:
          "4 archived travel passes remain accessible for reimbursement and record-keeping.",
      tickets: [
        _TripTicket(
          label: "Safari Access Pass",
          holder: "Primary Guest",
          code: "SFR-211-11A",
          state: "Archived",
        ),
        _TripTicket(
          label: "Safari Access Pass",
          holder: "Guest 02",
          code: "SFR-211-11B",
          state: "Archived",
        ),
        _TripTicket(
          label: "Safari Access Pass",
          holder: "Guest 03",
          code: "SFR-211-11C",
          state: "Archived",
        ),
        _TripTicket(
          label: "Safari Access Pass",
          holder: "Guest 04",
          code: "SFR-211-11D",
          state: "Archived",
        ),
      ],
      invoice: _InvoicePreview(
        invoiceNumber: "INV-TRIP-23814",
        issuedOn: "01 Mar 2026",
        paidOn: "01 Mar 2026",
        paymentMethod: "Bank transfer",
        paymentReference: "BNK-772014",
        status: "Paid",
        lineItems: [
          _InvoiceLine(
            title: "Akagera Premium Safari",
            subtitle: "4 travelers · 3 nights",
            amountRwf: 1980000,
          ),
          _InvoiceLine(
            title: "Private game drive supplement",
            subtitle: "Exclusive vehicle allocation",
            amountRwf: 210000,
          ),
        ],
        serviceFeeRwf: 50000,
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final session = AuthSession.instance.value;
    final displayName = _firstName(session.displayName);
    final email = (session.user?["email"] ?? "traveler@inotra.app").toString();

    final upcomingCount = _reservations.where((item) => item.isUpcoming).length;
    final ticketCount = _reservations.fold<int>(
      0,
      (sum, item) => sum + item.tickets.length,
    );
    final paidInvoices = _reservations.where(
      (item) => item.invoice.status.toLowerCase() == "paid",
    );
    final totalSpentRwf = paidInvoices.fold<int>(
      0,
      (sum, item) => sum + item.totalAmountRwf,
    );
    final nextTrip = _reservations.firstWhere(
      (item) => item.isUpcoming,
      orElse: () => _reservations.first,
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
        final isWide = contentWidth >= 1020;

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scheme.surface,
                scheme.surfaceContainerLowest.withValues(alpha: 0.95),
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
                      _HeroPanel(
                        title: t(lang, "nav.trip_reservations"),
                        displayName: displayName,
                        email: email,
                        nextTrip: nextTrip,
                        upcomingCount: upcomingCount,
                        ticketCount: ticketCount,
                        totalSpent: RwfCurrency.format(totalSpentRwf),
                      ),
                      const SizedBox(height: 18),
                      _SummaryGrid(
                        contentWidth: contentWidth,
                        summaryItems: [
                          _SummaryItem(
                            icon: HugeIcons.strokeRoundedCalendar03,
                            label: "Upcoming trips",
                            value: "$upcomingCount",
                            detail: "Reserved packages still ahead",
                            accent: const Color(0xFF0F8F5F),
                          ),
                          _SummaryItem(
                            icon: HugeIcons.strokeRoundedTicket01,
                            label: "Travel passes",
                            value: "$ticketCount",
                            detail: "Active and archived tickets",
                            accent: const Color(0xFF1877B8),
                          ),
                          _SummaryItem(
                            icon: HugeIcons.strokeRoundedInvoice03,
                            label: "Invoices available",
                            value: "${_reservations.length}",
                            detail: "Tap any invoice to inspect details",
                            accent: const Color(0xFFC07A12),
                          ),
                          _SummaryItem(
                            icon: HugeIcons.strokeRoundedWallet02,
                            label: "Total paid",
                            value: RwfCurrency.format(totalSpentRwf),
                            detail: "RWF-only billing across your trips",
                            accent: const Color(0xFF5E6B7A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 7,
                              child: _ReservationsSection(
                                reservations: _reservations,
                                billedName: session.displayName,
                                billedEmail: email,
                              ),
                            ),
                            const SizedBox(width: 18),
                            Expanded(
                              flex: 5,
                              child: Column(
                                children: [
                                  _DocumentHubCard(
                                    reservations: _reservations,
                                    billedName: session.displayName,
                                    billedEmail: email,
                                  ),
                                  const SizedBox(height: 18),
                                  const _SupportCard(),
                                ],
                              ),
                            ),
                          ],
                        )
                      else ...[
                        _ReservationsSection(
                          reservations: _reservations,
                          billedName: session.displayName,
                          billedEmail: email,
                        ),
                        const SizedBox(height: 18),
                        _DocumentHubCard(
                          reservations: _reservations,
                          billedName: session.displayName,
                          billedEmail: email,
                        ),
                        const SizedBox(height: 18),
                        const _SupportCard(),
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

  static Future<void> showInvoiceDialog(
    BuildContext context, {
    required _TripReservation reservation,
    required String billedName,
    required String billedEmail,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final width = MediaQuery.sizeOf(dialogContext).width;

        return Dialog(
          insetPadding: EdgeInsets.symmetric(
            horizontal: width >= 720 ? 32 : 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 720,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.84,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DialogTag(
                                icon: HugeIcons.strokeRoundedInvoice03,
                                label: "Invoice",
                                accent: reservation.coverTone,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                reservation.invoice.invoiceNumber,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.94,
                                  ),
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                reservation.packageName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.64,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _MetaChip(
                                icon: HugeIcons.strokeRoundedTick02,
                                label: reservation.invoice.status,
                              ),
                              _MetaChip(
                                icon: HugeIcons.strokeRoundedCalendar03,
                                label: reservation.invoice.issuedOn,
                              ),
                              _MetaChip(
                                icon: HugeIcons.strokeRoundedWallet02,
                                label: reservation.invoice.paymentMethod,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _InvoiceInfoGrid(
                            children: [
                              _InfoTile(
                                label: "Billed to",
                                value: billedName.trim().isEmpty
                                    ? "Guest traveler"
                                    : billedName,
                              ),
                              _InfoTile(label: "Email", value: billedEmail),
                              _InfoTile(
                                label: "Travel window",
                                value: reservation.travelWindow,
                              ),
                              _InfoTile(
                                label: "Reference",
                                value: reservation.invoice.paymentReference,
                              ),
                              _InfoTile(
                                label: "Confirmation code",
                                value: reservation.confirmationCode,
                              ),
                              _InfoTile(
                                label: "Payment recorded",
                                value: reservation.invoice.paidOn,
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            "Charges",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface.withValues(alpha: 0.92),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ...reservation.invoice.lineItems.map(
                            (line) => Padding(
                              padding: EdgeInsets.only(
                                bottom:
                                    line == reservation.invoice.lineItems.last
                                    ? 0
                                    : 10,
                              ),
                              child: _InvoiceLineTile(line: line),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: scheme.surfaceContainerLowest.withValues(
                                alpha: 0.86,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: scheme.onSurface.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Column(
                              children: [
                                _AmountRow(
                                  label: "Subtotal",
                                  value: RwfCurrency.format(
                                    reservation.invoice.subtotalRwf,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _AmountRow(
                                  label: "Service fee",
                                  value: RwfCurrency.format(
                                    reservation.invoice.serviceFeeRwf,
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                _AmountRow(
                                  label: "Total",
                                  value: RwfCurrency.format(
                                    reservation.invoice.totalRwf,
                                  ),
                                  emphasize: true,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> showTicketsDialog(
    BuildContext context, {
    required _TripReservation reservation,
  }) {
    final scheme = Theme.of(context).colorScheme;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 640,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.80,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: scheme.surface,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _DialogTag(
                                icon: HugeIcons.strokeRoundedTicket01,
                                label: "Travel passes",
                                accent: reservation.coverTone,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                reservation.packageName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.94,
                                  ),
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                reservation.ticketSummary,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  fontWeight: FontWeight.w500,
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.64,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: reservation.tickets.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final ticket = reservation.tickets[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerLowest.withValues(
                              alpha: 0.88,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: scheme.onSurface.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: reservation.coverTone.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: HugeIcon(
                                    icon: HugeIcons.strokeRoundedTicket01,
                                    size: 18,
                                    color: reservation.coverTone,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ticket.label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.92,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      ticket.holder,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: scheme.onSurface.withValues(
                                          alpha: 0.60,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      ticket.code,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: reservation.coverTone,
                                        letterSpacing: 0.1,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _StateBadge(
                                label: ticket.state,
                                accent: reservation.coverTone,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  final String title;
  final String displayName;
  final String email;
  final _TripReservation nextTrip;
  final int upcomingCount;
  final int ticketCount;
  final String totalSpent;

  const _HeroPanel({
    required this.title,
    required this.displayName,
    required this.email,
    required this.nextTrip,
    required this.upcomingCount,
    required this.ticketCount,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final split = width >= 900;

    final intro = Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  size: 12,
                  color: Colors.white,
                ),
                SizedBox(width: 6),
                Text(
                  "Reservations preview",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.7,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "${displayName.trim().isEmpty ? "Traveler" : displayName}, your reserved packages, travel passes and billing documents are organized in one polished space.",
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.80),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroChip(
                icon: HugeIcons.strokeRoundedCalendar03,
                label: "$upcomingCount upcoming trips",
              ),
              _HeroChip(
                icon: HugeIcons.strokeRoundedTicket01,
                label: "$ticketCount travel passes",
              ),
              _HeroChip(
                icon: HugeIcons.strokeRoundedWallet02,
                label: totalSpent,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            email,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    final nextTripCard = Container(
      width: split ? 330 : double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Next reserved trip",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.66),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            nextTrip.packageName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            nextTrip.destination,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: "Travel window",
                  value: nextTrip.travelWindow,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: "Confirmation",
                  value: nextTrip.confirmationCode,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF072C18), Color(0xFF0E5A38), Color(0xFF0B4365)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -48,
            right: -18,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -30,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: split
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [intro, const SizedBox(width: 18), nextTripCard],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [intro]),
                      const SizedBox(height: 18),
                      nextTripCard,
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final double contentWidth;
  final List<_SummaryItem> summaryItems;

  const _SummaryGrid({required this.contentWidth, required this.summaryItems});

  @override
  Widget build(BuildContext context) {
    final itemWidth = contentWidth >= 1120
        ? (contentWidth - 36) / 4
        : contentWidth >= 700
        ? (contentWidth - 12) / 2
        : contentWidth;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: summaryItems
          .map(
            (item) => SizedBox(
              width: itemWidth,
              child: _SummaryCard(item: item),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _ReservationsSection extends StatelessWidget {
  final List<_TripReservation> reservations;
  final String billedName;
  final String billedEmail;

  const _ReservationsSection({
    required this.reservations,
    required this.billedName,
    required this.billedEmail,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Your reserved packages",
            description:
                "Every trip you booked appears here with travel passes, payment state and direct invoice access.",
          ),
          const SizedBox(height: 18),
          Column(
            children: reservations
                .map(
                  (reservation) => Padding(
                    padding: EdgeInsets.only(
                      bottom: reservation == reservations.last ? 0 : 12,
                    ),
                    child: _ReservationCard(
                      reservation: reservation,
                      billedName: billedName,
                      billedEmail: billedEmail,
                    ),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _DocumentHubCard extends StatelessWidget {
  final List<_TripReservation> reservations;
  final String billedName;
  final String billedEmail;

  const _DocumentHubCard({
    required this.reservations,
    required this.billedName,
    required this.billedEmail,
  });

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Documents hub",
            description:
                "Quick access to tickets and invoices for each package you reserved.",
          ),
          const SizedBox(height: 18),
          ...reservations.map(
            (reservation) => Padding(
              padding: EdgeInsets.only(
                bottom: reservation == reservations.last ? 0 : 12,
              ),
              child: _DocumentTile(
                reservation: reservation,
                onInvoiceTap: () => TripReservationsPage.showInvoiceDialog(
                  context,
                  reservation: reservation,
                  billedName: billedName,
                  billedEmail: billedEmail,
                ),
                onTicketTap: () => TripReservationsPage.showTicketsDialog(
                  context,
                  reservation: reservation,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionHeader(
            title: "Reservation support",
            description:
                "The live version of this page can surface support requests, change history and post-booking messages in the same layout.",
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLowest.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMessage02,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Planned support features",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _SupportPoint(
                  title: "Trip change requests",
                  detail:
                      "Date changes, traveler updates and add-on approvals.",
                ),
                const SizedBox(height: 10),
                const _SupportPoint(
                  title: "Document sync",
                  detail:
                      "Live invoice updates and regenerated ticket bundles.",
                ),
                const SizedBox(height: 10),
                const _SupportPoint(
                  title: "Operations messaging",
                  detail:
                      "One thread for pre-arrival guidance and reservation follow-up.",
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final _TripReservation reservation;
  final String billedName;
  final String billedEmail;

  const _ReservationCard({
    required this.reservation,
    required this.billedName,
    required this.billedEmail,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 700;

    final details = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _MetaChip(
          icon: HugeIcons.strokeRoundedCalendar03,
          label: reservation.travelWindow,
        ),
        _MetaChip(
          icon: HugeIcons.strokeRoundedUserGroup03,
          label: "${reservation.travelers} travelers",
        ),
        _MetaChip(
          icon: HugeIcons.strokeRoundedClock01,
          label: reservation.durationLabel,
        ),
        _MetaChip(
          icon: HugeIcons.strokeRoundedWallet02,
          label: reservation.paymentStatus,
        ),
      ],
    );

    final actions = Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _ActionButton(
          label: "Tickets",
          filled: false,
          icon: HugeIcons.strokeRoundedTicket01,
          onTap: () => TripReservationsPage.showTicketsDialog(
            context,
            reservation: reservation,
          ),
        ),
        _ActionButton(
          label: "Invoice",
          filled: true,
          icon: HugeIcons.strokeRoundedInvoice03,
          onTap: () => TripReservationsPage.showInvoiceDialog(
            context,
            reservation: reservation,
            billedName: billedName,
            billedEmail: billedEmail,
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: reservation.coverTone.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedLuggage02,
                      size: 20,
                      color: reservation.coverTone,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _StateBadge(
                            label: reservation.status,
                            accent: reservation.coverTone,
                          ),
                          _StateBadge(
                            label: reservation.invoice.status,
                            accent: const Color(0xFF5E6B7A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        reservation.packageName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface.withValues(alpha: 0.94),
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reservation.destination,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface.withValues(alpha: 0.62),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!compact)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "Booking total",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface.withValues(alpha: 0.50),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        RwfCurrency.format(reservation.totalAmountRwf),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: scheme.onSurface.withValues(alpha: 0.92),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            if (compact) ...[
              const SizedBox(height: 14),
              Text(
                RwfCurrency.format(reservation.totalAmountRwf),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withValues(alpha: 0.92),
                ),
              ),
            ],
            const SizedBox(height: 14),
            details,
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedTicket01,
                        size: 15,
                        color: reservation.coverTone,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reservation.ticketSummary,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.45,
                            color: scheme.onSurface.withValues(alpha: 0.74),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    reservation.supportNote,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.45,
                      color: scheme.onSurface.withValues(alpha: 0.60),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  "Confirmation ${reservation.confirmationCode}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: reservation.coverTone,
                    letterSpacing: 0.1,
                  ),
                ),
                Text(
                  "Paid ${RwfCurrency.format(reservation.amountPaidRwf)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            actions,
          ],
        ),
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  final _TripReservation reservation;
  final VoidCallback onInvoiceTap;
  final VoidCallback onTicketTap;

  const _DocumentTile({
    required this.reservation,
    required this.onInvoiceTap,
    required this.onTicketTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reservation.packageName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            reservation.invoice.invoiceNumber,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: reservation.coverTone,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MiniDocButton(
                  label: "Invoice",
                  icon: HugeIcons.strokeRoundedInvoice03,
                  onTap: onInvoiceTap,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniDocButton(
                  label: "Tickets",
                  icon: HugeIcons.strokeRoundedTicket01,
                  onTap: onTicketTap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  final Widget child;

  const _SurfaceCard({required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface.withValues(alpha: isDark ? 0.90 : 0.98),
            scheme.surfaceContainerLowest.withValues(
              alpha: isDark ? 0.94 : 1.0,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.05),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(18), child: child),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String description;

  const _SectionHeader({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withValues(alpha: 0.94),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.45,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final _SummaryItem item;

  const _SummaryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: item.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: HugeIcon(icon: item.icon, size: 18, color: item.accent),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.94),
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.detail,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withValues(alpha: 0.62),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final dynamic icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 14, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.58),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final dynamic icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 13,
            color: scheme.onSurface.withValues(alpha: 0.62),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.72),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  final String label;
  final Color accent;

  const _StateBadge({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: accent,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final dynamic icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: filled ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: filled
                  ? AppColors.primary
                  : scheme.onSurface.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(
                icon: icon,
                size: 14,
                color: filled ? Colors.white : scheme.onSurface,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: filled ? Colors.white : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniDocButton extends StatelessWidget {
  final String label;
  final dynamic icon;
  final VoidCallback onTap;

  const _MiniDocButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(icon: icon, size: 13, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.86),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogTag extends StatelessWidget {
  final dynamic icon;
  final String label;
  final Color accent;

  const _DialogTag({
    required this.icon,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceInfoGrid extends StatelessWidget {
  final List<Widget> children;

  const _InvoiceInfoGrid({required this.children});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final itemWidth = width >= 720 ? 200.0 : double.infinity;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: children
          .map((child) => SizedBox(width: itemWidth, child: child))
          .toList(growable: false),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withValues(alpha: 0.88),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceLineTile extends StatelessWidget {
  final _InvoiceLine line;

  const _InvoiceLineTile({required this.line});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.onSurface.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface.withValues(alpha: 0.90),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  line.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface.withValues(alpha: 0.60),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            RwfCurrency.format(line.amountRwf),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  final bool emphasize;

  const _AmountRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: emphasize ? 13 : 12,
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
              color: scheme.onSurface.withValues(
                alpha: emphasize ? 0.92 : 0.62,
              ),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: emphasize ? 15 : 13,
            fontWeight: FontWeight.w900,
            color: scheme.onSurface.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

class _SupportPoint extends StatelessWidget {
  final String title;
  final String detail;

  const _SupportPoint({required this.title, required this.detail});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 6),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                  color: scheme.onSurface.withValues(alpha: 0.60),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SummaryItem {
  final dynamic icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
  });
}

class _TripReservation {
  final String packageName;
  final String destination;
  final String travelWindow;
  final String durationLabel;
  final String confirmationCode;
  final String status;
  final String paymentStatus;
  final int totalAmountRwf;
  final int amountPaidRwf;
  final int travelers;
  final Color coverTone;
  final String supportNote;
  final String ticketSummary;
  final List<_TripTicket> tickets;
  final _InvoicePreview invoice;

  const _TripReservation({
    required this.packageName,
    required this.destination,
    required this.travelWindow,
    required this.durationLabel,
    required this.confirmationCode,
    required this.status,
    required this.paymentStatus,
    required this.totalAmountRwf,
    required this.amountPaidRwf,
    required this.travelers,
    required this.coverTone,
    required this.supportNote,
    required this.ticketSummary,
    required this.tickets,
    required this.invoice,
  });

  bool get isUpcoming => status.toLowerCase() != "completed";
}

class _TripTicket {
  final String label;
  final String holder;
  final String code;
  final String state;

  const _TripTicket({
    required this.label,
    required this.holder,
    required this.code,
    required this.state,
  });
}

class _InvoicePreview {
  final String invoiceNumber;
  final String issuedOn;
  final String paidOn;
  final String paymentMethod;
  final String paymentReference;
  final String status;
  final List<_InvoiceLine> lineItems;
  final int serviceFeeRwf;

  const _InvoicePreview({
    required this.invoiceNumber,
    required this.issuedOn,
    required this.paidOn,
    required this.paymentMethod,
    required this.paymentReference,
    required this.status,
    required this.lineItems,
    required this.serviceFeeRwf,
  });

  int get subtotalRwf =>
      lineItems.fold<int>(0, (sum, item) => sum + item.amountRwf);

  int get totalRwf => subtotalRwf + serviceFeeRwf;
}

class _InvoiceLine {
  final String title;
  final String subtitle;
  final int amountRwf;

  const _InvoiceLine({
    required this.title,
    required this.subtitle,
    required this.amountRwf,
  });
}

String _firstName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return "Traveler";
  return trimmed.split(RegExp(r"\s+")).first;
}
