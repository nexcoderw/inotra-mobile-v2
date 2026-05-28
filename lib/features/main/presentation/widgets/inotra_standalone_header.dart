import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../core/widgets/app_cached_image.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class InotraStandaloneHeader extends StatelessWidget
    implements PreferredSizeWidget {
  static const double defaultHeight = kToolbarHeight + 6;

  final String title;
  final String displayName;
  final bool isAuthenticated;
  final int unreadCount;
  final VoidCallback onBackTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final double height;
  final String? imageUrl;

  const InotraStandaloneHeader({
    super.key,
    required this.title,
    required this.displayName,
    required this.isAuthenticated,
    required this.unreadCount,
    required this.onBackTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.height = defaultHeight,
    this.imageUrl,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shortName = _shortName(displayName);
    final userImage = imageUrl?.trim().isNotEmpty == true
        ? imageUrl
        : AuthSession.instance.value.user?["image"] as String?;

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 8,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(color: scheme.surface.withValues(alpha: 0.70)),
        ),
      ),
      leadingWidth: 112,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            _GlassIconButton(
              tooltip: tr("nav.back"),
              onTap: onBackTap,
              icon: HugeIcons.strokeRoundedArrowLeft01,
            ),
            const SizedBox(width: 6),
            _NotificationButton(
              onTap: onNotificationsTap,
              unreadCount: unreadCount,
            ),
          ],
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withValues(alpha: 0.94),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            isAuthenticated
                ? t(
                    currentLangSync(),
                    "auth.welcome",
                  ).replaceFirst("{name}", shortName)
                : t(currentLangSync(), "welcome.subtitle"),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withValues(alpha: 0.72),
              height: 1.1,
            ),
          ),
        ],
      ),
      actions: [
        _ProfilePill(
          displayName: isAuthenticated
              ? shortName
              : t(currentLangSync(), "auth.sign_in"),
          onTap: onProfileTap,
          imageUrl: userImage,
          isAuthenticated: isAuthenticated,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

String _shortName(String full) {
  final parts = full
      .trim()
      .split(RegExp(r"\s+"))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty || parts.first.isEmpty) return full;
  final firstInitial = "${parts.first[0]}.";
  if (parts.length == 1) return firstInitial;
  return "$firstInitial ${parts.sublist(1).join(" ")}";
}

class _GlassIconButton extends StatefulWidget {
  final String tooltip;
  final VoidCallback onTap;
  final dynamic icon;

  const _GlassIconButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          scale: _pressed ? 0.98 : 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.onSurface.withValues(alpha: 0.08),
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: widget.icon,
                    size: 18,
                    strokeWidth: 2,
                    color: scheme.onSurface.withValues(alpha: 0.80),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationButton extends StatelessWidget {
  final VoidCallback onTap;
  final int unreadCount;

  const _NotificationButton({required this.onTap, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _GlassIconButton(
          tooltip: "Notifications",
          onTap: onTap,
          icon: HugeIcons.strokeRoundedNotification01,
        ),
        if (unreadCount > 0)
          Positioned(
            top: -1,
            right: -1,
            child: Container(
              padding: const EdgeInsets.all(3),
              constraints: const BoxConstraints(minWidth: 15, minHeight: 15),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                unreadCount > 99 ? "99+" : unreadCount.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _ProfilePill extends StatefulWidget {
  final String displayName;
  final VoidCallback onTap;
  final String? imageUrl;
  final bool isAuthenticated;

  const _ProfilePill({
    required this.displayName,
    required this.onTap,
    required this.imageUrl,
    required this.isAuthenticated,
  });

  @override
  State<_ProfilePill> createState() => _ProfilePillState();
}

class _ProfilePillState extends State<_ProfilePill> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        scale: _pressed ? 0.99 : 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.surface.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.onSurface.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ClipOval(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child:
                          widget.isAuthenticated &&
                              widget.imageUrl != null &&
                              widget.imageUrl!.trim().isNotEmpty
                          ? AppCachedImage(
                              imageUrl: widget.imageUrl!.trim(),
                              fit: BoxFit.cover,
                              memCacheWidth: 80,
                              memCacheHeight: 80,
                              maxWidthDiskCache: 120,
                              maxHeightDiskCache: 120,
                              errorBuilder: (_) => const _ProfileFallbackIcon(),
                              placeholderBuilder: (_) =>
                                  const _ProfileFallbackIcon(),
                            )
                          : const _ProfileFallbackIcon(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: Text(
                      widget.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: scheme.onSurface.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileFallbackIcon extends StatelessWidget {
  const _ProfileFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.primary.withValues(alpha: 0.12),
      child: const Center(
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedUser,
          size: 14,
          strokeWidth: 2,
          color: AppColors.primary,
        ),
      ),
    );
  }
}
