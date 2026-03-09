class PackageImageItem {
  final String url;
  final String caption;
  final bool isFeatured;

  const PackageImageItem({
    required this.url,
    required this.caption,
    required this.isFeatured,
  });
}

class PackageActivity {
  final String id;
  final String title;
  final int day;

  const PackageActivity({
    required this.id,
    required this.title,
    required this.day,
  });

  factory PackageActivity.fromJson(Map<String, dynamic> j) {
    return PackageActivity(
      id: (j["id"] ?? "").toString(),
      title: (j["activity_name"] ?? j["title"] ?? j["name"] ?? "").toString(),
      day: (j["day"] as num?)?.toInt() ??
          (j["day_number"] as num?)?.toInt() ??
          (j["time"] as num?)?.toInt() ??
          1,
    );
  }
}

class PackageDetailData {
  final String id;
  final String title;
  final String description;
  final String location;
  final String? coverUrl;
  final int? durationDays;
  final bool isActive;
  final List<PackageActivity> activities;
  final List<PackageImageItem> images;

  const PackageDetailData({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.coverUrl,
    required this.durationDays,
    required this.isActive,
    required this.activities,
    required this.images,
  });

  List<String> get allImages {
    final List<String> urls = [];
    if (coverUrl != null && coverUrl!.trim().isNotEmpty) {
      urls.add(coverUrl!.trim());
    }
    for (final img in images) {
      if (img.url.isNotEmpty && !urls.contains(img.url)) {
        urls.add(img.url);
      }
    }
    return urls;
  }

  List<PackageImageItem> get allImageItems {
    final List<PackageImageItem> items = [];
    if (coverUrl != null && coverUrl!.trim().isNotEmpty) {
      items.add(PackageImageItem(
        url: coverUrl!.trim(),
        caption: title,
        isFeatured: true,
      ));
    }
    for (final img in images) {
      if (img.url.isNotEmpty) items.add(img);
    }
    return items;
  }

  factory PackageDetailData.fromJson(Map<String, dynamic> j) {
    final rawImages = (j["images"] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((m) => PackageImageItem(
                  url: (m["image_url"] ?? "").toString(),
                  caption: (m["caption"] ?? "").toString(),
                  isFeatured: m["is_featured"] == true,
                ))
            .toList() ??
        [];

    final rawActivities = (j["activities"] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(PackageActivity.fromJson)
            .toList() ??
        [];

    return PackageDetailData(
      id: (j["id"] ?? "").toString(),
      title: (j["title"] ?? j["name"] ?? "").toString(),
      description: (j["description"] ?? "").toString(),
      location: (j["location"] ?? j["city"] ?? "").toString(),
      coverUrl: (j["cover_url"] ?? j["image_url"] ?? "").toString(),
      durationDays: (j["duration_days"] as num?)?.toInt(),
      isActive: j["is_active"] == true,
      activities: rawActivities,
      images: rawImages,
    );
  }
}
