import "dart:convert";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:http/http.dart" as http;

import "../../../../core/config/api.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";
import "../widgets/trip_packages/package_overview_tab.dart";
import "../widgets/trip_packages/package_activities_tab.dart";
import "../widgets/trip_packages/package_gallery_tab.dart";

class TripPackageDetailsPage extends StatefulWidget {
  final String? packageId;
  const TripPackageDetailsPage({super.key, this.packageId});

  @override
  State<TripPackageDetailsPage> createState() => _TripPackageDetailsPageState();
}

class _TripPackageDetailsPageState extends State<TripPackageDetailsPage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  String? _error;
  PackageDetailData? _pkg;
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetch());
  }

  Future<void> _fetch() async {
    final id = widget.packageId ?? ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null || id.isEmpty) {
      setState(() {
        _loading = false;
        _error = t(currentLangSync(), "common.coming_soon");
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final uri = Api.url(PackageEndpoints.detail(id));
      final resp = await http.get(uri, headers: {"Accept": "application/json"});
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body) as Map<String, dynamic>;
        _pkg = PackageDetailData.fromJson(decoded);
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

    return MainScaffold(
      title: t(lang, "trips.details_title"),
      showAppBar: false,
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null || _pkg == null)
                ? _ErrorCard(message: _error ?? t(lang, "common.coming_soon"), onRetry: _fetch)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: PageHeader(title: _pkg!.title, onBack: () => Navigator.maybePop(context)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _HeroCard(pkg: _pkg!),
                      ),
                      const SizedBox(height: 10),
                      TabBar(
                        controller: _tabs,
                        labelColor: scheme.primary,
                        unselectedLabelColor: scheme.onSurface.withOpacity(0.6),
                        indicatorColor: scheme.primary,
                        tabs: [
                          Tab(text: t(lang, "trips.overview")),
                          Tab(text: t(lang, "trips.activities_title")),
                          Tab(text: t(lang, "trips.gallery_title")),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabs,
                          children: [
                            PackageOverviewTab(pkg: _pkg!),
                            PackageActivitiesTab(activities: _pkg!.activities),
                            PackageGalleryTab(images: _pkg!.allImages),
                          ],
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final PackageDetailData pkg;
  const _HeroCard({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: pkg.allImages.isNotEmpty
                ? Image.network(
                    pkg.allImages.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: scheme.surfaceVariant),
                  )
                : Container(color: scheme.surfaceVariant),
          ),
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.35),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCalendar02,
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "${pkg.durationDays} ${t(currentLangSync(), "packages.days")}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
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

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedWifiError01, color: scheme.error, size: 26),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          TextButton(onPressed: onRetry, child: Text(t(currentLangSync(), "common.try_again"))),
        ],
      ),
    );
  }
}

/* ----------------------------- MODELS ----------------------------- */

class PackageDetailData {
  final String id;
  final String title;
  final String description;
  final int durationDays;
  final List<String> allImages;
  final List<PackageActivity> activities;

  PackageDetailData({
    required this.id,
    required this.title,
    required this.description,
    required this.durationDays,
    required this.allImages,
    required this.activities,
  });

  factory PackageDetailData.fromJson(Map<String, dynamic> json) {
    final images = (json["images"] as List?)
            ?.whereType<Map>()
            .map((m) => (m["image_url"] ?? "").toString())
            .where((u) => u.isNotEmpty)
            .toList() ??
        [];
    final activities = (json["activities"] as List?)
            ?.whereType<Map>()
            .map((m) => PackageActivity.fromJson(m))
            .toList() ??
        [];
    final cover = (json["cover_url"] ?? "").toString();
    if (cover.isNotEmpty) images.insert(0, cover);

    return PackageDetailData(
      id: (json["id"] ?? "").toString(),
      title: (json["title"] ?? "").toString(),
      description: (json["description"] ?? "").toString(),
      durationDays: (json["duration_days"] as num?)?.toInt() ?? 0,
      allImages: images,
      activities: activities,
    );
  }
}

class PackageActivity {
  final String id;
  final String name;
  final int day;

  PackageActivity({required this.id, required this.name, required this.day});

  factory PackageActivity.fromJson(Map<String, dynamic> json) {
    return PackageActivity(
      id: (json["id"] ?? "").toString(),
      name: (json["activity_name"] ?? json["name"] ?? "").toString(),
      day: (json["time"] as num?)?.toInt() ?? 0,
    );
  }
}
