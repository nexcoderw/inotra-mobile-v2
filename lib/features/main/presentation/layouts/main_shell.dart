import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/inotra_bottom_nav.dart";
import "../widgets/inotra_app_header.dart";
import "../widgets/inotra_sidebar_drawer.dart";
import "../widgets/auth_dialog.dart";

import "../tabs/explore_tab.dart";
import "../tabs/listings_tab.dart";
import "../tabs/ai_chat_tab.dart";
import "../tabs/events_tab.dart";
import "../tabs/highlights_tab.dart";

class MainShell extends StatefulWidget {
  final int initialIndex;
  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  late int _index;
  AuthSession? _authSession;

  final _tabs = const [
    ExploreTab(),
    ListingsTab(),
    AiChatTab(),
    EventsTab(),
    HighlightsTab(),
  ];

  @override
  void initState() {
    super.initState();
    _ensureAuthSession();
    _index = widget.initialIndex.clamp(0, _tabs.length - 1);
  }

  String get _lang => currentLangSync();

  String get _title => switch (_index) {
        0 => t(_lang, "nav.explore"),
        1 => t(_lang, "nav.listings"),
        2 => t(_lang, "nav.ai_chat"),
        3 => t(_lang, "nav.events"),
        _ => t(_lang, "nav.highlights"),
      };

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  void _closeDrawer() {
    // Only pop if drawer is open (safe to call anyway)
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _goToNotifications() {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  void _goToProfile() {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  void _comingSoon(String label) {
    _closeDrawer();
    final lang = _lang;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label — ${t(lang, "common.coming_soon")}"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _onTabChange(int next) async {
    if (next == _index) return;

    if (next == 2 && await _maybeShowAuthDialog(featureLabel: "AI Chat")) {
      return;
    }

    setState(() => _index = next);

    final route = switch (next) {
      0 => AppRoutes.home,
      1 => AppRoutes.listings,
      2 => AppRoutes.aiChat,
      3 => AppRoutes.events,
      _ => AppRoutes.highlights,
    };

    Navigator.pushReplacementNamed(context, route);
  }

  void _handleAuthChange() {
    if (mounted) setState(() {});
  }

  void _ensureAuthSession() {
    if (_authSession != null) return;
    _authSession = AuthSession.instance;
    _authSession!.addListener(_handleAuthChange);
  }

  Future<bool> _maybeShowAuthDialog({required String featureLabel}) async {
    _ensureAuthSession();
    final isAuthed = _authSession?.value.isAuthenticated ?? false;
    if (isAuthed) return false;

    if (!mounted) return true;
    await AuthDialog.show(
      context,
      featureLabel: featureLabel,
      description: null,
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    _ensureAuthSession();
    final session = _authSession!.value;

    return Scaffold(
      key: _scaffoldKey,

      appBar: InotraAppHeader(
        title: _title,
        onMenuTap: _openDrawer,
        onNotificationsTap: _goToNotifications,
        onProfileTap: _goToProfile,
        displayName: session.displayName,
        isAuthenticated: session.isAuthenticated,
      ),

      drawer: InotraSidebarDrawer(
        onDashboardTap: () => _comingSoon(t(_lang, "nav.dashboard")),

        // EVENTS dropdown
        onMyEventsTap: () => _comingSoon(t(_lang, "nav.my_events")),
        onMyEventSubmissionsTap: () => _comingSoon(t(_lang, "nav.my_event_submissions")),
        onEventReviewTap: () => _comingSoon(t(_lang, "nav.event_review")),
        onEventTicketsTap: () => _comingSoon(t(_lang, "nav.event_tickets")),

        // LISTINGS dropdown
        onMyListingsTap: () => _comingSoon(t(_lang, "nav.my_listings")),
        onMyListingSubmissionsTap: () => _comingSoon(t(_lang, "nav.my_listing_submissions")),
        onListingReviewsTap: () => _comingSoon(t(_lang, "nav.listing_reviews")),
        onListingBookingTap: () => _comingSoon(t(_lang, "nav.listing_booking")),

        onTripReservationsTap: () => _comingSoon(t(_lang, "nav.trip_reservations")),

        onSettingsTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),

      body: IndexedStack(index: _index, children: _tabs),

      bottomNavigationBar: InotraBottomNav(
        currentIndex: _index,
        onChanged: _onTabChange,
      ),
    );
  }

  @override
  void dispose() {
    _authSession?.removeListener(_handleAuthChange);
    super.dispose();
  }
}
