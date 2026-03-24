import "package:flutter/material.dart";

import "../config/app_routes.dart";
import "../services/audit_service.dart";

/// Navigator observer that automatically tracks page views and time-on-page
/// for every named route in the app.
///
/// **How it works:**
/// - On [didPush] / [didReplace]: records the entry timestamp for the route.
/// - On [didPop] / [didReplace] (old route): computes time-on-page and fires
///   a single VIEW audit log entry via [AuditService.logPageView].
/// - Entity-detail pages (listing, event, package) call
///   [AuditService.enrichEntityContext] after their data loads so the final
///   log entry includes the entity name and type.
///
/// Register once in [MaterialApp.navigatorObservers]:
/// ```dart
/// navigatorObservers: [AuditRouteObserver.instance],
/// ```
class AuditRouteObserver extends RouteObserver<ModalRoute<void>> {
  AuditRouteObserver._();

  static final AuditRouteObserver instance = AuditRouteObserver._();

  /// Human-readable label for each named route.
  static const Map<String, String> _labels = {
    // ── Main tabs ─────────────────────────────────────────────────────────
    AppRoutes.home: "Explore",
    AppRoutes.listings: "Listings",
    AppRoutes.aiChat: "AI Chat",
    AppRoutes.events: "Events",
    AppRoutes.highlights: "Highlights",

    // ── Discover & details ────────────────────────────────────────────────
    AppRoutes.tripPackages: "Trip Packages",
    AppRoutes.tripPackageDetails: "Trip Package Details",
    AppRoutes.listingDetails: "Listing Details",
    AppRoutes.eventDetails: "Event Details",

    // ── AI Chat ───────────────────────────────────────────────────────────
    AppRoutes.aiChatConversations: "AI Chat Conversations",

    // ── Me area ───────────────────────────────────────────────────────────
    AppRoutes.dashboard: "Dashboard",
    AppRoutes.myEvents: "My Events",
    AppRoutes.myEventSubmissions: "My Event Submissions",
    AppRoutes.eventPayments: "Event Payments",
    AppRoutes.eventTickets: "Event Tickets",
    AppRoutes.myListings: "My Listings",
    AppRoutes.myListingSubmissions: "My Listing Submissions",
    AppRoutes.listingReviews: "Listing Reviews",
    AppRoutes.listingPayments: "Listing Payments",
    AppRoutes.listingBooking: "Listing Booking",
    AppRoutes.tripReservations: "Trip Reservations",

    // ── Profile ───────────────────────────────────────────────────────────
    AppRoutes.profile: "Profile",
    AppRoutes.profileAccount: "Profile Account Details",
    AppRoutes.profilePassword: "Change Password",
    AppRoutes.profileDanger: "Account Danger Zone",

    // ── Notifications ─────────────────────────────────────────────────────
    AppRoutes.notifications: "Notifications",

    // ── Settings ──────────────────────────────────────────────────────────
    AppRoutes.settings: "Settings",
    AppRoutes.settingsTheme: "Theme Settings",
    AppRoutes.settingsLanguage: "Language Settings",

    // ── Static pages ──────────────────────────────────────────────────────
    AppRoutes.privacyPolicy: "Privacy Policy",
    AppRoutes.termsConditions: "Terms & Conditions",
    AppRoutes.contactSupport: "Contact Support",
  };

  /// Entry timestamps keyed by route name.
  final Map<String, DateTime> _enterTimes = {};

  // ── RouteObserver overrides ────────────────────────────────────────────────

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _recordEntry(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null) _flush(oldRoute);
    if (newRoute != null) _recordEntry(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? nextRoute) {
    super.didPop(route, nextRoute);
    _flush(route);
  }

  // ── Internal ──────────────────────────────────────────────────────────────

  void _recordEntry(Route<dynamic> route) {
    final name = route.settings.name;
    if (name != null && _labels.containsKey(name)) {
      _enterTimes[name] = DateTime.now();
    }
  }

  void _flush(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null) return;
    final enter = _enterTimes.remove(name);
    final label = _labels[name];
    if (enter == null || label == null) return;

    final secs = DateTime.now().difference(enter).inSeconds;
    AuditService.instance.logPageView(
      pageName: label,
      routeName: name,
      durationSeconds: secs > 0 ? secs : null,
    );
  }
}
