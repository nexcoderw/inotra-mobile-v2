import "dart:ui";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";
import "../../../auth/presentation/widgets/quick_login_dialog.dart";

class InotraGuestHeader extends StatelessWidget implements PreferredSizeWidget {
  static const double defaultHeight = kToolbarHeight + 6;

  final String title;
  final double height;

  const InotraGuestHeader({
    super.key,
    required this.title,
    this.height = defaultHeight,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lang = currentLangSync();

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
      leadingWidth: 0,
      leading: const SizedBox.shrink(),
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
            t(lang, "welcome.subtitle"),
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
        _SignInPill(
          label: t(lang, "auth.sign_in"),
          onTap: () => QuickLoginDialog.show(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _SignInPill extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _SignInPill({required this.label, required this.onTap});

  @override
  State<_SignInPill> createState() => _SignInPillState();
}

class _SignInPillState extends State<_SignInPill> {
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
                  const _SignInIcon(),
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 112),
                    child: Text(
                      widget.label,
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

class _SignInIcon extends StatelessWidget {
  const _SignInIcon();

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: ColoredBox(
        color: AppColors.primary.withValues(alpha: 0.12),
        child: const SizedBox(
          width: 26,
          height: 26,
          child: Center(
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedUser,
              size: 14,
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}
