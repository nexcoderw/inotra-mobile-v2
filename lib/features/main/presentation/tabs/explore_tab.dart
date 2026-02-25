import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          const Text(
            "Explore",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _Card(
            title: "Trip Packages",
            subtitle: "Browse recommended packages",
            icon: Icons.card_travel,
            onTap: () => Navigator.pushNamed(context, AppRoutes.tripPackages),
          ),
          _Card(
            title: "Listings",
            subtitle: "Explore places & properties",
            icon: Icons.travel_explore_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.listings),
          ),
          _Card(
            title: "Events",
            subtitle: "Discover upcoming events",
            icon: Icons.celebration_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.events),
          ),
          _Card(
            title: "AI Chat Conversations",
            subtitle: "View previous chats",
            icon: Icons.chat_bubble_outline,
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiChatConversations),
          ),
          _Card(
            title: "Profile",
            subtitle: "Account settings",
            icon: Icons.person_outline,
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          _Card(
            title: "Notifications",
            subtitle: "Latest updates",
            icon: Icons.notifications_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _Card({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}