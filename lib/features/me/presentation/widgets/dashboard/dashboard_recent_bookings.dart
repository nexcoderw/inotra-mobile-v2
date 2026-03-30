import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../../core/constants/app_colors.dart";
import "../../../../../i18n/lang.dart";
import "../../../../../i18n/translations.dart";
import "dashboard_shared.dart";

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class BookingItem {
  final String id;
  final String listingName;
  final String? guestName;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final double? totalPrice;
  final String? currency;

  const BookingItem({
    required this.id,
    required this.listingName,
    this.guestName,
    this.checkIn,
    this.checkOut,
    this.status = "pending",
    this.totalPrice,
    this.currency,
  });

  factory BookingItem.fromJson(Map<String, dynamic> json) {
    // Flexible parsing — handles various field naming conventions.
    final listing = json["listing"] ?? json["place"] ?? {};
    String name = "";
    if (listing is Map) {
      name =
          (listing["title"] ?? listing["name"] ?? listing["place_name"] ?? "")
              .toString();
    }
    if (name.isEmpty) {
      name =
          (json["listing_title"] ?? json["place_name"] ?? json["title"] ?? "")
              .toString();
    }

    final user = json["user"] ?? json["guest"] ?? {};
    String guest = "";
    if (user is Map) {
      guest =
          (user["display_name"] ??
                  user["full_name"] ??
                  user["name"] ??
                  user["email"] ??
                  "")
              .toString();
    }
    if (guest.isEmpty) {
      guest = (json["guest_name"] ?? json["user_name"] ?? "").toString();
    }

    final price = json["total_price"] ?? json["price"] ?? json["amount"];
    double? parsedPrice;
    if (price != null) {
      parsedPrice = double.tryParse(price.toString());
    }

    return BookingItem(
      id: (json["id"] ?? "").toString(),
      listingName: name,
      guestName: guest.isEmpty ? null : guest,
      checkIn: (json["check_in"] ?? json["check_in_date"] ?? "").toString(),
      checkOut: (json["check_out"] ?? json["check_out_date"] ?? "").toString(),
      status: (json["status"] ?? "pending").toString().toLowerCase(),
      totalPrice: parsedPrice,
      currency: (json["currency"] ?? "RWF").toString(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────

class DashboardRecentBookings extends StatelessWidget {
  final List<BookingItem> bookings;
  final bool isLoading;
  final VoidCallback? onViewAll;

  const DashboardRecentBookings({
    super.key,
    required this.bookings,
    this.isLoading = false,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();

    return DashboardSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DashboardSectionHeader(
            icon: HugeIcons.strokeRoundedCalendar03,
            iconColor: const Color(0xFF0EA5E9),
            title: t(lang, "dashboard.recent_bookings"),
            subtitle: isLoading
                ? t(lang, "dashboard.loading")
                : "${bookings.length} ${t(lang, "dashboard.shown")}",
            onViewAll: onViewAll,
          ),
          const SizedBox(height: 16),
          if (isLoading)
            ..._buildSkeletons(context)
          else if (bookings.isEmpty)
            _buildEmpty(context)
          else
            ...bookings.map((b) => _BookingRow(booking: b)),
        ],
      ),
    );
  }

  List<Widget> _buildSkeletons(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    return List.generate(
      3,
      (_) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: s.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 12,
                    decoration: BoxDecoration(
                      color: s.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 120,
                    height: 10,
                    decoration: BoxDecoration(
                      color: s.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    final s = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedCalendarRemove02,
              color: s.onSurface.withValues(alpha: 0.25),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              t(lang, "dashboard.no_bookings"),
              style: TextStyle(
                fontSize: 13,
                color: s.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single booking row
// ─────────────────────────────────────────────────────────────────────────────

class _BookingRow extends StatelessWidget {
  final BookingItem booking;
  const _BookingRow({required this.booking});

  static const _statusColors = {
    "confirmed": Color(0xFF22C55E),
    "pending": Color(0xFFF59E0B),
    "cancelled": Color(0xFFEF4444),
    "completed": Color(0xFF0EA5E9),
  };

  Color _statusColor() =>
      _statusColors[booking.status] ?? const Color(0xFF9CA3AF);

  String _statusLabel(String lang) {
    final s = booking.status;
    switch (s) {
      case "confirmed":
        return t(lang, "dashboard.status_confirmed");
      case "pending":
        return t(lang, "dashboard.status_pending");
      case "cancelled":
        return t(lang, "dashboard.status_cancelled");
      case "completed":
        return t(lang, "dashboard.status_completed");
      default:
        return s.isEmpty
            ? t(lang, "dashboard.status_pending")
            : "${s[0].toUpperCase()}${s.substring(1)}";
    }
  }

  String _initials() {
    final name = booking.listingName;
    final parts = name.split(" ").where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return "${parts[0][0]}${parts[1][0]}".toUpperCase();
    if (parts.isNotEmpty) return parts[0][0].toUpperCase();
    return "?";
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    final statusColor = _statusColor();
    final listingTitle = booking.listingName.isEmpty
        ? t(lang, "dashboard.listing_fallback")
        : booking.listingName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Initials avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                _initials(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title + meta
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listingTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                if ((booking.guestName ?? "").isNotEmpty ||
                    (booking.checkIn ?? "").isNotEmpty)
                  Text(
                    [
                      if ((booking.guestName ?? "").isNotEmpty)
                        booking.guestName!,
                      if ((booking.checkIn ?? "").isNotEmpty)
                        _formatDate(booking.checkIn!),
                    ].join(" · "),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right side: price + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (booking.totalPrice != null)
                Text(
                  "${booking.currency ?? 'RWF'} ${_formatPrice(booking.totalPrice!)}",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _statusLabel(lang),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String iso) {
    try {
      final d = DateTime.parse(iso);
      const m = [
        "Jan",
        "Feb",
        "Mar",
        "Apr",
        "May",
        "Jun",
        "Jul",
        "Aug",
        "Sep",
        "Oct",
        "Nov",
        "Dec",
      ];
      return "${m[d.month - 1]} ${d.day}";
    } catch (_) {
      return iso.length > 10 ? iso.substring(0, 10) : iso;
    }
  }

  String _formatPrice(double p) {
    if (p >= 1000000) return "${(p / 1000000).toStringAsFixed(1)}M";
    if (p >= 1000) return "${(p / 1000).toStringAsFixed(0)}K";
    return p.toStringAsFixed(0);
  }
}
