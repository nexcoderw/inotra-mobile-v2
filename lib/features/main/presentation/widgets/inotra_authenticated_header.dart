import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class InotraAuthenticatedHeader extends StatelessWidget
    implements PreferredSizeWidget {
  static const double defaultHeight = kToolbarHeight + 6;

  final String title;
  final String displayName;
  final VoidCallback onMenuTap;
  final VoidCallback onNotificationsTap;
  final VoidCallback onProfileTap;
  final double height;
  final String? imageUrl;
  final int unreadCount;

  const InotraAuthenticatedHeader({
    super.key,
    required this.title,
    required this.displayName,
    required this.onMenuTap,
    required this.onNotificationsTap,
    required this.onProfileTap,
    this.imageUrl,
    this.height = defaultHeight,
    this.unreadCount = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final userImage = (imageUrl != null && imageUrl!.isNotEmpty)
        ? imageUrl
        : AuthSession.instance.value.user?["image"] as String?;

    final avatarProvider =
        (userImage != null && userImage.isNotEmpty) ? NetworkImage(userImage) : null;
    final shortName = _shortName(displayName);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 8,
      automaticallyImplyLeading: false,

      // ✅ Premium glassy header (no border/shadow)
      backgroundColor: Colors.transparent,
      foregroundColor: scheme.onSurface,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            color: scheme.surface.withOpacity(0.70),
          ),
        ),
      ),

      leadingWidth: 112,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Row(
          children: [
            _IconPillButton(
              tooltip: "Menu",
              onTap: onMenuTap,
              icon: HugeIcons.strokeRoundedMenuCircle,
            ),
            const SizedBox(width: 6),
            _NotificationPillButton(
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
              color: scheme.onSurface.withOpacity(0.94),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t(currentLangSync(), "auth.welcome").isNotEmpty
                ? t(currentLangSync(), "auth.welcome").replaceFirst("{name}", shortName)
                : shortName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withOpacity(0.72),
              height: 1.1,
            ),
          ),
        ],
      ),

      actions: [
        _ProfilePill(
          displayName: shortName,
          onTap: onProfileTap,
          imageProvider: avatarProvider,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

String _shortName(String full) {
  final parts =
      full.trim().split(RegExp(r"\\s+")).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty || parts.first.isEmpty) return full;
  final firstInitial = "${parts.first[0]}.";
  if (parts.length == 1) return firstInitial;
  final last = parts.sublist(1).join(" ");
  return "$firstInitial $last";
}

class _IconPillButton extends StatefulWidget {
  final String tooltip;
  final VoidCallback onTap;
  final dynamic icon;

  const _IconPillButton({
    required this.tooltip,
    required this.onTap,
    required this.icon,
  });

  @override
  State<_IconPillButton> createState() => _IconPillButtonState();
}

class _IconPillButtonState extends State<_IconPillButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
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
                  color: scheme.surface.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: scheme.onSurface.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: HugeIcon(
                    icon: widget.icon,
                    size: 18,
                    strokeWidth: 2,
                    color: scheme.onSurface.withOpacity(0.80),
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

class _NotificationPillButton extends StatefulWidget {
  final VoidCallback onTap;
  final int unreadCount;

  const _NotificationPillButton({
    required this.onTap,
    required this.unreadCount,
  });

  @override
  State<_NotificationPillButton> createState() =>
      _NotificationPillButtonState();
}

class _NotificationPillButtonState extends State<_NotificationPillButton> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: "Notifications",
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: widget.onTap,
        child: AnimatedScale(
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOut,
          scale: _pressed ? 0.98 : 1,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      color: scheme.surface.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: scheme.onSurface.withOpacity(0.08),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedNotification01,
                        size: 18,
                        strokeWidth: 2,
                        color: scheme.onSurface.withOpacity(0.80),
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.unreadCount > 0)
                Positioned(
                  top: -1,
                  right: -1,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 15,
                      minHeight: 15,
                    ),
                    child: Text(
                      widget.unreadCount > 99
                          ? "99+"
                          : widget.unreadCount.toString(),
                      style: const TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
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

class _ProfilePill extends StatefulWidget {
  final String displayName;
  final VoidCallback onTap;
  final ImageProvider? imageProvider;

  const _ProfilePill({
    required this.displayName,
    required this.onTap,
    required this.imageProvider,
  });

  @override
  State<_ProfilePill> createState() => _ProfilePillState();
}

class _ProfilePillState extends State<_ProfilePill> {
  bool _pressed = false;

  void _setPressed(bool v) => setState(() => _pressed = v);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapCancel: () => _setPressed(false),
      onTapUp: (_) => _setPressed(false),
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
                color: scheme.surface.withOpacity(0.55),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: scheme.onSurface.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 13,
                    backgroundColor: AppColors.primary.withOpacity(0.12),
                    backgroundImage: widget.imageProvider,
                    child: widget.imageProvider == null
                        ? const HugeIcon(
                            icon: HugeIcons.strokeRoundedUser,
                            size: 14,
                            strokeWidth: 2.0,
                            color: AppColors.primary,
                          )
                        : null,
                  ),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Text(
                      widget.displayName,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: scheme.onSurface.withOpacity(0.88),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    size: 14,
                    strokeWidth: 2,
                    color: scheme.onSurface.withOpacity(0.55),
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
