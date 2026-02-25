import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/inotra_bottom_nav.dart";
import "../widgets/inotra_app_header.dart";
import "../widgets/inotra_sidebar_drawer.dart";

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


  void _onTabChange(int next) {
    if (next == _index) return;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,

      appBar: InotraAppHeader(
        title: _title,
        onMenuTap: _openDrawer,
        onNotificationsTap: _goToNotifications,
        onProfileTap: _goToProfile,
        displayName: "Guest",
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

        onProfileTap: () {
          _closeDrawer();
          _goToProfile();
        },
      ),

      body: IndexedStack(index: _index, children: _tabs),

      bottomNavigationBar: InotraBottomNav(
        currentIndex: _index,
        onChanged: _onTabChange,
      ),
    );
  }
}