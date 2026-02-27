import "dart:ui";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:toastification/toastification.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/app_colors.dart";
import "../../../../i18n/translations.dart";
import "../../../../core/services/auth_session.dart";

const double _kDrawerTopTileHeight = 72;

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
  final VoidCallback? onProfileTap;

  final VoidCallback? onLogoutTap;

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
    this.onProfileTap,
    this.onLogoutTap,
  });

  String get _lang {
    final preferred =
        AuthSession.instance.value.user?['preferred_language'] as String?;
    if (preferred == null || preferred.isEmpty) return 'en';
    final lower = preferred.toLowerCase();
    if (lower.startsWith('rw')) return 'rw';
    if (lower.startsWith('fr')) return 'fr';
    if (lower.startsWith('es')) return 'es';
    if (lower.startsWith('de')) return 'de';
    return 'en';
  }

  void _openProfile(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();

    onProfileTap?.call();
    navigator.pushNamed(AppRoutes.profile);
  }

  void _logout(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) navigator.pop();

    AuthSession.instance.signOut();
    onLogoutTap?.call();

    toastification.show(
      context: context,
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      title: const Text("Logged out"),
      description: const Text("You have been signed out successfully."),
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 3),
    );

    navigator.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          color: scheme.surface.withOpacity(isDark ? 0.50 : 0.78),
        ),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Column(
              children: [
                const SizedBox(height: 40),
                const _GlassHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    children: [
                      _GlassNavTile(
                        icon: HugeIcons.strokeRoundedDashboardSquare01,
                        title: t(_lang, "nav.dashboard"),
                        subtitle: t(_lang, "nav.highlights"),
                        onTap: onDashboardTap,
                        showTrailing: false,
                      ),

                      _GlassSection(
                        title: t(_lang, "nav.my_events"),
                        icon: HugeIcons.strokeRoundedCalendar01,
                        children: [
                          _GlassSubTile(
                            title: t(_lang, "nav.my_events"),
                            icon: HugeIcons.strokeRoundedCalendar01,
                            onTap: onMyEventsTap,
                          ),
                          _GlassSubTile(
                            title: t(_lang, "nav.my_event_submissions"),
                            icon: HugeIcons.strokeRoundedTask01,
                            onTap: onMyEventSubmissionsTap,
                          ),
                          _GlassSubTile(
                            title: t(_lang, "nav.event_review"),
                            icon: HugeIcons.strokeRoundedStar,
                            onTap: onEventReviewTap,
                          ),
                          _GlassSubTile(
                            title: t(_lang, "nav.event_tickets"),
                            icon: HugeIcons.strokeRoundedTicket01,
                            onTap: onEventTicketsTap,
                          ),
                        ],
                      ),

                      _GlassSection(
                        title: t(_lang, "nav.my_listings"),
                        icon: HugeIcons.strokeRoundedLocation01,
                        children: [
                          _GlassSubTile(
                            title: t(_lang, "nav.my_listings"),
                            icon: HugeIcons.strokeRoundedLocation01,
                            onTap: onMyListingsTap,
                          ),
                          _GlassSubTile(
                            title: t(_lang, "nav.my_listing_submissions"),
                            icon: HugeIcons.strokeRoundedTask01,
                            onTap: onMyListingSubmissionsTap,
                          ),
                          _GlassSubTile(
                            title: t(_lang, "nav.listing_reviews"),
                            icon: HugeIcons.strokeRoundedStar,
                            onTap: onListingReviewsTap,
                          ),
                          _GlassSubTile(
                            title: t(_lang, "nav.listing_booking"),
                            icon: HugeIcons.strokeRoundedCalendarCheckIn01,
                            onTap: onListingBookingTap,
                          ),
                        ],
                      ),

                      _GlassNavTile(
                        icon: HugeIcons.strokeRoundedTicket01,
                        title: t(_lang, "nav.trip_reservations"),
                        subtitle: t(_lang, "common.coming_soon"),
                        onTap: onTripReservationsTap,
                        showTrailing: false,
                      ),

                      _GlassNavTile(
                        icon: HugeIcons.strokeRoundedUser,
                        title: t(_lang, "nav.profile"),
                        subtitle: t(_lang, "profile.user_profile"),
                        onTap: () => _openProfile(context),
                        showTrailing: false,
                      ),

                      _GlassNavTile(
                        icon: HugeIcons.strokeRoundedSettings02,
                        title: t(_lang, "nav.settings"),
                        subtitle: t(_lang, "nav.settings_sub"),
                        onTap: onSettingsTap,
                        showTrailing: false,
                      ),

                      _GlassDangerTile(
                        icon: HugeIcons.strokeRoundedLogout01,
                        title: t(_lang, "nav.logout"),
                        subtitle: t(_lang, "nav.logout_sub"),
                        onTap: () => _logout(context),
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
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(isDark ? 0.16 : 0.10),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.10 : 0.20),
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
                    color: scheme.onSurface.withOpacity(0.96),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "By NAVIG8",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: scheme.onSurface.withOpacity(0.78),
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ----------------------------
/// LINK TILE (transparent bg + separator line)
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
    final divider = scheme.onSurface.withOpacity(0.10);

    return _SeparatedTile(
      dividerColor: divider,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: _kDrawerTopTileHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
            child: Row(
              children: [
                _IconPill(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.94),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        (subtitle ?? ""),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: scheme.onSurface.withOpacity(0.72),
                        ),
                      ),
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
      ),
    );
  }
}

class _GlassDangerTile extends StatelessWidget {
  final dynamic icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _GlassDangerTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider = scheme.onSurface.withOpacity(0.10);

    return _SeparatedTile(
      dividerColor: divider,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: _kDrawerTopTileHeight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    // ✅ no border, transparent-ish bg
                    color: Colors.red.withOpacity(isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      size: 20,
                      strokeWidth: 2.0,
                      color: isDark ? Colors.white : Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          color: scheme.onSurface.withOpacity(0.94),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                          color: scheme.onSurface.withOpacity(0.72),
                        ),
                      ),
                    ],
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
        ),
      ),
    );
  }
}

/// ----------------------------
/// SECTION (header = transparent + separator; body unchanged)
/// ----------------------------
class _GlassSection extends StatefulWidget {
  final String title;
  final dynamic icon;
  final List<Widget> children;

  const _GlassSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  State<_GlassSection> createState() => _GlassSectionState();
}

class _GlassSectionState extends State<_GlassSection>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final divider = scheme.onSurface.withOpacity(0.10);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SeparatedTile(
          dividerColor: divider,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _toggle,
            child: SizedBox(
              height: _kDrawerTopTileHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 12),
                child: Row(
                  children: [
                    _IconPill(icon: widget.icon),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              color: scheme.onSurface.withOpacity(0.94),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Tap to expand",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: scheme.onSurface.withOpacity(0.70),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowDown01,
                        size: 14,
                        strokeWidth: 2.0,
                        color: scheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // expand area
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints:
                  _expanded ? const BoxConstraints() : const BoxConstraints(maxHeight: 0),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(52, 6, 6, 10),
                child: Column(children: widget.children),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// ----------------------------
/// SUB TILE (inside section) + separator
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
    final divider = scheme.onSurface.withOpacity(0.10);

    return _SeparatedTile(
      dividerColor: divider,
      inset: const EdgeInsets.only(left: 6, right: 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          child: Row(
            children: [
              HugeIcon(
                icon: icon,
                size: 18,
                strokeWidth: 2.0,
                color: scheme.onSurface.withOpacity(0.88),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: scheme.onSurface.withOpacity(0.92),
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
      ),
    );
  }
}

/// ----------------------------
/// Separator wrapper (line below each link)
/// ----------------------------
class _SeparatedTile extends StatelessWidget {
  final Widget child;
  final Color dividerColor;
  final EdgeInsets inset;

  const _SeparatedTile({
    required this.child,
    required this.dividerColor,
    this.inset = const EdgeInsets.only(left: 52, right: 6),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ✅ transparent background + no border
        Material(
          color: Colors.transparent,
          child: child,
        ),

        // ✅ separator line
        Padding(
          padding: inset,
          child: Divider(
            height: 1,
            thickness: 1,
            color: dividerColor,
          ),
        ),
      ],
    );
  }
}

/// ----------------------------
/// ICON PILL (transparent bg + no border; theme-based icon color)
/// ----------------------------
class _IconPill extends StatelessWidget {
  final dynamic icon;

  const _IconPill({required this.icon});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ Your rule:
    // - dark: white icon with stroke
    // - light: primary color icon
    final iconColor = isDark ? Colors.white : AppColors.primary;

    return SizedBox(
      height: 40,
      width: 40,
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: 20,
          strokeWidth: 2.0,
          color: iconColor,
        ),
      ),
    );
  }
}