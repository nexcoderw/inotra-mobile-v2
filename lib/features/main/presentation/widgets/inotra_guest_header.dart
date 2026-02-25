import "dart:ui";
import "package:flutter/material.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/config/app_routes.dart";

class InotraGuestHeader extends StatelessWidget implements PreferredSizeWidget {
  static const double defaultHeight = kToolbarHeight + 14;

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
        elevation: 0,
        child: SafeArea(
          bottom: false,
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                height: height,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: scheme.surface.withOpacity(isDark ? 0.55 : 0.80),
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.white.withOpacity(isDark ? 0.08 : 0.18),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // Brand block
                    Container(
                      height: 40,
                      width: 40,
                      padding: const EdgeInsets.all(6),
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

                    // Copy
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Welcome to INOTRA",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: 0.2,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            "Sign in to save trips, chat, and manage bookings",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                              color: scheme.onSurface.withOpacity(0.62),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Actions
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.onSurface,
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(isDark ? 0.45 : 0.55),
                            ),
                            backgroundColor: Colors.white.withOpacity(isDark ? 0.06 : 0.10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
                          child: const Text(
                            "Sign In",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            elevation: 0,
                          ),
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.register),
                          child: const Text(
                            "Register",
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
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