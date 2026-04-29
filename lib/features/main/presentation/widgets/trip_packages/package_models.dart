class PackageImageItem {
  final String url;
  final String caption;
  final bool isFeatured;
  final String role;
  final String? altText;

  const PackageImageItem({
    required this.url,
    required this.caption,
    required this.isFeatured,
    required this.role,
    this.altText,
  });

  factory PackageImageItem.fromJson(Map<String, dynamic> j) {
    final rawUrl = (j["image_url"] ?? j["url"] ?? j["image"] ?? "")
        .toString()
        .trim();
    return PackageImageItem(
      url: rawUrl,
      caption: (j["caption"] ?? "").toString(),
      isFeatured:
          j["is_featured"] == true ||
          j["role"]?.toString().toLowerCase() == "hero",
      role: (j["role"] ?? "gallery").toString(),
      altText: (j["alt_text"] ?? j["alt"] ?? "").toString().trim().isEmpty
          ? null
          : (j["alt_text"] ?? j["alt"]).toString().trim(),
    );
  }
}

class PackageActivity {
  final String id;
  final String title;
  final int day;
  final int sortOrder;
  final String description;
  final String activityType;
  final int? estimatedDurationMinutes;
  final String difficultyLevel;
  final bool isOptional;
  final bool isIncluded;
  final String whatToExpect;
  final String notes;
  final List<PackageImageItem> media;

  const PackageActivity({
    required this.id,
    required this.title,
    required this.day,
    required this.sortOrder,
    required this.description,
    required this.activityType,
    required this.estimatedDurationMinutes,
    required this.difficultyLevel,
    required this.isOptional,
    required this.isIncluded,
    required this.whatToExpect,
    required this.notes,
    required this.media,
  });

  factory PackageActivity.fromJson(Map<String, dynamic> j) {
    final rawMedia =
        (j["media"] as List?)
            ?.whereType<Map>()
            .map((m) => PackageImageItem.fromJson(Map<String, dynamic>.from(m)))
            .where((item) => item.url.isNotEmpty)
            .toList() ??
        const <PackageImageItem>[];

    return PackageActivity(
      id: (j["id"] ?? "").toString(),
      title: (j["activity_name"] ?? j["title"] ?? j["name"] ?? "").toString(),
      day:
          (j["day"] as num?)?.toInt() ??
          (j["day_number"] as num?)?.toInt() ??
          (j["time"] as num?)?.toInt() ??
          1,
      sortOrder: (j["sort_order"] as num?)?.toInt() ?? 0,
      description: (j["description"] ?? "").toString(),
      activityType: (j["activity_type"] ?? "").toString(),
      estimatedDurationMinutes: (j["estimated_duration_minutes"] as num?)
          ?.toInt(),
      difficultyLevel: (j["difficulty_level"] ?? "").toString(),
      isOptional: j["is_optional"] == true,
      isIncluded: j["is_included"] != false,
      whatToExpect: (j["what_to_expect"] ?? "").toString(),
      notes: (j["notes"] ?? "").toString(),
      media: rawMedia,
    );
  }
}

class PackageStop {
  final String id;
  final int sortOrder;
  final String title;
  final String placeName;
  final String stopType;
  final String description;
  final String arrivalTime;
  final String departureTime;
  final String transportMode;
  final String distanceLabel;
  final String durationLabel;
  final List<PackageImageItem> media;
  final List<PackageActivity> activities;

  const PackageStop({
    required this.id,
    required this.sortOrder,
    required this.title,
    required this.placeName,
    required this.stopType,
    required this.description,
    required this.arrivalTime,
    required this.departureTime,
    required this.transportMode,
    required this.distanceLabel,
    required this.durationLabel,
    required this.media,
    required this.activities,
  });

  factory PackageStop.fromJson(Map<String, dynamic> j) {
    final rawMedia =
        (j["media"] as List?)
            ?.whereType<Map>()
            .map((m) => PackageImageItem.fromJson(Map<String, dynamic>.from(m)))
            .where((item) => item.url.isNotEmpty)
            .toList() ??
        const <PackageImageItem>[];

    final rawActivities =
        (j["activities"] as List?)
            ?.whereType<Map>()
            .map((m) => PackageActivity.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        <PackageActivity>[];

    rawActivities.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return PackageStop(
      id: (j["id"] ?? "").toString(),
      sortOrder: (j["sort_order"] as num?)?.toInt() ?? 0,
      title: (j["title"] ?? "").toString(),
      placeName: (j["place_name"] ?? "").toString(),
      stopType: (j["stop_type"] ?? "").toString(),
      description: (j["description"] ?? "").toString(),
      arrivalTime: (j["arrival_time"] ?? "").toString(),
      departureTime: (j["departure_time"] ?? "").toString(),
      transportMode: (j["transport_mode"] ?? "").toString(),
      distanceLabel: (j["distance_label"] ?? "").toString(),
      durationLabel: (j["duration_label"] ?? "").toString(),
      media: rawMedia,
      activities: rawActivities,
    );
  }
}

class PackageDay {
  final String id;
  final int dayNumber;
  final String title;
  final String summary;
  final String overnightLocation;
  final String mealsIncluded;
  final String notes;
  final List<PackageImageItem> media;
  final List<PackageStop> stops;

  const PackageDay({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.summary,
    required this.overnightLocation,
    required this.mealsIncluded,
    required this.notes,
    required this.media,
    required this.stops,
  });

  factory PackageDay.fromJson(Map<String, dynamic> j) {
    final rawMedia =
        (j["media"] as List?)
            ?.whereType<Map>()
            .map((m) => PackageImageItem.fromJson(Map<String, dynamic>.from(m)))
            .where((item) => item.url.isNotEmpty)
            .toList() ??
        const <PackageImageItem>[];

    final rawStops =
        (j["stops"] as List?)
            ?.whereType<Map>()
            .map((m) => PackageStop.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        <PackageStop>[];

    rawStops.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return PackageDay(
      id: (j["id"] ?? "").toString(),
      dayNumber:
          (j["day_number"] as num?)?.toInt() ??
          (j["order"] as num?)?.toInt() ??
          1,
      title: (j["title"] ?? "").toString(),
      summary: (j["summary"] ?? "").toString(),
      overnightLocation: (j["overnight_location"] ?? "").toString(),
      mealsIncluded: (j["meals_included"] ?? "").toString(),
      notes: (j["notes"] ?? "").toString(),
      media: rawMedia,
      stops: rawStops,
    );
  }
}

class PackageDetailData {
  final String id;
  final String title;
  final String description;
  final String summary;
  final String overview;
  final String location;
  final String routeSummary;
  final String originLabel;
  final String destinationLabel;
  final String travelerFit;
  final String transportSummary;
  final String bestSeason;
  final String includedItems;
  final String excludedItems;
  final String cancellationPolicy;
  final String whatToBring;
  final String importantNotes;
  final String tripStyle;
  final String difficultyLevel;
  final String physicalIntensity;
  final String pricingMode;
  final String? coverUrl;
  final String? coverAltText;
  final int? durationDays;
  final int? durationNights;
  final int activitiesCount;
  final int daysCount;
  final int stopsCount;
  final String? priceAmount;
  final String? priceCurrency;
  final bool isActive;
  final List<PackageActivity> activities;
  final List<PackageImageItem> images;
  final List<PackageImageItem> gallery;
  final List<PackageDay> days;

  const PackageDetailData({
    required this.id,
    required this.title,
    required this.description,
    required this.summary,
    required this.overview,
    required this.location,
    required this.routeSummary,
    required this.originLabel,
    required this.destinationLabel,
    required this.travelerFit,
    required this.transportSummary,
    required this.bestSeason,
    required this.includedItems,
    required this.excludedItems,
    required this.cancellationPolicy,
    required this.whatToBring,
    required this.importantNotes,
    required this.tripStyle,
    required this.difficultyLevel,
    required this.physicalIntensity,
    required this.pricingMode,
    required this.coverUrl,
    required this.coverAltText,
    required this.durationDays,
    required this.durationNights,
    required this.activitiesCount,
    required this.daysCount,
    required this.stopsCount,
    required this.priceAmount,
    required this.priceCurrency,
    required this.isActive,
    required this.activities,
    required this.images,
    required this.gallery,
    required this.days,
  });

  String get displayDescription {
    final candidates = [overview.trim(), summary.trim(), description.trim()];
    return candidates.firstWhere((value) => value.isNotEmpty, orElse: () => "");
  }

  String get routeLabel {
    final route = routeSummary.trim();
    if (route.isNotEmpty) return route;

    final origin = originLabel.trim();
    final destination = destinationLabel.trim();
    if (origin.isNotEmpty && destination.isNotEmpty) {
      return "$origin -> $destination";
    }

    return location.trim();
  }

  int get resolvedDaysCount {
    if (daysCount > 0) return daysCount;
    if (days.isNotEmpty) return days.length;
    return durationDays ?? 0;
  }

  int get resolvedActivitiesCount {
    if (activitiesCount > 0) return activitiesCount;
    if (activities.isNotEmpty) return activities.length;
    return days.fold<int>(
      0,
      (sum, day) =>
          sum +
          day.stops.fold<int>(
            0,
            (stopSum, stop) => stopSum + stop.activities.length,
          ),
    );
  }

  List<PackageActivity> get flattenedActivities {
    if (activities.isNotEmpty) {
      final sorted = [...activities]
        ..sort((a, b) {
          final byDay = a.day.compareTo(b.day);
          if (byDay != 0) return byDay;
          return a.sortOrder.compareTo(b.sortOrder);
        });
      return sorted;
    }

    final generated = <PackageActivity>[];
    for (final day in days) {
      for (final stop in day.stops) {
        for (final activity in stop.activities) {
          generated.add(
            PackageActivity(
              id: activity.id,
              title: activity.title,
              day: day.dayNumber,
              sortOrder: activity.sortOrder,
              description: activity.description,
              activityType: activity.activityType,
              estimatedDurationMinutes: activity.estimatedDurationMinutes,
              difficultyLevel: activity.difficultyLevel,
              isOptional: activity.isOptional,
              isIncluded: activity.isIncluded,
              whatToExpect: activity.whatToExpect,
              notes: activity.notes,
              media: activity.media,
            ),
          );
        }
      }
    }
    generated.sort((a, b) {
      final byDay = a.day.compareTo(b.day);
      if (byDay != 0) return byDay;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return generated;
  }

  List<String> get allImages {
    final seen = <String>{};
    final urls = <String>[];

    void addUrl(String? value) {
      final url = (value ?? "").trim();
      if (url.isEmpty || seen.contains(url)) return;
      seen.add(url);
      urls.add(url);
    }

    addUrl(coverUrl);

    for (final img in allImageItems) {
      addUrl(img.url);
    }

    return urls;
  }

  List<PackageImageItem> get allImageItems {
    final items = <PackageImageItem>[];
    final seen = <String>{};

    void addItem(PackageImageItem item) {
      if (item.url.isEmpty || seen.contains(item.url)) return;
      seen.add(item.url);
      items.add(item);
    }

    if ((coverUrl ?? "").trim().isNotEmpty) {
      addItem(
        PackageImageItem(
          url: coverUrl!.trim(),
          caption: title,
          isFeatured: true,
          role: "hero",
          altText: coverAltText,
        ),
      );
    }

    for (final img in gallery) {
      addItem(img);
    }
    for (final img in images) {
      addItem(img);
    }
    for (final day in days) {
      for (final img in day.media) {
        addItem(img);
      }
      for (final stop in day.stops) {
        for (final img in stop.media) {
          addItem(img);
        }
        for (final activity in stop.activities) {
          for (final img in activity.media) {
            addItem(img);
          }
        }
      }
    }

    return items;
  }

  factory PackageDetailData.fromJson(Map<String, dynamic> j) {
    List<PackageImageItem> parseImages(String key) {
      return (j[key] as List?)
              ?.whereType<Map>()
              .map(
                (m) => PackageImageItem.fromJson(Map<String, dynamic>.from(m)),
              )
              .where((item) => item.url.isNotEmpty)
              .toList() ??
          const <PackageImageItem>[];
    }

    final rawActivities =
        (j["activities"] as List?)
            ?.whereType<Map>()
            .map((m) => PackageActivity.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        <PackageActivity>[];

    final rawDays =
        (j["days"] as List?)
            ?.whereType<Map>()
            .map((m) => PackageDay.fromJson(Map<String, dynamic>.from(m)))
            .toList() ??
        <PackageDay>[];

    rawDays.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    final description = (j["description"] ?? "").toString();
    final summary = (j["summary"] ?? "").toString();
    final overview = (j["overview"] ?? "").toString();

    return PackageDetailData(
      id: (j["id"] ?? "").toString(),
      title: (j["title"] ?? j["name"] ?? "").toString(),
      description: description,
      summary: summary,
      overview: overview,
      location: (j["location"] ?? j["city"] ?? "").toString(),
      routeSummary: (j["route_summary"] ?? "").toString(),
      originLabel: (j["origin_label"] ?? "").toString(),
      destinationLabel: (j["destination_label"] ?? "").toString(),
      travelerFit: (j["traveler_fit"] ?? "").toString(),
      transportSummary: (j["transport_summary"] ?? "").toString(),
      bestSeason: (j["best_season"] ?? "").toString(),
      includedItems: (j["included_items"] ?? "").toString(),
      excludedItems: (j["excluded_items"] ?? "").toString(),
      cancellationPolicy: (j["cancellation_policy"] ?? "").toString(),
      whatToBring: (j["what_to_bring"] ?? "").toString(),
      importantNotes: (j["important_notes"] ?? "").toString(),
      tripStyle: (j["trip_style"] ?? "").toString(),
      difficultyLevel: (j["difficulty_level"] ?? "").toString(),
      physicalIntensity: (j["physical_intensity"] ?? "").toString(),
      pricingMode: (j["pricing_mode"] ?? "").toString(),
      coverUrl: (j["cover_url"] ?? j["image_url"] ?? "").toString().trim(),
      coverAltText: (j["cover_alt_text"] ?? "").toString().trim().isEmpty
          ? null
          : (j["cover_alt_text"] ?? "").toString().trim(),
      durationDays: (j["duration_days"] as num?)?.toInt(),
      durationNights: (j["duration_nights"] as num?)?.toInt(),
      activitiesCount:
          (j["activities_count"] as num?)?.toInt() ?? rawActivities.length,
      daysCount: (j["days_count"] as num?)?.toInt() ?? rawDays.length,
      stopsCount: (j["stops_count"] as num?)?.toInt() ?? 0,
      priceAmount: (j["price_amount"] ?? "").toString().trim().isEmpty
          ? null
          : (j["price_amount"] ?? "").toString().trim(),
      priceCurrency: (j["price_currency"] ?? "").toString().trim().isEmpty
          ? null
          : (j["price_currency"] ?? "").toString().trim(),
      isActive: j["is_active"] == true,
      activities: rawActivities,
      images: parseImages("images"),
      gallery: parseImages("gallery"),
      days: rawDays,
    );
  }
}
