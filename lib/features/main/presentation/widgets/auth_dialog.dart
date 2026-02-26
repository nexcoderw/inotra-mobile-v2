import "dart:ui";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/config/app_routes.dart";
import "../../../../i18n/lang.dart";
import "../../../../i18n/translations.dart";

class AuthDialog extends StatelessWidget {
  final String featureLabel;
  final String? description;

  const AuthDialog({
    super.key,
    required this.featureLabel,
    this.description,
  });

  static Future<void> show(
    BuildContext context, {
    required String featureLabel,
    String? description,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Auth dialog",
      barrierColor: Colors.black.withOpacity(0.25), // subtle dim
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, __, ___) {
        // ✅ blur everything behind
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Center(
            child: AuthDialog(
              featureLabel: featureLabel,
              description: description,
            ),
          ),
        );
      },
      transitionBuilder: (_, anim, __, child) {
        final curved = Curves.easeOutCubic.transform(anim.value);
        return Transform.scale(
          scale: 0.96 + (0.04 * curved),
          child: Opacity(opacity: anim.value, child: child),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bodyText = description ??
        tr("auth.member_body").replaceAll("{feature}", featureLabel);

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface.withOpacity(isDark ? 0.55 : 0.86),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withOpacity(isDark ? 0.10 : 0.20),
              ),
              boxShadow: [
                BoxShadow(
                  blurRadius: 26,
                  offset: const Offset(0, 18),
                  color: Colors.black.withOpacity(isDark ? 0.22 : 0.12),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // top row: icon + close
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(isDark ? 0.10 : 0.18),
                          ),
                        ),
                        child: const Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedLock,
                            size: 22,
                            strokeWidth: 2.0,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => Navigator.of(context).pop(),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedCancel01,
                            size: 20,
                            strokeWidth: 2.0,
                            color: scheme.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    tr("auth.member_only").replaceAll("{feature}", featureLabel),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: scheme.onSurface,
                      height: 1.15,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    bodyText,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: scheme.onSurface.withOpacity(0.72),
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: scheme.onSurface,
                            side: BorderSide(
                              color: AppColors.primary.withOpacity(isDark ? 0.45 : 0.60),
                            ),
                            backgroundColor:
                                Colors.white.withOpacity(isDark ? 0.06 : 0.10),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            minimumSize: const Size.fromHeight(48), // ✅ taller
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(context, AppRoutes.login);
                          },
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedLogin01,
                            size: 16,
                            strokeWidth: 2.0,
                            color: AppColors.primary,
                          ),
                          label: Text(
                            tr("auth.sign_in"),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32),
                            ),
                            minimumSize: const Size.fromHeight(48), // ✅ taller
                            elevation: 0,
                          ),
                          onPressed: () {
                            Navigator.of(context).pop();
                            Navigator.pushNamed(context, AppRoutes.register);
                          },
                          icon: const HugeIcon(
                            icon: HugeIcons.strokeRoundedUserAdd01,
                            size: 16,
                            strokeWidth: 2.0,
                            color: Colors.white,
                          ),
                          label: Text(
                            tr("auth.create_account"),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Align(
                    alignment: Alignment.center,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        "Maybe later",
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.62),
                          fontWeight: FontWeight.w800,
                        ),
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
