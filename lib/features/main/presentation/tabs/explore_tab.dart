import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ExploreTab extends StatelessWidget {
  const ExploreTab({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        children: [
          Text(
            t(lang, "nav.explore"),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          _Card(
            title: t(lang, "home.trip_packages"),
            subtitle: t(lang, "home.trip_packages_sub"),
            icon: Icons.card_travel,
            onTap: () => Navigator.pushNamed(context, AppRoutes.tripPackages),
          ),
          _Card(
            title: t(lang, "home.listings"),
            subtitle: t(lang, "home.listings_sub"),
            icon: Icons.travel_explore_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.listings),
          ),
          _Card(
            title: t(lang, "home.events"),
            subtitle: t(lang, "home.events_sub"),
            icon: Icons.celebration_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.events),
          ),
          _Card(
            title: t(lang, "ai.conversations"),
            subtitle: t(lang, "ai.placeholder"),
            icon: Icons.chat_bubble_outline,
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiChatConversations),
          ),
          _Card(
            title: t(lang, "home.profile"),
            subtitle: t(lang, "home.profile_sub"),
            icon: Icons.person_outline,
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          _Card(
            title: t(lang, "home.notifications"),
            subtitle: t(lang, "home.notifications_sub"),
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
