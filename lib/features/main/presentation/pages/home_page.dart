import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    return MainScaffold(
      title: t(lang, "nav.dashboard"),
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            t(lang, "home.welcome"),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _NavCard(
            title: t(lang, "home.trip_packages"),
            subtitle: t(lang, "home.trip_packages_sub"),
            icon: Icons.card_travel,
            onTap: () => Navigator.pushNamed(context, AppRoutes.tripPackages),
          ),
          _NavCard(
            title: t(lang, "home.listings"),
            subtitle: t(lang, "home.listings_sub"),
            icon: Icons.place_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.listings),
          ),
          _NavCard(
            title: t(lang, "home.events"),
            subtitle: t(lang, "home.events_sub"),
            icon: Icons.celebration_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.events),
          ),
          _NavCard(
            title: t(lang, "home.ai_chat"),
            subtitle: t(lang, "home.ai_chat_sub"),
            icon: Icons.auto_awesome_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiChat),
          ),
          _NavCard(
            title: t(lang, "home.profile"),
            subtitle: t(lang, "home.profile_sub"),
            icon: Icons.person_outline,
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
          ),
          _NavCard(
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

class _NavCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _NavCard({
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
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
