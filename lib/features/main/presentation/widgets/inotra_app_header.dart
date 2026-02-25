import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/config/app_routes.dart";

class InotraAppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final String displayName;
  final bool isAuthenticated;

  const InotraAppHeader({
    super.key,
    required this.title,
    required this.onMenuTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.displayName = "Guest",
    this.isAuthenticated = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 6);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // When unauthenticated: show a focused CTA strip instead of the full app header.
    if (!isAuthenticated) {
      return PreferredSize(
        preferredSize: preferredSize,
        child: Material(
          color: scheme.surface,
          elevation: 0,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: kToolbarHeight + 6,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome to Inotra",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Sign in to unlock the full experience",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: scheme.onSurface.withOpacity(0.62),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.7)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                        child: const Text(
                          "Sign In",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                        ),
                        onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                        child: const Text(
                          "Register",
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return AppBar(
      elevation: 0,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      titleSpacing: 8,
      automaticallyImplyLeading: false,

      // Give room for icons on the leading side (only when authenticated)
      leadingWidth: isAuthenticated ? 104 : 0,
      leading: isAuthenticated
          ? Padding(
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
            )
          : null,

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
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: isAuthenticated
              ? InkWell(
                  key: const ValueKey("profile"),
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
                )
              : Padding(
                  key: const ValueKey("auth-cta"),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Welcome!",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: scheme.onSurface,
                            ),
                          ),
                          Text(
                            "Sign in to enjoy full experience",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: scheme.onSurface.withOpacity(0.60),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: BorderSide(color: AppColors.primary.withOpacity(0.6)),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                            child: const Text(
                              "Sign In",
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                              minimumSize: const Size(0, 0),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                            child: const Text(
                              "Sign Up",
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
