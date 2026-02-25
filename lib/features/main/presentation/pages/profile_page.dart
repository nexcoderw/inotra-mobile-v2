import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../widgets/main_scaffold.dart";

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _logout(BuildContext context) {
    // TODO: Call API auth/logout/ and clear local tokens.
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Profile",
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 32, child: Icon(Icons.person)),
          const SizedBox(height: 12),
          const Text(
            "User Profile",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text("Notifications"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Logout"),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}