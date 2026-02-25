import "dart:ui";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/config/app_routes.dart";

class InotraGuestHeader extends StatelessWidget implements PreferredSizeWidget {
  static const double defaultHeight = 108; // ✅ more room (2-row layout)
  final double height;

  const InotraGuestHeader({super.key, this.height = defaultHeight});

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PreferredSize(
      preferredSize: preferredSize,
      child: Material(
        color: Colors.transparent,
        child: SafeArea(
          bottom: false,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: height,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(isDark ? 0.55 : 0.86),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(isDark ? 0.08 : 0.18),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Row 1: Brand + text
                    Row(
                      children: [
                        Container(
                          height: 42,
                          width: 42,
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: scheme.surface.withOpacity(isDark ? 0.20 : 0.10),
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
                                "Welcome 👋",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Sign in to save trips & manage bookings",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  color: scheme.onSurface.withOpacity(0.62),
                                  height: 1.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Row 2: Actions (full-width, taller buttons)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: scheme.onSurface,
                              side: BorderSide(
                                color: AppColors.primary.withOpacity(isDark ? 0.45 : 0.55),
                              ),
                              backgroundColor: Colors.white.withOpacity(isDark ? 0.06 : 0.10),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // ✅ taller
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size.fromHeight(44), // ✅ consistent height
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedLogin01,
                              size: 18,
                              strokeWidth: 2.0,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              "Sign In",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), // ✅ taller
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              minimumSize: const Size.fromHeight(44), // ✅ consistent height
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedUserAdd01,
                              size: 18,
                              strokeWidth: 2.0,
                              color: Colors.white,
                            ),
                            label: const Text(
                              "Register",
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
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