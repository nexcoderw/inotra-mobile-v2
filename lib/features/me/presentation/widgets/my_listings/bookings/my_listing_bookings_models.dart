import "package:flutter/material.dart";

class MyListingBookingPreview {
  const MyListingBookingPreview({
    required this.id,
    required this.listingName,
    required this.locationLabel,
    required this.stayLabel,
    required this.statusKey,
    required this.checkIn,
    required this.checkOut,
    required this.bookedOn,
    required this.guestCount,
    required this.totalPaidRwf,
    required this.nightlyRateRwf,
    required this.bookingCode,
    required this.paymentMethodKey,
    required this.paymentReference,
    required this.accent,
  });

  static const empty = MyListingBookingPreview(
    id: "",
    listingName: "",
    locationLabel: "",
    stayLabel: "",
    statusKey: "my_listings.bookings.status_pending",
    checkIn: null,
    checkOut: null,
    bookedOn: null,
    guestCount: 0,
    totalPaidRwf: 0,
    nightlyRateRwf: 0,
    bookingCode: "",
    paymentMethodKey: "my_listings.bookings.payment_method_card",
    paymentReference: "",
    accent: Color(0xFF0F8F5F),
  );

  final String id;
  final String listingName;
  final String locationLabel;
  final String stayLabel;
  final String statusKey;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final DateTime? bookedOn;
  final int guestCount;
  final int totalPaidRwf;
  final int nightlyRateRwf;
  final String bookingCode;
  final String paymentMethodKey;
  final String paymentReference;
  final Color accent;

  bool get isUpcoming {
    final date = checkOut ?? checkIn;
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bookingDay = DateTime(date.year, date.month, date.day);
    return !bookingDay.isBefore(today);
  }

  int get nights {
    if (checkIn == null || checkOut == null) return 1;
    final diff = checkOut!.difference(checkIn!).inDays;
    return diff <= 0 ? 1 : diff;
  }

  String get propertyKey => "$listingName|$locationLabel";

  factory MyListingBookingPreview.fromJson(Map<String, dynamic> json) {
    final listing = _asMap(json["listing"] ?? json["place"]);
    final listingName = _firstString([
      listing["title"],
      listing["name"],
      listing["place_name"],
      json["listing_title"],
      json["place_name"],
      json["title"],
    ]);

    final locationLabel = _joinNonEmpty([
      _firstString([listing["city"], json["city"]]),
      _firstString([listing["country"], json["country"]]),
    ], separator: ", ");

    final stayLabel = _firstString([
      listing["category"],
      listing["type"],
      json["room_type"],
      json["unit_type"],
      json["booking_type"],
    ]);

    final checkIn = _parseDate(json["check_in"] ?? json["check_in_date"]);
    final checkOut = _parseDate(json["check_out"] ?? json["check_out_date"]);
    final bookedOn = _parseDate(
      json["created_at"] ?? json["booked_at"] ?? json["created"],
    );

    final guestCount = _parseInt(
      json["guest_count"] ??
          json["guests"] ??
          json["number_of_guests"] ??
          json["travellers"] ??
          1,
    );

    final totalPaid = _parseNum(
      json["total_price"] ?? json["price"] ?? json["amount"],
    );

    final nights = checkIn != null && checkOut != null
        ? _safeNights(checkIn, checkOut)
        : 1;

    final nightlyRate = _parseNum(
      json["nightly_rate"] ??
          json["price_per_night"] ??
          json["night_rate"] ??
          (totalPaid != null ? totalPaid / nights : null),
    );

    final rawStatus = _firstString([json["status"]]).toLowerCase();
    final statusKey = _statusKey(rawStatus);

    return MyListingBookingPreview(
      id: _firstString([json["id"]]),
      listingName: listingName.isEmpty ? "Listing" : listingName,
      locationLabel: locationLabel.isEmpty
          ? _firstString([
              listing["address"],
              json["address"],
              json["location"],
            ])
          : locationLabel,
      stayLabel: stayLabel,
      statusKey: statusKey,
      checkIn: checkIn,
      checkOut: checkOut,
      bookedOn: bookedOn,
      guestCount: guestCount <= 0 ? 1 : guestCount,
      totalPaidRwf: (totalPaid ?? 0).round(),
      nightlyRateRwf: (nightlyRate ?? totalPaid ?? 0).round(),
      bookingCode: _firstString([
        json["booking_code"],
        json["booking_reference"],
        json["confirmation_code"],
        json["reference"],
        json["id"],
      ]),
      paymentMethodKey: _paymentMethodKey(
        _firstString([
          json["payment_method"],
          json["payment_type"],
          json["payment_channel"],
        ]),
      ),
      paymentReference: _firstString([
        json["payment_reference"],
        json["transaction_reference"],
        json["reference_code"],
        json["transaction_id"],
        json["id"],
      ]),
      accent: _accentForStatus(statusKey),
    );
  }
}

class MyListingBookingMetricItem {
  const MyListingBookingMetricItem({
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

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  return const <String, dynamic>{};
}

String _firstString(List<dynamic> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? "";
    if (text.isNotEmpty && text.toLowerCase() != "null") {
      return text;
    }
  }
  return "";
}

String _joinNonEmpty(List<String> parts, {String separator = " · "}) {
  final filtered = parts.where((part) => part.trim().isNotEmpty).toList();
  return filtered.join(separator);
}

DateTime? _parseDate(dynamic value) {
  final text = value?.toString().trim() ?? "";
  if (text.isEmpty) return null;
  return DateTime.tryParse(text);
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? "") ?? 0;
}

num? _parseNum(dynamic value) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? "");
}

int _safeNights(DateTime checkIn, DateTime checkOut) {
  final diff = checkOut.difference(checkIn).inDays;
  return diff <= 0 ? 1 : diff;
}

String _statusKey(String raw) {
  if (raw.contains("cancel")) return "my_listings.bookings.status_cancelled";
  if (raw.contains("complete") || raw.contains("finished")) {
    return "my_listings.bookings.status_completed";
  }
  if (raw.contains("checked") ||
      raw.contains("active") ||
      raw.contains("in_progress") ||
      raw.contains("ongoing")) {
    return "my_listings.bookings.status_checked_in";
  }
  if (raw.contains("confirm")) return "my_listings.bookings.status_confirmed";
  return "my_listings.bookings.status_pending";
}

String _paymentMethodKey(String raw) {
  final value = raw.replaceAll("_", " ").toLowerCase();
  if (value.contains("momo") || value.contains("mobile")) {
    return "my_listings.bookings.payment_method_mobile_money";
  }
  if (value.contains("bank") ||
      value.contains("transfer") ||
      value.contains("wire")) {
    return "my_listings.bookings.payment_method_bank_transfer";
  }
  if (value.contains("cash")) return "my_listings.bookings.payment_method_cash";
  return "my_listings.bookings.payment_method_card";
}

Color _accentForStatus(String key) {
  switch (key) {
    case "my_listings.bookings.status_confirmed":
      return const Color(0xFF0F8F5F);
    case "my_listings.bookings.status_checked_in":
      return const Color(0xFF1877B8);
    case "my_listings.bookings.status_completed":
      return const Color(0xFF5E6B7A);
    case "my_listings.bookings.status_cancelled":
      return const Color(0xFFD64545);
    default:
      return const Color(0xFFC07A12);
  }
}
