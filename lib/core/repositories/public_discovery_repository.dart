import "dart:async";
import "dart:convert";

import "package:http/http.dart" as http;

import "../config/api.dart";
import "../constants/api/event_endpoints.dart";
import "../constants/api/package_endpoints.dart";
import "../constants/api/place_endpoints.dart";

/// Small in-memory cache for public discovery endpoints.
///
/// This cache is intentionally session-only:
/// - keeps tab switches and detail re-opens fast
/// - does not change backend contracts
/// - still allows explicit user refresh to bypass the cache
class PublicDiscoveryRepository {
  PublicDiscoveryRepository._();

  static final PublicDiscoveryRepository instance =
      PublicDiscoveryRepository._();

  static const Duration _feedTtl = Duration(seconds: 45);
  static const Duration _detailTtl = Duration(minutes: 4);
  static const Duration _previewTtl = Duration(minutes: 2);

  final Map<String, _MemoryCacheEntry> _cache = {};
  final Map<String, Future<CachedJsonResponse>> _inFlight = {};

  Future<CachedJsonResponse> fetchListingsPage({
    required int page,
    required int pageSize,
    String search = "",
    bool forceRefresh = false,
  }) {
    final uri = Api.url(
      "${PlaceEndpoints.list}?page=$page&page_size=$pageSize"
      "${search.isNotEmpty ? "&search=$search" : ""}",
    );
    return _get(uri, ttl: _feedTtl, forceRefresh: forceRefresh);
  }

  Future<CachedJsonResponse> fetchExploreListings({
    int page = 1,
    int pageSize = 4,
    bool forceRefresh = false,
  }) {
    final uri = Api.url(
      "${PlaceEndpoints.list}?page=$page&page_size=$pageSize",
    );
    return _get(uri, ttl: _previewTtl, forceRefresh: forceRefresh);
  }

  Future<CachedJsonResponse> fetchListingDetail(
    String id, {
    bool forceRefresh = false,
  }) {
    final uri = Api.url(PlaceEndpoints.detail(id));
    return _get(uri, ttl: _detailTtl, forceRefresh: forceRefresh);
  }

  Future<CachedJsonResponse> fetchEventsPage({
    required int page,
    required int pageSize,
    String search = "",
    String ordering = "start_at",
    bool forceRefresh = false,
  }) {
    final uri = Api.url(
      "${EventEndpoints.list}?page=$page&page_size=$pageSize"
      "&ordering=$ordering"
      "${search.isNotEmpty ? "&search=$search" : ""}",
    );
    return _get(uri, ttl: _feedTtl, forceRefresh: forceRefresh);
  }

  Future<CachedJsonResponse> fetchExploreEvents({
    int page = 1,
    int pageSize = 3,
    int limit = 3,
    String ordering = "start_at",
    bool forceRefresh = false,
  }) {
    final uri = Api.url(
      "${EventEndpoints.list}?page=$page&page_size=$pageSize"
      "&limit=$limit&ordering=$ordering",
    );
    return _get(uri, ttl: _previewTtl, forceRefresh: forceRefresh);
  }

  Future<CachedJsonResponse> fetchEventDetail(
    String id, {
    bool forceRefresh = false,
  }) {
    final uri = Api.url(EventEndpoints.detail(id));
    return _get(
      uri,
      ttl: _detailTtl,
      forceRefresh: forceRefresh,
      headers: const {"Accept": "application/json"},
    );
  }

  Future<CachedJsonResponse> fetchPackagesPage({
    required int page,
    required int pageSize,
    String search = "",
    bool forceRefresh = false,
  }) {
    final uri = Api.url(
      "${PackageEndpoints.list}?page=$page&page_size=$pageSize"
      "${search.isNotEmpty ? "&search=$search" : ""}",
    );
    return _get(uri, ttl: _feedTtl, forceRefresh: forceRefresh);
  }

  Future<CachedJsonResponse> fetchTripPackagesPreview({
    int limit = 3,
    bool forceRefresh = false,
  }) {
    final uri = Api.url("${PackageEndpoints.list}?limit=$limit");
    return _get(uri, ttl: _previewTtl, forceRefresh: forceRefresh);
  }

  Future<CachedJsonResponse> fetchPackageDetail(
    String id, {
    bool forceRefresh = false,
  }) {
    final uri = Api.url(PackageEndpoints.detail(id));
    return _get(
      uri,
      ttl: _detailTtl,
      forceRefresh: forceRefresh,
      headers: const {"Accept": "application/json"},
    );
  }

  Future<CachedJsonResponse> _get(
    Uri uri, {
    required Duration ttl,
    bool forceRefresh = false,
    Map<String, String>? headers,
  }) {
    final key = _cacheKey(uri, headers);
    final now = DateTime.now();

    final cached = _cache[key];
    if (!forceRefresh && cached != null && cached.expiresAt.isAfter(now)) {
      return Future.value(cached.toResponse());
    }

    if (!forceRefresh) {
      final inflight = _inFlight[key];
      if (inflight != null) return inflight;
    }

    final future = _performGet(
      key,
      uri,
      ttl: ttl,
      headers: headers,
    ).whenComplete(() => _inFlight.remove(key));

    _inFlight[key] = future;
    return future;
  }

  Future<CachedJsonResponse> _performGet(
    String key,
    Uri uri, {
    required Duration ttl,
    Map<String, String>? headers,
  }) async {
    final resp = await http.get(uri, headers: headers);
    final response = CachedJsonResponse(
      statusCode: resp.statusCode,
      body: resp.body,
    );

    if (response.isSuccess) {
      _cache[key] = _MemoryCacheEntry(
        statusCode: response.statusCode,
        body: response.body,
        expiresAt: DateTime.now().add(ttl),
      );
    }

    return response;
  }

  String _cacheKey(Uri uri, Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) return uri.toString();
    final normalizedHeaders = headers.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final headerKey = normalizedHeaders
        .map((entry) => "${entry.key}:${entry.value}")
        .join("|");
    return "${uri}::$headerKey";
  }
}

class CachedJsonResponse {
  final int statusCode;
  final String body;

  const CachedJsonResponse({required this.statusCode, required this.body});

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  dynamic decodeJson() => jsonDecode(body);
}

class _MemoryCacheEntry {
  final int statusCode;
  final String body;
  final DateTime expiresAt;

  const _MemoryCacheEntry({
    required this.statusCode,
    required this.body,
    required this.expiresAt,
  });

  CachedJsonResponse toResponse() =>
      CachedJsonResponse(statusCode: statusCode, body: body);
}
