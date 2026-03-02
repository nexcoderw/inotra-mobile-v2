import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

/// Public model for listing details.
class PlaceDetails {
  final String id;
  final String name;
  final String description;
  final String categoryName;
  final String address;
  final String city;
  final String country;
  final double? latitude;
  final double? longitude;
  final String phone;
  final String whatsapp;
  final String email;
  final String website;
  final double? rating;
  final int? reviewsCount;
  final List<String> images;
  final List<String> services;
  final Map<String, OpeningHours> hours;

  const PlaceDetails({
    required this.id,
    required this.name,
    required this.description,
    required this.categoryName,
    required this.address,
    required this.city,
    required this.country,
    required this.latitude,
    required this.longitude,
    required this.phone,
    required this.whatsapp,
    required this.email,
    required this.website,
    required this.rating,
    required this.reviewsCount,
    required this.images,
    required this.services,
    required this.hours,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    Map<String, OpeningHours> hours = {};
    final rawHours = json["opening_hours"];
    if (rawHours is Map) {
      hours = rawHours.map((key, value) {
        if (value is Map) {
          return MapEntry(
            key.toString().toLowerCase(),
            OpeningHours.fromJson(Map<String, dynamic>.from(value)),
          );
        }
        return MapEntry(key.toString().toLowerCase(), OpeningHours.empty());
      });
    }

    final images = (json["images"] as List?)
            ?.whereType<Map>()
            .map((m) => (m["image_url"] ?? m["url"] ?? "").toString())
            .where((u) => u.isNotEmpty)
            .toList() ??
        [];

    final services = (json["services"] as List?)
            ?.whereType<Map>()
            .map((m) => (m["name"] ?? "").toString())
            .where((s) => s.isNotEmpty)
            .toList() ??
        [];

    double? toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    int? toInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return PlaceDetails(
      id: (json["id"] ?? "").toString(),
      name: (json["name"] ?? "").toString(),
      description: (json["description"] ?? "").toString().trim(),
      categoryName: (json["category_name"] ?? "").toString(),
      address: (json["address"] ?? "").toString(),
      city: (json["city"] ?? "").toString(),
      country: (json["country"] ?? "").toString(),
      latitude: toDouble(json["latitude"]),
      longitude: toDouble(json["longitude"]),
      phone: (json["phone"] ?? "").toString(),
      whatsapp: (json["whatsapp"] ?? "").toString(),
      email: (json["email"] ?? "").toString(),
      website: (json["website"] ?? "").toString(),
      rating: toDouble(json["avg_rating"]),
      reviewsCount: toInt(json["reviews_count"]),
      images: images,
      services: services,
      hours: hours,
    );
  }
}

class OpeningHours {
  final String open;
  final String close;
  const OpeningHours({required this.open, required this.close});

  factory OpeningHours.fromJson(Map<String, dynamic> json) {
    return OpeningHours(
      open: (json["open"] ?? "").toString(),
      close: (json["close"] ?? "").toString(),
    );
  }

  factory OpeningHours.empty() => const OpeningHours(open: "", close: "");
}

class ListingRatingChip extends StatelessWidget {
  final double rating;
  final int reviews;
  const ListingRatingChip({super.key, required this.rating, required this.reviews});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.primary.withOpacity(0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedStar,
            size: 16,
            color: scheme.primary,
            strokeWidth: 2.2,
          ),
          const SizedBox(width: 6),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            "(${reviews.toString()})",
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class ListingPill extends StatelessWidget {
  final dynamic icon;
  final String label;
  const ListingPill({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: icon,
            size: 14,
            color: scheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ListingInfoRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  const ListingInfoRow({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HugeIcon(
          icon: icon,
          size: 16,
          color: scheme.onSurface.withOpacity(0.7),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }
}

class ListingHoursTable extends StatelessWidget {
  final Map<String, OpeningHours> hours;
  const ListingHoursTable({super.key, required this.hours});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const order = [
      "monday",
      "tuesday",
      "wednesday",
      "thursday",
      "friday",
      "saturday",
      "sunday",
    ];
    return Column(
      children: order.map((day) {
        final val = hours[day];
        final label = day[0].toUpperCase() + day.substring(1);
        final text = val == null
            ? "—"
            : (val.open.isNotEmpty && val.close.isNotEmpty
                ? "${val.open} - ${val.close}"
                : "—");
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 90,
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface.withOpacity(0.75),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: scheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
