import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";

class InotraSidebarDrawer extends StatelessWidget {
  final VoidCallback onDashboardTap;

  // EVENTS
  final VoidCallback onMyEventsTap;
  final VoidCallback onMyEventSubmissionsTap;
  final VoidCallback onEventReviewTap;
  final VoidCallback onEventTicketsTap;

  // LISTINGS
  final VoidCallback onMyListingsTap;
  final VoidCallback onMyListingSubmissionsTap;
  final VoidCallback onListingReviewsTap;
  final VoidCallback onListingBookingTap;

  final VoidCallback onTripReservationsTap;
  final VoidCallback onProfileTap;

  const InotraSidebarDrawer({
    super.key,
    required this.onDashboardTap,

    required this.onMyEventsTap,
    required this.onMyEventSubmissionsTap,
    required this.onEventReviewTap,
    required this.onEventTicketsTap,

    required this.onMyListingsTap,
    required this.onMyListingSubmissionsTap,
    required this.onListingReviewsTap,
    required this.onListingBookingTap,

    required this.onTripReservationsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // Header
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

            // Body (scrollable)
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                children: [
                  _DrawerLink(
                    icon: HugeIcons.strokeRoundedDashboardSquare01,
                    title: "Dashboard",
                    onTap: onDashboardTap,
                  ),

                  const SizedBox(height: 10),

                  // EVENTS dropdown
                  _DrawerSection(
                    title: "My Events",
                    icon: HugeIcons.strokeRoundedCalendar01,
                    children: [
                      _DrawerSubLink(
                        title: "My Events",
                        icon: HugeIcons.strokeRoundedCalendar01,
                        onTap: onMyEventsTap,
                      ),
                      _DrawerSubLink(
                        title: "My Event Submissions",
                        icon: HugeIcons.strokeRoundedTask01,
                        onTap: onMyEventSubmissionsTap,
                      ),
                      _DrawerSubLink(
                        title: "Review",
                        icon: HugeIcons.strokeRoundedStar,
                        onTap: onEventReviewTap,
                      ),
                      _DrawerSubLink(
                        title: "Tickets",
                        icon: HugeIcons.strokeRoundedTicket01,
                        onTap: onEventTicketsTap,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // LISTINGS dropdown
                  _DrawerSection(
                    title: "My Listings",
                    icon: HugeIcons.strokeRoundedLocation01,
                    children: [
                      _DrawerSubLink(
                        title: "My Listings",
                        icon: HugeIcons.strokeRoundedLocation01,
                        onTap: onMyListingsTap,
                      ),
                      _DrawerSubLink(
                        title: "My Listing Submissions",
                        icon: HugeIcons.strokeRoundedTask01,
                        onTap: onMyListingSubmissionsTap,
                      ),
                      _DrawerSubLink(
                        title: "Reviews",
                        icon: HugeIcons.strokeRoundedStar,
                        onTap: onListingReviewsTap,
                      ),
                      _DrawerSubLink(
                        title: "Booking",
                        icon: HugeIcons.strokeRoundedCalendarCheckIn01,
                        onTap: onListingBookingTap,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  _DrawerLink(
                    icon: HugeIcons.strokeRoundedTicket01,
                    title: "Trip Reservations",
                    onTap: onTripReservationsTap,
                  ),

                  const SizedBox(height: 18),

                  // Premium profile button
                  OutlinedButton.icon(
                    onPressed: onProfileTap,
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedUser,
                      size: 20,
                      strokeWidth: 2.0,
                    ),
                    label: const Text("Open Profile"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      foregroundColor: scheme.onSurface,
                      side: BorderSide(color: scheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
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
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        leading: HugeIcon(icon: icon, size: 22, strokeWidth: 2.0),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        trailing: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          size: 20,
          strokeWidth: 2.0,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _DrawerSection extends StatelessWidget {
  final String title;
  final dynamic icon;
  final List<Widget> children;

  const _DrawerSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.8)),
      ),
      child: Theme(
        // Remove default ExpansionTile divider/paddings and make it cleaner
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          leading: HugeIcon(icon: icon, size: 22, strokeWidth: 2.0),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          trailing: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowDown01,
            size: 20,
            strokeWidth: 2.0,
          ),
          children: children,
        ),
      ),
    );
  }
}

class _DrawerSubLink extends StatelessWidget {
  final String title;
  final dynamic icon;
  final VoidCallback onTap;

  const _DrawerSubLink({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              HugeIcon(icon: icon, size: 18, strokeWidth: 2.0),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              const HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                strokeWidth: 2.0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}