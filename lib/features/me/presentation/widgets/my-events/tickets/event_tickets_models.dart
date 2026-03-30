import "package:flutter/material.dart";

class EventTicketPreview {
  const EventTicketPreview({
    required this.eventTitle,
    required this.venue,
    required this.city,
    required this.startAt,
    required this.endAt,
    required this.ticketCategoryKey,
    required this.ticketStateKey,
    required this.holderName,
    required this.quantity,
    required this.unitPriceRwf,
    required this.orderNumber,
    required this.ticketCode,
    required this.paymentMethodKey,
    required this.paymentReference,
    required this.purchasedAt,
    required this.sectionLabel,
    required this.entryWindow,
    required this.accent,
    this.perkKeys = const [],
  });

  final String eventTitle;
  final String venue;
  final String city;
  final DateTime startAt;
  final DateTime endAt;
  final String ticketCategoryKey;
  final String ticketStateKey;
  final String holderName;
  final int quantity;
  final int unitPriceRwf;
  final String orderNumber;
  final String ticketCode;
  final String paymentMethodKey;
  final String paymentReference;
  final DateTime purchasedAt;
  final String sectionLabel;
  final String entryWindow;
  final Color accent;
  final List<String> perkKeys;

  int get totalPaidRwf => quantity * unitPriceRwf;

  bool get isUpcoming {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final endDay = DateTime(endAt.year, endAt.month, endAt.day);
    return !endDay.isBefore(today);
  }

  String get eventStatusKey {
    final now = DateTime.now();
    if (endAt.isBefore(now)) return "events.status_ended";
    if (!startAt.isAfter(now) && !endAt.isBefore(now)) {
      return "events.status_happening";
    }

    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final startDay = DateTime(startAt.year, startAt.month, startAt.day);
    if (_isSameDay(startDay, tomorrow)) return "events.status_tomorrow";
    return "events.status_future";
  }
}

class EventTicketMetricItem {
  const EventTicketMetricItem({
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

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

final sampleEventTickets = [
  EventTicketPreview(
    eventTitle: "Kigali Jazz Nights",
    venue: "Kigali Conference Centre",
    city: "Kigali",
    startAt: DateTime(2026, 4, 2, 19, 0),
    endAt: DateTime(2026, 4, 2, 23, 30),
    ticketCategoryKey: "my_events.ticket_vip",
    ticketStateKey: "my_events.tickets.ticket_ready",
    holderName: "Primary Holder",
    quantity: 2,
    unitPriceRwf: 120000,
    orderNumber: "EVT-24018",
    ticketCode: "VIP-24018-A",
    paymentMethodKey: "my_events.tickets.payment_method_card",
    paymentReference: "CARD-804321",
    purchasedAt: DateTime(2026, 3, 29, 16, 15),
    sectionLabel: "Sky Lounge",
    entryWindow: "18:15 - 19:15",
    accent: const Color(0xFF0F8F5F),
    perkKeys: [
      "my_events.tickets.perk_priority_lane",
      "my_events.tickets.perk_welcome_drink",
      "my_events.tickets.perk_lounge_access",
    ],
  ),
  EventTicketPreview(
    eventTitle: "Rwanda Tech Expo Summit",
    venue: "BK Arena",
    city: "Kigali",
    startAt: DateTime(2026, 4, 19, 9, 0),
    endAt: DateTime(2026, 4, 19, 18, 0),
    ticketCategoryKey: "my_events.ticket_regular",
    ticketStateKey: "my_events.tickets.ticket_ready",
    holderName: "Primary Holder",
    quantity: 1,
    unitPriceRwf: 45000,
    orderNumber: "EVT-24107",
    ticketCode: "REG-24107-C",
    paymentMethodKey: "my_events.tickets.payment_method_mobile_money",
    paymentReference: "MOMO-981502",
    purchasedAt: DateTime(2026, 3, 28, 12, 42),
    sectionLabel: "Hall C",
    entryWindow: "08:00 - 09:30",
    accent: const Color(0xFF1877B8),
    perkKeys: [
      "my_events.tickets.perk_networking_access",
      "my_events.tickets.perk_parking_access",
    ],
  ),
  EventTicketPreview(
    eventTitle: "Lake Kivu Sunset Sessions",
    venue: "Kivu Marina Bay",
    city: "Karongi",
    startAt: DateTime(2026, 3, 16, 17, 30),
    endAt: DateTime(2026, 3, 16, 22, 0),
    ticketCategoryKey: "my_events.ticket_table",
    ticketStateKey: "my_events.tickets.ticket_used",
    holderName: "Primary Holder",
    quantity: 4,
    unitPriceRwf: 80000,
    orderNumber: "EVT-23892",
    ticketCode: "TBL-23892-B",
    paymentMethodKey: "my_events.tickets.payment_method_bank_transfer",
    paymentReference: "BNK-410224",
    purchasedAt: DateTime(2026, 3, 4, 10, 8),
    sectionLabel: "Lakeside Deck",
    entryWindow: "16:45 - 18:00",
    accent: const Color(0xFFC07A12),
    perkKeys: [
      "my_events.tickets.perk_table_service",
      "my_events.tickets.perk_host_fast_track",
    ],
  ),
];
