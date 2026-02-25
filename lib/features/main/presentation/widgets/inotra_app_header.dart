import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

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
        onPressed: onMenuTap,
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedMenu01,
          size: 24,
          strokeWidth: 2.0,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: [
        IconButton(
          tooltip: "Notifications",
          onPressed: onNotificationsTap,
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedNotification01,
            size: 24,
            strokeWidth: 2.0,
          ),
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
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: 18,
                    strokeWidth: 2.0,
                    color: AppColors.primary,
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