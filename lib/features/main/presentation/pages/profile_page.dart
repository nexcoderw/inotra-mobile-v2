import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;
    final user = AuthSession.instance.value.user ?? {};
    final imageUrl = user["image"] as String?;

    return MainScaffold(
      title: t(lang, "profile.title"),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: scheme.primary.withOpacity(0.12),
                  backgroundImage:
                      (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                      ? Icon(Icons.person, size: 38, color: scheme.primary)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  t(lang, "profile.user_profile"),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _ProfileNavTile(
            icon: HugeIcons.strokeRoundedUser,
            title: t(lang, "profile.account_details"),
            subtitle: t(lang, "profile.account_details_sub"),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profileAccount),
          ),
          const SizedBox(height: 10),
          _ProfileNavTile(
            icon: HugeIcons.strokeRoundedLockPassword,
            title: t(lang, "profile.change_password"),
            subtitle: t(lang, "profile.change_password_sub"),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profilePassword),
          ),
          const SizedBox(height: 10),
          _ProfileNavTile(
            icon: Icons.warning_amber_rounded,
            color: scheme.error,
            title: t(lang, "profile.danger_zone"),
            subtitle: t(lang, "profile.danger_zone_sub"),
            onTap: () => Navigator.pushNamed(context, AppRoutes.profileDanger),
          ),
        ],
      ),
    );
  }
}

class _ProfileNavTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tone = color ?? scheme.primary;
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: tone.withOpacity(0.12),
          child: icon is IconData
              ? Icon(icon as IconData, size: 18, color: tone)
              : HugeIcon(icon: icon, size: 18, strokeWidth: 2, color: tone),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSurface.withOpacity(0.65),
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
