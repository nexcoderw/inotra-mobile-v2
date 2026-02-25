import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/app_colors.dart";
import "../widgets/inotra_bottom_nav.dart";

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

  void _goToNotifications() {
    Navigator.pushNamed(context, AppRoutes.notifications);
  }

  void _goToProfile() {
    Navigator.pushNamed(context, AppRoutes.profile);
  }

  void _comingSoon(String label) {
    Navigator.pop(context); // close drawer
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$label — coming soon"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Professional top header
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        titleSpacing: 8,
        leading: IconButton(
          tooltip: "Menu",
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Text(
          _title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: "Notifications",
            icon: const Icon(Icons.notifications_outlined),
            onPressed: _goToNotifications,
          ),
          const SizedBox(width: 6),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _goToProfile,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    child: Icon(
                      Icons.person_outline,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Guest",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),

      // ✅ Sidebar (Drawer)
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black.withOpacity(0.06),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.explore, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "INOTRA",
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            "Menu",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              _DrawerLink(
                icon: Icons.dashboard_outlined,
                title: "Dashboard",
                onTap: () => _comingSoon("Dashboard"),
              ),
              _DrawerLink(
                icon: Icons.celebration_outlined,
                title: "My Events",
                onTap: () => _comingSoon("My Events"),
              ),
              _DrawerLink(
                icon: Icons.place_outlined,
                title: "My Listings",
                onTap: () => _comingSoon("My Listings"),
              ),
              _DrawerLink(
                icon: Icons.receipt_long_outlined,
                title: "Trip Reservations",
                onTap: () => _comingSoon("Trip Reservations"),
              ),

              const Spacer(),

              Padding(
                padding: const EdgeInsets.all(16),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, AppRoutes.profile);
                  },
                  icon: const Icon(Icons.person_outline),
                  label: const Text("Open Profile"),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),

      // ✅ The tab body
      body: IndexedStack(index: _index, children: _tabs),

      // ✅ Bottom nav stays as-is
      bottomNavigationBar: InotraBottomNav(
        currentIndex: _index,
        onChanged: _onTabChange,
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}