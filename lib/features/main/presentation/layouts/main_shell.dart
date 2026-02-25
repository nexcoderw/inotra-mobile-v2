import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../widgets/inotra_bottom_nav.dart";
import "../widgets/inotra_app_header.dart";
import "../widgets/inotra_sidebar_drawer.dart";
import "../widgets/ai_chat_auth_dialog.dart";

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

  String get _title => switch (_index) {
        0 => "Explore",
        1 => "Listings",
        2 => "AI Chat",
        3 => "Events",
        _ => "Highlights",
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label — coming soon"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _onTabChange(int next) async {
    if (next == _index) return;

    if (next == 2 && await _maybeShowAiChatDialog()) {
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

  Future<bool> _maybeShowAiChatDialog() async {
    _ensureAuthSession();
    final isAuthed = _authSession?.value.isAuthenticated ?? false;
    if (isAuthed) return false;

    if (!mounted) return true;
    await AiChatAuthDialog.show(context);
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
        onDashboardTap: () => _comingSoon("Dashboard"),

        // EVENTS dropdown
        onMyEventsTap: () => _comingSoon("My Events"),
        onMyEventSubmissionsTap: () => _comingSoon("My Event Submissions"),
        onEventReviewTap: () => _comingSoon("Event Review"),
        onEventTicketsTap: () => _comingSoon("Event Tickets"),

        // LISTINGS dropdown
        onMyListingsTap: () => _comingSoon("My Listings"),
        onMyListingSubmissionsTap: () => _comingSoon("My Listing Submissions"),
        onListingReviewsTap: () => _comingSoon("Listing Reviews"),
        onListingBookingTap: () => _comingSoon("Listing Booking"),

        onTripReservationsTap: () => _comingSoon("Trip Reservations"),

        onSettingsTap: () => _comingSoon("Settings"),
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
