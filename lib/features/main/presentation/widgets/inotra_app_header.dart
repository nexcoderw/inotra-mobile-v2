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

      // Give room for 2 icons on the leading side
      leadingWidth: 104,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            IconButton(
              tooltip: "Menu",
              onPressed: onMenuTap,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedMenuCircle,
                size: 24,
                strokeWidth: 2.0,
              ),
            ),
            IconButton(
              tooltip: "Notifications",
              onPressed: onNotificationsTap,
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                size: 24,
                strokeWidth: 2.0,
              ),
            ),
          ],
        ),
      ),

      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16.5,
          letterSpacing: 0.1,
        ),
      ),

      actions: [
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
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 140),
                  child: Text(
                    displayName,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
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