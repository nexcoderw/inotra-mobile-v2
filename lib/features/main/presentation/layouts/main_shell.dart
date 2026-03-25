import "package:flutter/material.dart";

import "package:provider/provider.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/notification_service.dart";
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
  late final List<Widget Function()> _tabBuilders;
  late final List<Widget?> _tabCache;

  @override
  void initState() {
    super.initState();
    _ensureAuthSession();
    _tabBuilders = [
      () => const ExploreTab(),
      () => const ListingsTab(),
      () => const AiChatTab(),
      () => const EventsTab(),
      () => const HighlightsTab(),
    ];
    _tabCache = List<Widget?>.filled(_tabBuilders.length, null, growable: false);
    _index = widget.initialIndex.clamp(0, _tabBuilders.length - 1);
    _ensureTabLoaded(_index);
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

  void _goToNotifications() {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  void _goToProfile() {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  void _ensureTabLoaded(int index) {
    if (_tabCache[index] != null) return;
    _tabCache[index] = _tabBuilders[index]();
  }

  void _onTabChange(int next) async {
    if (next == _index) return;

    if (next == 2 && await _maybeShowAuthDialog(featureLabel: "AI Chat")) {
      return;
    }

    _ensureTabLoaded(next);
    setState(() => _index = next);
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
        unreadCount: context.watch<NotificationService>().unreadCount,
      ),

      drawer: InotraSidebarDrawer(
        onDashboardTap: () => Navigator.pushNamed(context, AppRoutes.dashboard),

        // EVENTS dropdown
        onMyEventsTap: () => Navigator.pushNamed(context, AppRoutes.myEvents),
        onMyEventSubmissionsTap: () =>
            Navigator.pushNamed(context, AppRoutes.myEventSubmissions),
        onEventPaymentsTap: () =>
            Navigator.pushNamed(context, AppRoutes.eventPayments),
        onEventTicketsTap: () =>
            Navigator.pushNamed(context, AppRoutes.eventTickets),

        // LISTINGS dropdown
        onMyListingsTap: () =>
            Navigator.pushNamed(context, AppRoutes.myListings),
        onMyListingSubmissionsTap: () =>
            Navigator.pushNamed(context, AppRoutes.myListingSubmissions),
        onListingReviewsTap: () =>
            Navigator.pushNamed(context, AppRoutes.listingReviews),
        onListingPaymentsTap: () =>
            Navigator.pushNamed(context, AppRoutes.listingPayments),
        onListingBookingTap: () =>
            Navigator.pushNamed(context, AppRoutes.listingBooking),

        onTripReservationsTap: () =>
            Navigator.pushNamed(context, AppRoutes.tripReservations),

        onSettingsTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),

      body: IndexedStack(
        index: _index,
        children: List<Widget>.generate(
          _tabCache.length,
          (index) => _tabCache[index] ?? const SizedBox.shrink(),
          growable: false,
        ),
      ),

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
