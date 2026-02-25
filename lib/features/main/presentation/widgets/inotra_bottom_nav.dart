import "dart:ui";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";

class InotraBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onChanged;

  const InotraBottomNav({
    super.key,
    required this.currentIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.92),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(
                  color: Colors.white.withOpacity(0.10),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    selected: currentIndex == 0,
                    label: "Explore",
                    icon: HugeIcons.strokeRoundedHome01,
                    onTap: () => onChanged(0),
                  ),
                  _NavItem(
                    selected: currentIndex == 1,
                    label: "Listings",
                    icon: HugeIcons.strokeRoundedSearch01,
                    onTap: () => onChanged(1),
                  ),
                  _NavItem(
                    selected: currentIndex == 2,
                    label: "AI Chat",
                    icon: HugeIcons.strokeRoundedSparkles,
                    onTap: () => onChanged(2),
                  ),
                  _NavItem(
                    selected: currentIndex == 3,
                    label: "Events",
                    icon: HugeIcons.strokeRoundedConfetti,
                    onTap: () => onChanged(3),
                  ),
                  _NavItem(
                    selected: currentIndex == 4,
                    label: "Highlights",
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

class _NavItem extends StatelessWidget {
  final bool selected;
  final String label;
  final dynamic icon; // HugeIcons.* type
  final VoidCallback onTap;

  const _NavItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.primary : Colors.white;
    final bg = selected ? Colors.white : Colors.transparent;

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 340),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: selected ? 1 : 0),
      builder: (context, t, child) {
        final width = lerpDouble(46, 150, t)!;
        final scale = lerpDouble(1.0, 1.05, t)!;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutCubic,
            width: width,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Transform.scale(
              scale: scale,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: HugeIcon(
                      icon: icon,
                      key: ValueKey("$label-$selected"),
                      color: fg,
                      size: 22,
                      strokeWidth: 2.0,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: selected ? 1 : 0,
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}