import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";

class InotraSidebarDrawer extends StatelessWidget {
  final VoidCallback onDashboardTap;
  final VoidCallback onMyEventsTap;
  final VoidCallback onMyListingsTap;
  final VoidCallback onTripReservationsTap;
  final VoidCallback onProfileTap;

  const InotraSidebarDrawer({
    super.key,
    required this.onDashboardTap,
    required this.onMyEventsTap,
    required this.onMyListingsTap,
    required this.onTripReservationsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.06),
                  ),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    child: const HugeIcon(
                      icon: HugeIcons.strokeRoundedCompass01,
                      color: Colors.white,
                      size: 22,
                      strokeWidth: 2.0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "INOTRA",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Menu",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            _DrawerLink(
              icon: HugeIcons.strokeRoundedDashboardSquare01,
              title: "Dashboard",
              onTap: onDashboardTap,
            ),
            _DrawerLink(
              icon: HugeIcons.strokeRoundedCalendar01,
              title: "My Events",
              onTap: onMyEventsTap,
            ),
            _DrawerLink(
              icon: HugeIcons.strokeRoundedLocation01,
              title: "My Listings",
              onTap: onMyListingsTap,
            ),
            _DrawerLink(
              icon: HugeIcons.strokeRoundedTicket01,
              title: "Trip Reservations",
              onTap: onTripReservationsTap,
            ),

            const Spacer(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: onProfileTap,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedUser,
                  size: 20,
                  strokeWidth: 2.0,
                ),
                label: const Text("Open Profile"),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  final dynamic icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerLink({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: HugeIcon(icon: icon, size: 22, strokeWidth: 2.0),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      trailing: const HugeIcon(
        icon: HugeIcons.strokeRoundedArrowRight01,
        size: 20,
        strokeWidth: 2.0,
      ),
      onTap: onTap,
    );
  }
}