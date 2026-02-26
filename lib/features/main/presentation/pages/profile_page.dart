import "package:flutter/material.dart";
import "../../../../core/config/app_routes.dart";
import "../widgets/main_scaffold.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _logout(BuildContext context) {
    AuthSession.instance.signOut();
    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    return MainScaffold(
      title: t(lang, "profile.title"),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 32, child: Icon(Icons.person)),
          const SizedBox(height: 12),
          Text(
            t(lang, "profile.user_profile"),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: Text(t(lang, "profile.notifications")),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.pushNamed(context, AppRoutes.notifications),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: Text(t(lang, "nav.logout")),
              onTap: () => _logout(context),
            ),
          ),
        ],
      ),
    );
  }
}
