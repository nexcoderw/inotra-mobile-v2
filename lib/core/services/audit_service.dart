import "dart:convert";

import "package:http/http.dart" as http;

import "../config/api.dart";
import "../constants/api/audit_endpoints.dart";
import "auth_session.dart";
import "device_info_service.dart";

// ── Internal entity context ───────────────────────────────────────────────────

class _EntityContext {
  final String entityType;
  final String entityId;
  final String entityLabel;

  const _EntityContext({
    required this.entityType,
    required this.entityId,
    required this.entityLabel,
  });
}

// ── AuditService ──────────────────────────────────────────────────────────────

/// Singleton service that submits user-activity audit events to the backend.
///
/// Usage — entity-detail pages call [enrichEntityContext] after their data
/// loads so the final log entry (fired when the route exits) includes the
/// human-readable entity name:
///
/// ```dart
/// // Inside _ListingDetailsPageState after _place is set:
/// AuditService.instance.enrichEntityContext(
///   routeName: AppRoutes.listingDetails,
///   entityType: "PLACE",
///   entityId: _place.id,
///   entityLabel: _place.name,
/// );
/// ```
///
/// All network calls are fire-and-forget — failures are silently swallowed
/// so that audit instrumentation can never disrupt the user experience.
class AuditService {
  AuditService._();

  static final AuditService instance = AuditService._();

  /// Pending entity context keyed by route name.
  /// Set by entity-detail pages after data loads; consumed on route exit.
  final Map<String, _EntityContext> _pendingEntities = {};

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Store entity context for a route so it can be included in the exit log.
  ///
  /// Call this inside the page state after the entity data loads:
  /// ```dart
  /// AuditService.instance.enrichEntityContext(
  ///   routeName: AppRoutes.listingDetails,
  ///   entityType: "PLACE",
  ///   entityId: _place.id,
  ///   entityLabel: _place.name,
  /// );
  /// ```
  void enrichEntityContext({
    required String routeName,
    required String entityType,
    required String entityId,
    required String entityLabel,
  }) {
    _pendingEntities[routeName] = _EntityContext(
      entityType: entityType,
      entityId: entityId,
      entityLabel: entityLabel,
    );
  }

  /// Log a page view event.  Called by [AuditRouteObserver] when a route
  /// exits so the log entry always includes the real time-on-page value.
  ///
  /// If [enrichEntityContext] was called for this route (entity-detail pages),
  /// the entity info is merged into the single log entry automatically.
  Future<void> logPageView({
    required String pageName,
    required String routeName,
    int? durationSeconds,
  }) async {
    final entity = _pendingEntities.remove(routeName);

    await _send(
      action: "VIEW",
      entityType: entity?.entityType ?? "",
      entityId: entity?.entityId ?? "",
      entityLabel: entity?.entityLabel ?? "",
      description: (entity != null && entity.entityLabel.isNotEmpty)
          ? "Viewed ${entity.entityLabel}"
          : "Visited $pageName",
      metadata: {
        "page": pageName,
        if (durationSeconds != null && durationSeconds > 0)
          "duration_seconds": durationSeconds,
      },
    );
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  Future<void> _send({
    required String action,
    String entityType = "",
    String entityId = "",
    String entityLabel = "",
    String description = "",
    Map<String, dynamic> metadata = const {},
  }) async {
    final token = AuthSession.instance.value.accessToken;
    if (token == null || token.isEmpty) return;

    try {
      final body = <String, dynamic>{"action": action};
      if (entityType.isNotEmpty) body["entity_type"]  = entityType;
      if (entityId.isNotEmpty)   body["entity_id"]    = entityId;
      if (entityLabel.isNotEmpty) body["entity_label"] = entityLabel;
      if (description.isNotEmpty) body["description"]  = description;
      if (metadata.isNotEmpty)   body["metadata"]     = metadata;

      await http
          .post(
            Api.url(AuditEndpoints.track),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
              ...DeviceInfoService.instance.asHeader,
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
    } catch (_) {
      // Silently ignore — a missed audit event is acceptable.
    }
  }
}
