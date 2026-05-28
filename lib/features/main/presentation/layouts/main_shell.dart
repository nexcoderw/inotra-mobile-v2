import "package:flutter/material.dart";

import "package:provider/provider.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/services/notification_service.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../../../auth/presentation/widgets/quick_login_dialog.dart";
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
  late final PageController _pageController;
  int _chatUnreadCount = 0;
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
      () => AiChatTab(onUnreadMessage: _onChatUnread),
      () => const EventsTab(),
      () => const HighlightsTab(),
    ];
    _tabCache = List<Widget?>.filled(
      _tabBuilders.length,
      null,
      growable: false,
    );
    _index = widget.initialIndex.clamp(0, _tabBuilders.length - 1);
    _pageController = PageController(initialPage: _index);
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

  void _onChatUnread() {
    if (_index != 2 && mounted) setState(() => _chatUnreadCount++);
  }

  void _commitTabChange(int next) {
    if (next == _index) return;
    _ensureTabLoaded(next);
    setState(() {
      _index = next;
      if (next == 2) _chatUnreadCount = 0;
    });
  }

  void _animateToTab(int next) {
    if (!_pageController.hasClients) return;
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  void _onTabChange(int next) async {
    if (next == _index) return;

    if (next == 2 && await _maybeShowLoginDialog()) {
      return;
    }

    _commitTabChange(next);
    _animateToTab(next);
  }

  void _handlePageChanged(int next) {
    if (next == _index) return;

    if (next == 2) {
      () async {
        if (await _maybeShowLoginDialog()) {
          if (mounted) _animateToTab(_index);
          return;
        }
        if (mounted) _commitTabChange(next);
      }();
      return;
    }

    _commitTabChange(next);
  }

  void _handleAuthChange() {
    if (mounted) setState(() {});
  }

  void _ensureAuthSession() {
    if (_authSession != null) return;
    _authSession = AuthSession.instance;
    _authSession!.addListener(_handleAuthChange);
  }

  Future<bool> _maybeShowLoginDialog() async {
    _ensureAuthSession();
    final isAuthed = _authSession?.value.isAuthenticated ?? false;
    if (isAuthed) return false;

    if (!mounted) return true;
    await QuickLoginDialog.show(context);
    return !AuthSession.instance.value.isAuthenticated;
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
        onEventTicketsTap: () =>
            Navigator.pushNamed(context, AppRoutes.eventTickets),

        // LISTINGS dropdown
        onMyListingsTap: () =>
            Navigator.pushNamed(context, AppRoutes.myListings),
        onMyListingSubmissionsTap: () =>
            Navigator.pushNamed(context, AppRoutes.myListingSubmissions),
        onListingReviewsTap: () =>
            Navigator.pushNamed(context, AppRoutes.listingReviews),
        onListingBookingTap: () =>
            Navigator.pushNamed(context, AppRoutes.listingBooking),

        onTripReservationsTap: () =>
            Navigator.pushNamed(context, AppRoutes.tripReservations),

        onSettingsTap: () => Navigator.pushNamed(context, AppRoutes.settings),
      ),

      body: PageView.builder(
        controller: _pageController,
        itemCount: _tabCache.length,
        onPageChanged: _handlePageChanged,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        itemBuilder: (context, index) {
          _ensureTabLoaded(index);
          return _KeepAliveTab(
            key: ValueKey("main-tab-$index"),
            child: _tabCache[index] ?? const SizedBox.shrink(),
          );
        },
      ),

      bottomNavigationBar: InotraBottomNav(
        currentIndex: _index,
        onChanged: _onTabChange,
        chatBadgeCount: _chatUnreadCount,
      ),
    );
  }

  @override
  void dispose() {
    _authSession?.removeListener(_handleAuthChange);
    _pageController.dispose();
    super.dispose();
  }
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;

  const _KeepAliveTab({super.key, required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
