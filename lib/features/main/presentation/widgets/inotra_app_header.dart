import "package:flutter/material.dart";

import "inotra_authenticated_header.dart";
import "inotra_guest_header.dart";

class InotraAppHeader extends StatelessWidget implements PreferredSizeWidget {
  static const double _headerHeight = kToolbarHeight + 6;

  final String title;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final String displayName;
  final bool isAuthenticated;
  final int unreadCount;

  const InotraAppHeader({
    super.key,
    required this.title,
    required this.onMenuTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.displayName = "Guest",
    this.isAuthenticated = false,
    this.unreadCount = 0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(_headerHeight);

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return const InotraGuestHeader(height: _headerHeight);
    }

    return InotraAuthenticatedHeader(
      title: title,
      displayName: displayName,
      onMenuTap: onMenuTap,
      onNotificationsTap: onNotificationsTap,
      onProfileTap: onProfileTap,
      height: _headerHeight,
      unreadCount: unreadCount,
    );
  }
}
