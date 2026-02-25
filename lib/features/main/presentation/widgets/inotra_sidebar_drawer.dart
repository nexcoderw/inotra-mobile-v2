import "dart:ui";
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
  final VoidCallback onSettingsTap;
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
    required this.onSettingsTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            // Glass base surface
            color: scheme.surface.withOpacity(isDark ? 0.55 : 0.80),
          ),
          child: Stack(
            children: [
              // soft blobs (premium glass feel)
              Positioned(
                top: -80,
                left: -60,
                child: _GlowBlob(color: AppColors.primary.withOpacity(0.20), size: 220),
              ),
              Positioned(
                bottom: -90,
                right: -60,
                child: _GlowBlob(color: scheme.secondary.withOpacity(0.16), size: 240),
              ),

              // main content
              ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Column(
                    children: [
                      _GlassHeader(),

                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                          children: [
                            _GlassNavTile(
                              icon: HugeIcons.strokeRoundedDashboardSquare01,
                              title: "Dashboard",
                              subtitle: "Overview & quick stats",
                              onTap: onDashboardTap,
                              // no trailing arrow for non-dropdown links ✅
                              showTrailing: false,
                            ),

                            const SizedBox(height: 12),

                            _GlassSection(
                              title: "My Events",
                              icon: HugeIcons.strokeRoundedCalendar01,
                              children: [
                                _GlassSubTile(
                                  title: "My Events",
                                  icon: HugeIcons.strokeRoundedCalendar01,
                                  onTap: onMyEventsTap,
                                ),
                                _GlassSubTile(
                                  title: "My Event Submissions",
                                  icon: HugeIcons.strokeRoundedTask01,
                                  onTap: onMyEventSubmissionsTap,
                                ),
                                _GlassSubTile(
                                  title: "Review",
                                  icon: HugeIcons.strokeRoundedStar,
                                  onTap: onEventReviewTap,
                                ),
                                _GlassSubTile(
                                  title: "Tickets",
                                  icon: HugeIcons.strokeRoundedTicket01,
                                  onTap: onEventTicketsTap,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _GlassSection(
                              title: "My Listings",
                              icon: HugeIcons.strokeRoundedLocation01,
                              children: [
                                _GlassSubTile(
                                  title: "My Listings",
                                  icon: HugeIcons.strokeRoundedLocation01,
                                  onTap: onMyListingsTap,
                                ),
                                _GlassSubTile(
                                  title: "My Listing Submissions",
                                  icon: HugeIcons.strokeRoundedTask01,
                                  onTap: onMyListingSubmissionsTap,
                                ),
                                _GlassSubTile(
                                  title: "Reviews",
                                  icon: HugeIcons.strokeRoundedStar,
                                  onTap: onListingReviewsTap,
                                ),
                                _GlassSubTile(
                                  title: "Booking",
                                  icon: HugeIcons.strokeRoundedCalendarCheckIn01,
                                  onTap: onListingBookingTap,
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            _GlassNavTile(
                              icon: HugeIcons.strokeRoundedTicket01,
                              title: "Trip Reservations",
                              subtitle: "Your bookings & status",
                              onTap: onTripReservationsTap,
                              showTrailing: false, // ✅ no arrow
                            ),

                            const SizedBox(height: 12),

                            _GlassNavTile(
                              icon: HugeIcons.strokeRoundedSettings02,
                              title: "Settings",
                              subtitle: "Your settings & preferences",
                              onTap: onSettingsTap,
                              showTrailing: false, // ✅ no arrow
                            ),

                            const SizedBox(height: 16),

                            _GlassPrimaryButton(
                              icon: HugeIcons.strokeRoundedUser,
                              label: "Open Profile",
                              onTap: onProfileTap,
                            ),

                            const SizedBox(height: 10),

                            Text(
                              "INOTRA • v1.0",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: scheme.onSurface.withOpacity(0.55),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// HEADER
/// ----------------------------
class _GlassHeader extends StatelessWidget {
  const _GlassHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            // ✅ Logo from assets (instead of icon)
            Container(
              height: 44,
              width: 44,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: scheme.surface.withOpacity(isDark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(isDark ? 0.10 : 0.22),
                ),
              ),
              child: Image.asset(
                "assets/branding/logo_color.png",
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "INOTRA",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                      color: scheme.onSurface,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "Premium navigation",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      color: scheme.onSurface.withOpacity(0.62),
                      height: 1.1,
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

/// ----------------------------
/// TOP LEVEL TILE (no dropdown)
/// ----------------------------
class _GlassNavTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final bool showTrailing;

  const _GlassNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.showTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            children: [
              _IconPill(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: scheme.onSurface.withOpacity(0.62),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (showTrailing)
                HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 18,
                  strokeWidth: 2.0,
                  color: scheme.onSurface.withOpacity(0.55),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// SECTION (dropdown)
/// ----------------------------
class _GlassSection extends StatelessWidget {
  final String title;
  final dynamic icon;
  final List<Widget> children;

  const _GlassSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return _GlassCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
          leading: _IconPill(icon: icon),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
          ),
          subtitle: Text(
            "Tap to expand",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
              color: scheme.onSurface.withOpacity(0.60),
            ),
          ),
          trailing: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowDown01,
            size: 14,
            strokeWidth: 2.0,
            color: scheme.onSurface.withOpacity(0.55),
          ),
          children: children,
        ),
      ),
    );
  }
}

/// ----------------------------
/// SUB TILE (inside section)
/// ----------------------------
class _GlassSubTile extends StatelessWidget {
  final String title;
  final dynamic icon;
  final VoidCallback onTap;

  const _GlassSubTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            HugeIcon(icon: icon, size: 18, strokeWidth: 2.0),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12, // ✅ dropdown item font size
                ),
              ),
            ),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 18,
              strokeWidth: 2.0,
              color: scheme.onSurface.withOpacity(0.50),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------
/// PRIMARY CTA BUTTON
/// ----------------------------
class _GlassPrimaryButton extends StatelessWidget {
  final dynamic icon;
  final String label;
  final VoidCallback onTap;

  const _GlassPrimaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return _GlassCard(
      radius: 18,
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withOpacity(isDark ? 0.38 : 0.18),
                scheme.secondary.withOpacity(isDark ? 0.22 : 0.12),
              ],
            ),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: icon,
                size: 20,
                strokeWidth: 2.0,
                color: scheme.onSurface,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 18,
                strokeWidth: 2.0,
                color: scheme.onSurface.withOpacity(0.65),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------
/// REUSABLE GLASS CARD
/// ----------------------------
class _GlassCard extends StatelessWidget {
  final Widget child;
  final double radius;
  final EdgeInsets padding;

  const _GlassCard({
    required this.child,
    this.radius = 16,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: scheme.surface.withOpacity(isDark ? 0.35 : 0.62),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(isDark ? 0.10 : 0.22),
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                spreadRadius: 0,
                offset: const Offset(0, 10),
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ----------------------------
/// ICON PILL
/// ----------------------------
class _IconPill extends StatelessWidget {
  final dynamic icon;

  const _IconPill({required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 40,
      width: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.26 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(isDark ? 0.08 : 0.18)),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: 20,
          strokeWidth: 2.0,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// ----------------------------
/// GLOW BLOB
/// ----------------------------
class _GlowBlob extends StatelessWidget {
  final Color color;
  final double size;

  const _GlowBlob({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}