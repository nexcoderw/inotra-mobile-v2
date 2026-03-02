import "dart:convert";
import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/place_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/page_header.dart";

class ListingDetailsPage extends StatefulWidget {
  final String? placeId;
  const ListingDetailsPage({super.key, this.placeId});

  @override
  State<ListingDetailsPage> createState() => _ListingDetailsPageState();
}

class _ListingDetailsPageState extends State<ListingDetailsPage> {
  _Place? _place;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final id =
        widget.placeId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = "Missing listing id";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(PlaceEndpoints.detail(id));
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        if (decoded is Map) {
          _place = _Place.fromJson(Map<String, dynamic>.from(decoded));
        } else {
          _error = "Invalid response";
        }
      } else {
        _error = "Status ${resp.statusCode}";
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        body: SafeArea(
          child: _loading
              ? const _PageSkeleton()
              : _error != null
                  ? _ErrorState(
                      message: _error!,
                      onRetry: _fetch,
                    )
                  : _place == null
                      ? _ErrorState(
                          message: t(lang, "listings.no_data"),
                          onRetry: _fetch,
                        )
                      : Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                              child: PageHeader(
                                title: _place!.name,
                                onBack: () => Navigator.maybePop(context),
                                icon: HugeIcons.strokeRoundedArrowLeft01,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: _HeroCarousel(images: _place!.images),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _place!.name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _RatingChip(
                                        rating: _place!.rating ?? 0,
                                        reviews: _place!.reviewsCount ?? 0,
                                      ),
                                      const SizedBox(width: 10),
                                      if (_place!.categoryName.isNotEmpty)
                                        _Pill(
                                          icon: HugeIcons.strokeRoundedHotel,
                                          label: _place!.categoryName,
                                        ),
                                      const Spacer(),
                                      _Pill(
                                        icon: HugeIcons.strokeRoundedMapsLocation02,
                                        label: _place!.city.isNotEmpty
                                            ? "${_place!.city}, ${_place!.country}"
                                            : _place!.country,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            TabBar(
                              labelColor: scheme.primary,
                              unselectedLabelColor: scheme.onSurface.withOpacity(0.6),
                              indicatorColor: scheme.primary,
                              isScrollable: true,
                              tabs: [
                                Tab(text: t(lang, "listings.tab_overview")),
                                Tab(text: t(lang, "listings.tab_map")),
                                Tab(text: t(lang, "listings.tab_reviews")),
                                Tab(text: t(lang, "listings.tab_transport")),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _OverviewTab(place: _place!),
                                  _MapTab(place: _place!),
                                  _ReviewsTab(),
                                  _TransportTab(place: _place!),
                                ],
                              ),
                            ),
                          ],
                        ),
        ),
      ),
    );
  }
}

/* ----------------------------- OVERVIEW ----------------------------- */

class _OverviewTab extends StatelessWidget {
  final _Place place;
  const _OverviewTab({required this.place});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (place.description.isNotEmpty) ...[
            Text(
              t(lang, "listings.overview_title"),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              place.description,
              style: TextStyle(
                height: 1.5,
                color: scheme.onSurface.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (place.services.isNotEmpty) ...[
            Text(
              t(lang, "listings.services"),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: place.services
                  .map((s) => _Pill(
                        icon: HugeIcons.strokeRoundedCheckVerified01,
                        label: s,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            t(lang, "listings.hours"),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _HoursTable(hours: place.hours),
        ],
      ),
    );
  }
}

/* ----------------------------- MAP ----------------------------- */

class _MapTab extends StatelessWidget {
  final _Place place;
  const _MapTab({required this.place});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "listings.address"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _InfoRow(
            icon: HugeIcons.strokeRoundedMapsLocation02,
            label: place.address.isNotEmpty ? place.address : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: HugeIcons.strokeRoundedLocation01,
            label: "${place.latitude?.toStringAsFixed(6) ?? '--'}, "
                "${place.longitude?.toStringAsFixed(6) ?? '--'}",
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.6),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedMapLocation01,
                    size: 34,
                    color: scheme.onSurface.withOpacity(0.55),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    t(lang, "listings.map_placeholder"),
                    style: TextStyle(
                      color: scheme.onSurface.withOpacity(0.6),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- REVIEWS ----------------------------- */

class _ReviewsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(
            icon: HugeIcons.strokeRoundedChatSearch01,
            size: 36,
            color: scheme.onSurface.withOpacity(0.35),
          ),
          const SizedBox(height: 10),
          Text(
            t(lang, "listings.reviews_empty"),
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.65),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- TRANSPORT ----------------------------- */

class _TransportTab extends StatelessWidget {
  final _Place place;
  const _TransportTab({required this.place});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t(lang, "listings.transport_title"),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: HugeIcons.strokeRoundedCall01,
            label: place.phone.isNotEmpty ? place.phone : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: HugeIcons.strokeRoundedChat02,
            label: place.whatsapp.isNotEmpty ? place.whatsapp : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: HugeIcons.strokeRoundedMail02,
            label: place.email.isNotEmpty ? place.email : t(lang, "listings.no_data"),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: HugeIcons.strokeRoundedGlobe02,
            label: place.website.isNotEmpty ? place.website : t(lang, "listings.no_data"),
          ),
        ],
      ),
    );
  }
}

/* ----------------------------- WIDGETS ----------------------------- */

class _HeroCarousel extends StatefulWidget {
  final List<String> images;
  const _HeroCarousel({required this.images});

  @override
  State<_HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<_HeroCarousel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(20);
    final imgs = widget.images.isNotEmpty ? widget.images : [null];

    return Column(
      children: [
        ClipRRect(
          borderRadius: radius,
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              color: scheme.surfaceVariant.withOpacity(0.6),
            ),
            child: PageView.builder(
              itemCount: imgs.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) {
                final url = imgs[i];
                if (url == null || url.trim().isEmpty) {
                  return _PlaceholderImage(scheme: scheme);
                }
                return Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _PlaceholderImage(scheme: scheme),
                  loadingBuilder: (_, child, evt) =>
                      evt == null ? child : _PlaceholderImage(scheme: scheme),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            imgs.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _index == i ? 18 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              decoration: BoxDecoration(
                color: _index == i
                    ? scheme.primary
                    : scheme.onSurface.withOpacity(0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  final ColorScheme scheme;
  const _PlaceholderImage({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceVariant.withOpacity(0.7),
      child: Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedImageNotFound01,
          color: scheme.onSurface.withOpacity(0.35),
          size: 32,
        ),
      ),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  final int reviews;
  const _RatingChip({required this.rating, required this.reviews});

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

class _Pill extends StatelessWidget {
  final dynamic icon;
  final String label;
  const _Pill({required this.icon, required this.label});

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

class _InfoRow extends StatelessWidget {
  final dynamic icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

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

class _HoursTable extends StatelessWidget {
  final Map<String, OpeningHours> hours;
  const _HoursTable({required this.hours});

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

/* ----------------------------- STATES ----------------------------- */

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedWifiError01,
              size: 34,
              color: scheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.error,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              child: Text(t(lang, "common.try_again")),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageSkeleton extends StatelessWidget {
  const _PageSkeleton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                height: 24,
                width: 220,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 210,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                height: 16,
                width: 260,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 16,
                width: 180,
                decoration: BoxDecoration(
                  color: scheme.surfaceVariant.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: scheme.surfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------------- MODEL ----------------------------- */

class _Place {
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

  _Place({
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

  factory _Place.fromJson(Map<String, dynamic> json) {
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

    return _Place(
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
