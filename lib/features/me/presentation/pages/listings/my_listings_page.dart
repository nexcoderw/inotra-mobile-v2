import "package:flutter/material.dart";
import "package:inotra/i18n/lang.dart";
import "package:inotra/i18n/translations.dart";
import "package:inotra/features/main/presentation/widgets/main_scaffold.dart";

class MyListingsPage extends StatelessWidget {
  const MyListingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = currentLangSync();
    final scheme = Theme.of(context).colorScheme;

    return MainScaffold(
      title: t(lang, "nav.my_listings"),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t(lang, "nav.my_listings"),
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
      ),
    );
  }
}
