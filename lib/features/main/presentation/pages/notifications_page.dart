import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:provider/provider.dart";

import "../../../../core/config/app_routes.dart";
import "../../../../core/constants/app_colors.dart";
import "../../../../core/models/app_notification.dart";
import "../../../../core/services/notification_service.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../widgets/main_scaffold.dart";
import "../widgets/page_header.dart";

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  @override
  void initState() {
    super.initState();
    // Refresh when page opens so the list is always fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.instance.fetch();
    });
  }

  Future<void> _onRefresh() => NotificationService.instance.fetch();

  void _onTap(BuildContext context, AppNotification notif) {
    NotificationService.instance.markRead(notif.id);
    switch (notif.kind) {
      case "PLACE":
        Navigator.pushNamed(context, AppRoutes.listingDetails,
            arguments: notif.entityId);
      case "EVENT":
        Navigator.pushNamed(context, AppRoutes.eventDetails,
            arguments: notif.entityId);
      case "PACKAGE":
        Navigator.pushNamed(context, AppRoutes.tripPackageDetails,
            arguments: notif.entityId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang   = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "notifications.title"),
      showAppBar: false,
      child: SafeArea(
        child: Consumer<NotificationService>(
          builder: (context, svc, _) {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              color: AppColors.primary,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // ── Header ─────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: PageHeader(
                                title: t(lang, "notifications.title")),
                          ),
                          if (svc.unreadCount > 0)
                            _MarkAllReadButton(
                              onTap: svc.markAllRead,
                              scheme: scheme,
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SliverToBoxAdapter(child: SizedBox(height: 12)),

                  // ── Loading shimmer ─────────────────────────────────────
                  if (svc.loading && !svc.initialized)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _NotificationShimmer(scheme: scheme),
                        childCount: 6,
                      ),
                    )

                  // ── Empty state ─────────────────────────────────────────
                  else if (svc.notifications.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyState(scheme: scheme, lang: lang),
                    )

                  // ── Notification list ───────────────────────────────────
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final notif = svc.notifications[i];
                            return _NotificationTile(
                              notification: notif,
                              onTap: () => _onTap(ctx, notif),
                              scheme: scheme,
                            );
                          },
                          childCount: svc.notifications.length,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Mark all read button ─────────────────────────────────────────────────────

class _MarkAllReadButton extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _MarkAllReadButton({required this.onTap, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.20),
          ),
        ),
        child: Text(
          "Mark all read",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

// ── Individual notification tile ─────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _NotificationTile({
    required this.notification,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: isUnread
                ? AppColors.primary.withOpacity(0.05)
                : scheme.surface.withOpacity(0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? AppColors.primary.withOpacity(0.20)
                  : scheme.onSurface.withOpacity(0.07),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    _KindIcon(kind: notification.kind, isUnread: isUnread),
                    const SizedBox(width: 12),

                    // Text content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isUnread
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: scheme.onSurface
                                        .withOpacity(isUnread ? 0.95 : 0.82),
                                    height: 1.3,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (isUnread) _UnreadDot(),
                            ],
                          ),
                          if (notification.body.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              notification.body,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: scheme.onSurface.withOpacity(0.58),
                                height: 1.4,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            _timeAgo(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface.withOpacity(0.40),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Chevron
                    const SizedBox(width: 8),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 14,
                      strokeWidth: 2,
                      color: scheme.onSurface.withOpacity(0.30),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Kind icon ─────────────────────────────────────────────────────────────────

class _KindIcon extends StatelessWidget {
  final String kind;
  final bool isUnread;

  const _KindIcon({required this.kind, required this.isUnread});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (kind) {
      "EVENT"   => (HugeIcons.strokeRoundedCalendar03, const Color(0xFF6C63FF)),
      "PACKAGE" => (HugeIcons.strokeRoundedAirplane01, const Color(0xFF00B67A)),
      _         => (HugeIcons.strokeRoundedBuilding04,  AppColors.primary),
    };

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(isUnread ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(isUnread ? 0.30 : 0.14),
        ),
      ),
      child: Center(
        child: HugeIcon(
          icon: icon,
          size: 18,
          strokeWidth: 2,
          color: color.withOpacity(isUnread ? 1 : 0.65),
        ),
      ),
    );
  }
}

// ── Unread dot ────────────────────────────────────────────────────────────────

class _UnreadDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      margin: const EdgeInsets.only(top: 3),
      decoration: BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.40),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final ColorScheme scheme;
  final String lang;

  const _EmptyState({required this.scheme, required this.lang});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: scheme.onSurface.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedNotification01,
                size: 30,
                strokeWidth: 1.5,
                color: scheme.onSurface.withOpacity(0.28),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "No notifications yet",
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withOpacity(0.72),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You'll see new listings, events &\ntrip packages here.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: scheme.onSurface.withOpacity(0.44),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Loading shimmer tile ──────────────────────────────────────────────────────

class _NotificationShimmer extends StatelessWidget {
  final ColorScheme scheme;

  const _NotificationShimmer({required this.scheme});

  @override
  Widget build(BuildContext context) {
    final base = scheme.onSurface.withOpacity(0.06);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: scheme.onSurface.withOpacity(0.09),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 10,
                    width: 140,
                    decoration: BoxDecoration(
                      color: scheme.onSurface.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
      ),
    );
  }
}

// ── Time ago helper ───────────────────────────────────────────────────────────

String _timeAgo(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inSeconds < 60)  return "Just now";
  if (diff.inMinutes < 60)  return "${diff.inMinutes}m ago";
  if (diff.inHours < 24)    return "${diff.inHours}h ago";
  if (diff.inDays < 7)      return "${diff.inDays}d ago";
  if (diff.inDays < 30)     return "${(diff.inDays / 7).floor()}w ago";
  if (diff.inDays < 365)    return "${(diff.inDays / 30).floor()}mo ago";
  return "${(diff.inDays / 365).floor()}y ago";
}
