import "dart:ui";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/services/auth_session.dart";
import "../../../../i18n/translations.dart";

class InotraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const InotraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  String _lang() {
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

  @override
  Widget build(BuildContext context) {
    final lang = _lang();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ soft glass base, no border, no shadow, no gradient
    final baseBg = scheme.surface.withOpacity(isDark ? 0.52 : 0.78);

    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              height: 66,
              decoration: BoxDecoration(
                color: baseBg,
                borderRadius: BorderRadius.circular(999),
              ),
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniNavItem(
                    selected: currentIndex == 0,
                    label: t(lang, "nav.explore"),
                    icon: HugeIcons.strokeRoundedHome01,
                    onTap: () => onChanged(0),
                  ),
                  _MiniNavItem(
                    selected: currentIndex == 1,
                    label: t(lang, "nav.listings"),
                    icon: HugeIcons.strokeRoundedHotelBell,
                    onTap: () => onChanged(1),
                  ),

                  // ✅ floating center action (premium)
                  _CenterFabNavItem(
                    selected: currentIndex == 2,
                    label: t(lang, "nav.ai_chat"),
                    icon: HugeIcons.strokeRoundedSparkles,
                    onTap: () => onChanged(2),
                  ),

                  _MiniNavItem(
                    selected: currentIndex == 3,
                    label: t(lang, "nav.events"),
                    icon: HugeIcons.strokeRoundedFireworks,
                    onTap: () => onChanged(3),
                  ),
                  _MiniNavItem(
                    selected: currentIndex == 4,
                    label: t(lang, "nav.highlights"),
                    icon: HugeIcons.strokeRoundedPlay,
                    onTap: () => onChanged(4),
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

class _MiniNavItem extends StatelessWidget {
  final bool selected;
  final String label;
  final dynamic icon;
  final VoidCallback onTap;

  const _MiniNavItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ theme icon rule
    final baseIconColor = isDark ? Colors.white : AppColors.primary;
    final iconColor = selected ? scheme.primary : baseIconColor;

    // ✅ small top indicator instead of wide pill (new UI)
    final indicatorColor =
        selected ? scheme.primary : scheme.onSurface.withOpacity(isDark ? 0.12 : 0.10);

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: SizedBox(
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                height: 4,
                width: selected ? 18 : 8,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: indicatorColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              HugeIcon(
                icon: icon,
                size: 18,
                strokeWidth: 2.2,
                color: iconColor,
              ),
              const SizedBox(height: 6),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                  color: selected
                      ? scheme.onSurface.withOpacity(0.92)
                      : scheme.onSurface.withOpacity(0.60),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterFabNavItem extends StatelessWidget {
  final bool selected;
  final String label;
  final dynamic icon;
  final VoidCallback onTap;

  const _CenterFabNavItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ no shadows, no gradients
    final fabBg = scheme.primary;
    final ring = isDark
        ? Colors.white.withOpacity(0.18)
        : scheme.onSurface.withOpacity(0.08);

    // make it feel “floating” via position only (not shadow)
    return Expanded(
      child: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            scale: selected ? 1.02 : 1.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: fabBg,
                    shape: BoxShape.circle,
                    border: Border.all(color: ring, width: 1),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: icon,
                      size: 20,
                      strokeWidth: 2.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: scheme.onSurface.withOpacity(0.78),
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