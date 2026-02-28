import "dart:convert";

import "package:flutter/material.dart";
import "package:http/http.dart" as http;
import "../../../../core/config/api.dart";
import "../../../../core/constants/api/package_endpoints.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

/// Horizontal carousel preview of top trip packages (3 items).
class TripPackagesPreview extends StatefulWidget {
  const TripPackagesPreview({super.key});

  @override
  State<TripPackagesPreview> createState() => _TripPackagesPreviewState();
}

class _TripPackagesPreviewState extends State<TripPackagesPreview> {
  bool _loading = true;
  String? _error;
  List<_Package> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final uri = Api.url("${PackageEndpoints.list}?limit=3");
      final resp = await http.get(uri);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        final decoded = jsonDecode(resp.body);
        final results = (decoded is Map ? decoded["results"] : decoded) as List? ?? [];
        _items = results.whereType<Map<String, dynamic>>().map(_Package.fromJson).toList();
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t(lang, "packages.title"),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, AppRoutes.tripPackages),
                child: Text(
                  t(lang, "packages.see_all"),
                  style: TextStyle(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 180,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _error!,
                            style: TextStyle(
                              color: scheme.error,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton(onPressed: _load, child: Text(t(lang, "common.try_again"))),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final p = _items[i];
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.tripPackageDetails,
                            arguments: p.id,
                          ),
                          child: Container(
                            width: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: scheme.surface,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: p.imageUrl == null
                                      ? Container(color: scheme.surfaceVariant)
                                      : Image.network(
                                          p.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Container(color: scheme.surfaceVariant),
                                        ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.title ?? t(lang, "packages.title"),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        p.subtitle ?? "",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: scheme.onSurface.withOpacity(0.7),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${p.durationDays} ${t(lang, "packages.days")}"
                                        " • ${p.activities} ${t(lang, "packages.activities")}",
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: scheme.onSurface.withOpacity(0.68),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

class _Package {
  final String id;
  final String? title;
  final String? subtitle;
  final String? imageUrl;
  final int durationDays;
  final int activities;

  _Package({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    required this.durationDays,
    required this.activities,
  });

  static _Package fromJson(Map<String, dynamic> json) {
    return _Package(
      id: json["id"]?.toString() ?? "",
      title: json["title"] as String? ?? json["name"] as String?,
      subtitle: json["location"] as String? ?? json["description"] as String?,
      imageUrl: (json["cover_url"] ?? json["image"] ?? json["cover_image"]) as String?,
      durationDays: (json["duration_days"] as num?)?.toInt() ?? 0,
      activities: (json["activities_count"] as num?)?.toInt() ?? 0,
    );
  }
}
