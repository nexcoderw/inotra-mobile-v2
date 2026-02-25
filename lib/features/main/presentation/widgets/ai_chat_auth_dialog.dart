import "package:flutter/material.dart";

import "../../../../core/constants/app_colors.dart";
import "../../../../core/config/app_routes.dart";

class AiChatAuthDialog extends StatelessWidget {
  const AiChatAuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const AiChatAuthDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "AI Chat is for members",
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sign in or create an account to access AI Chat and keep your conversations in sync.",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: scheme.onSurface.withOpacity(0.70),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withOpacity(0.7)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    child: const Text(
                      "Sign In",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                    child: const Text(
                      "Create Account",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
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
                    color: scheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
