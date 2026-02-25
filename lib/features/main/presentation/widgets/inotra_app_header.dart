import "package:flutter/material.dart";
import "../../../../core/constants/app_colors.dart";

class InotraAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;

  final String displayName;

  const InotraAppHeader({
    super.key,
    required this.title,
    required this.onMenuTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.displayName = "Guest",
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AppBar(
      elevation: 0,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      titleSpacing: 8,
      leading: IconButton(
        tooltip: "Menu",
        icon: const Icon(Icons.menu_rounded),
        onPressed: onMenuTap,
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: "Notifications",
          icon: const Icon(Icons.notifications_outlined),
          onPressed: onNotificationsTap,
        ),
        const SizedBox(width: 6),
        InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onProfileTap,
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
                Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );
  }
}