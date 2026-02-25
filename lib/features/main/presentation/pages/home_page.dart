import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../widgets/main_scaffold.dart";

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Home",
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRoutes.notifications),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            "Welcome to INOTRA",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          _NavCard(
            title: "Trip Packages",
            subtitle: "Browse recommended packages",
            icon: Icons.card_travel,
            onTap: () => Navigator.pushNamed(context, AppRoutes.tripPackages),
          ),
          _NavCard(
            title: "Listings",
            subtitle: "Explore places & properties",
            icon: Icons.place_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.listings),
          ),
          _NavCard(
            title: "Events",
            subtitle: "Discover upcoming events",
            icon: Icons.celebration_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.events),
          ),
          _NavCard(
            title: "AI Chat",
            subtitle: "Ask the INOTRA assistant",
            icon: Icons.auto_awesome_outlined,
            onTap: () => Navigator.pushNamed(context, AppRoutes.aiChat),
          ),
          _NavCard(
            title: "Profile",
            subtitle: "Account settings",
            icon: Icons.person_outline,
            onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
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