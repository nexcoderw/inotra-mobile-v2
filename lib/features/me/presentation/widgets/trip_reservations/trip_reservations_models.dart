import "package:flutter/material.dart";

class TripReservationPreview {
  const TripReservationPreview({
    required this.packageName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.nights,
    required this.confirmationCode,
    required this.statusKey,
    required this.paymentStatusKey,
    required this.totalAmountRwf,
    required this.amountPaidRwf,
    required this.travelers,
    required this.accent,
    required this.tickets,
    required this.invoice,
  });

  final String packageName;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final int nights;
  final String confirmationCode;
  final String statusKey;
  final String paymentStatusKey;
  final int totalAmountRwf;
  final int amountPaidRwf;
  final int travelers;
  final Color accent;
  final List<TripTicketPreview> tickets;
  final TripInvoicePreview invoice;

  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return !endDate.isBefore(today);
  }

  double get paymentProgress {
    if (totalAmountRwf <= 0) return 0;
    return (amountPaidRwf / totalAmountRwf).clamp(0.0, 1.0);
  }

  int get balanceRwf {
    final value = totalAmountRwf - amountPaidRwf;
    return value > 0 ? value : 0;
  }

  int get basePackageAmountRwf =>
      totalAmountRwf - invoice.serviceFeeRwf - invoice.extrasTotalRwf;
}

class TripTicketPreview {
  const TripTicketPreview({
    required this.labelKey,
    required this.holder,
    required this.code,
    required this.stateKey,
  });

  final String labelKey;
  final String holder;
  final String code;
  final String stateKey;
}

class TripInvoicePreview {
  const TripInvoicePreview({
    required this.invoiceNumber,
    required this.issuedOn,
    required this.paidOn,
    required this.paymentMethodKey,
    required this.paymentReference,
    required this.statusKey,
    required this.serviceFeeRwf,
    required this.lineItems,
  });

  final String invoiceNumber;
  final DateTime issuedOn;
  final DateTime paidOn;
  final String paymentMethodKey;
  final String paymentReference;
  final String statusKey;
  final int serviceFeeRwf;
  final List<TripInvoiceLine> lineItems;

  int get extrasTotalRwf =>
      lineItems.fold<int>(0, (sum, item) => sum + item.amountRwf);
}

class TripInvoiceLine {
  const TripInvoiceLine({
    required this.titleKey,
    required this.subtitleKey,
    required this.amountRwf,
  });

  final String titleKey;
  final String subtitleKey;
  final int amountRwf;
}

class TripReservationMetricItem {
  const TripReservationMetricItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.detail,
    required this.accent,
  });

  final dynamic icon;
  final String label;
  final String value;
  final String detail;
  final Color accent;
}

final sampleTripReservations = [
  TripReservationPreview(
    packageName: "Volcano Ridge Escape",
    destination: "Musanze, Rwanda",
    startDate: DateTime(2026, 4, 6),
    endDate: DateTime(2026, 4, 10),
    nights: 4,
    confirmationCode: "INO-TRP-24061",
    statusKey: "trip_reservations.status_upcoming",
    paymentStatusKey: "trip_reservations.paid_full",
    totalAmountRwf: 1860000,
    amountPaidRwf: 1860000,
    travelers: 3,
    accent: const Color(0xFF0F8F5F),
    tickets: [
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_traveler_pass",
        holder: "Primary Guest",
        code: "TRV-901-24A",
        stateKey: "trip_reservations.ticket_active",
      ),
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_traveler_pass",
        holder: "Guest 02",
        code: "TRV-901-24B",
        stateKey: "trip_reservations.ticket_active",
      ),
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_permit_access",
        holder: "Guest 03",
        code: "PRM-771-09C",
        stateKey: "trip_reservations.ticket_issued",
      ),
    ],
    invoice: TripInvoicePreview(
      invoiceNumber: "INV-TRIP-24061",
      issuedOn: DateTime(2026, 3, 30),
      paidOn: DateTime(2026, 3, 30),
      paymentMethodKey: "trip_reservations.payment_method_card",
      paymentReference: "PYR-448201",
      statusKey: "trip_reservations.invoice_paid",
      serviceFeeRwf: 30000,
      lineItems: [
        TripInvoiceLine(
          titleKey: "trip_reservations.line_transfer",
          subtitleKey: "trip_reservations.line_transfer_sub",
          amountRwf: 120000,
        ),
        TripInvoiceLine(
          titleKey: "trip_reservations.line_permit",
          subtitleKey: "trip_reservations.line_permit_sub",
          amountRwf: 90000,
        ),
      ],
    ),
  ),
  TripReservationPreview(
    packageName: "Lake Kivu Signature Retreat",
    destination: "Karongi, Rwanda",
    startDate: DateTime(2026, 4, 18),
    endDate: DateTime(2026, 4, 21),
    nights: 3,
    confirmationCode: "INO-TRP-24092",
    statusKey: "trip_reservations.status_confirmed",
    paymentStatusKey: "trip_reservations.deposit_received",
    totalAmountRwf: 980000,
    amountPaidRwf: 420000,
    travelers: 2,
    accent: const Color(0xFFC07A12),
    tickets: [
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_reservation_voucher",
        holder: "Primary Guest",
        code: "RSV-518-72A",
        stateKey: "trip_reservations.ticket_pending",
      ),
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_reservation_voucher",
        holder: "Guest 02",
        code: "RSV-518-72B",
        stateKey: "trip_reservations.ticket_pending",
      ),
    ],
    invoice: TripInvoicePreview(
      invoiceNumber: "INV-TRIP-24092",
      issuedOn: DateTime(2026, 3, 31),
      paidOn: DateTime(2026, 3, 31),
      paymentMethodKey: "trip_reservations.payment_method_mobile_money",
      paymentReference: "MOMO-981504",
      statusKey: "trip_reservations.invoice_partial",
      serviceFeeRwf: 50000,
      lineItems: [
        TripInvoiceLine(
          titleKey: "trip_reservations.line_boat_cruise",
          subtitleKey: "trip_reservations.line_boat_cruise_sub",
          amountRwf: 90000,
        ),
      ],
    ),
  ),
  TripReservationPreview(
    packageName: "Akagera Premium Safari",
    destination: "Eastern Province, Rwanda",
    startDate: DateTime(2026, 3, 9),
    endDate: DateTime(2026, 3, 12),
    nights: 3,
    confirmationCode: "INO-TRP-23814",
    statusKey: "trip_reservations.status_completed",
    paymentStatusKey: "trip_reservations.closed",
    totalAmountRwf: 2240000,
    amountPaidRwf: 2240000,
    travelers: 4,
    accent: const Color(0xFF1877B8),
    tickets: [
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_safari_access_pass",
        holder: "Primary Guest",
        code: "SFR-211-11A",
        stateKey: "trip_reservations.ticket_archived",
      ),
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_safari_access_pass",
        holder: "Guest 02",
        code: "SFR-211-11B",
        stateKey: "trip_reservations.ticket_archived",
      ),
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_safari_access_pass",
        holder: "Guest 03",
        code: "SFR-211-11C",
        stateKey: "trip_reservations.ticket_archived",
      ),
      TripTicketPreview(
        labelKey: "trip_reservations.ticket_type_safari_access_pass",
        holder: "Guest 04",
        code: "SFR-211-11D",
        stateKey: "trip_reservations.ticket_archived",
      ),
    ],
    invoice: TripInvoicePreview(
      invoiceNumber: "INV-TRIP-23814",
      issuedOn: DateTime(2026, 3, 1),
      paidOn: DateTime(2026, 3, 1),
      paymentMethodKey: "trip_reservations.payment_method_bank_transfer",
      paymentReference: "BNK-772014",
      statusKey: "trip_reservations.invoice_paid",
      serviceFeeRwf: 50000,
      lineItems: [
        TripInvoiceLine(
          titleKey: "trip_reservations.line_game_drive",
          subtitleKey: "trip_reservations.line_game_drive_sub",
          amountRwf: 210000,
        ),
      ],
    ),
  ),
];
