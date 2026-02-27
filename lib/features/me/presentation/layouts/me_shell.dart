import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../../../main/presentation/widgets/inotra_app_header.dart";
import "../../../main/presentation/widgets/inotra_bottom_nav.dart";
import "../../../main/presentation/widgets/inotra_sidebar_drawer.dart";

/// Shell layout for all pages under the `me/` area.
/// Provides a shared app header and sidebar drawer navigation.
class MeShell extends StatefulWidget {
  final String title;
  final Widget child;
  final int currentIndex;

  const MeShell({
    super.key,
    required this.title,
    required this.child,
    this.currentIndex = 0,
  });

  @override
  State<MeShell> createState() => _MeShellState();
}

class _MeShellState extends State<MeShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  String get _lang => currentLangSync();
  AuthSession get _session => AuthSession.instance;

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();
  void _closeDrawerIfOpen() {
    if (Navigator.canPop(context)) Navigator.pop(context);
  }

  void _goTo(String route) {
    _closeDrawerIfOpen();
    Navigator.pushNamed(context, route);
  }

  void _goToNotifications() => _goTo(AppRoutes.notifications);
  void _goToProfile() => _goTo(AppRoutes.profile);

  void _onTabChange(int next) {
    if (next == widget.currentIndex) return;
    final route = switch (next) {
      0 => AppRoutes.home,
      1 => AppRoutes.listings,
      2 => AppRoutes.aiChat,
      3 => AppRoutes.events,
      _ => AppRoutes.highlights,
    };
    _goTo(route);
  }

  @override
  Widget build(BuildContext context) {
    final session = _session.value;

    return Scaffold(
      key: _scaffoldKey,
      appBar: InotraAppHeader(
        title: widget.title,
        onMenuTap: _openDrawer,
        onNotificationsTap: _goToNotifications,
        onProfileTap: _goToProfile,
        displayName: session.displayName,
        isAuthenticated: session.isAuthenticated,
      ),
      drawer: InotraSidebarDrawer(
        onDashboardTap: () => _goTo(AppRoutes.dashboard),
        onMyEventsTap: () => _goTo(AppRoutes.myEvents),
        onMyEventSubmissionsTap: () => _goTo(AppRoutes.myEventSubmissions),
        onEventReviewTap: () => _goTo(AppRoutes.eventReview),
        onEventTicketsTap: () => _goTo(AppRoutes.eventTickets),
        onMyListingsTap: () => _goTo(AppRoutes.myListings),
        onMyListingSubmissionsTap: () => _goTo(AppRoutes.myListingSubmissions),
        onListingReviewsTap: () => _goTo(AppRoutes.listingReviews),
        onListingBookingTap: () => _goTo(AppRoutes.listingBooking),
        onTripReservationsTap: () => _goTo(AppRoutes.tripReservations),
        onSettingsTap: () => _goTo(AppRoutes.settings),
        onProfileTap: _goToProfile,
        onLogoutTap: null,
      ),
      body: widget.child,
      bottomNavigationBar: InotraBottomNav(
        currentIndex: widget.currentIndex,
        onChanged: _onTabChange,
      ),
    );
  }
}
