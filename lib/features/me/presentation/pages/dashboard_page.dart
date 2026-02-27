import "package:flutter/material.dart";
import "package:inotra/i18n/lang.dart";
import "package:inotra/i18n/translations.dart";
import "package:inotra/i18n/lang.dart";
import "package:inotra/i18n/translations.dart";

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            t(lang, "nav.dashboard"),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: scheme.onSurface.withOpacity(0.92),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            t(lang, "common.coming_soon"),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface.withOpacity(0.72),
            ),
          ),
        ],
      ),
    );
  }
}
