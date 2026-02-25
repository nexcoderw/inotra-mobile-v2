import "package:flutter/material.dart";

import "../../../../core/config/app_routes.dart";
import "../widgets/inotra_bottom_nav.dart";

// Tab pages (lightweight, no nested Scaffold)
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

  void _onTabChange(int next) {
    if (next == _index) return;

    setState(() => _index = next);

    // Update route name so back button / deep links make sense
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
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: InotraBottomNav(
        currentIndex: _index,
        onChanged: _onTabChange,
      ),
    );
  }
}